import netmiko
import csv
import sys
import os
import pyinputplus as pyip
import ast
import time
import getpass
from ntc_templates.parse import parse_output as po
from dotenv import load_dotenv


class Cisco:
    def __init__(self, dev_attrs):
        self.hostname = dev_attrs[0]
        self.mgmt_ip = dev_attrs[1]
        self.type = dev_attrs[2]
        self.device_os = dev_attrs[3]
        self.site = dev_attrs[4]
        self.site_code = int(dev_attrs[5])
        self.menu_number = int(dev_attrs[6])
        self.domain_controller = dev_attrs[7]
        self.avail_vlans = ast.literal_eval(dev_attrs[8])


def Connect(mgmt_ip):
    load_dotenv(dotenv_path='/home/kendel/python-files/switchport_program/env.env')

    device = {
        'device_type' : 'cisco_ios',
        'ip'          :  mgmt_ip,
        'username'    : 'svc.net.automation',
        'password'    :  os.environ.get('svc_passwd'),
        'port'        : '22'
    }

    return netmiko.ConnectHandler(**device)


def create_network_device_objs():
    dir = os.path.dirname(__file__)
    filename = os.path.join(dir, '../inventory.csv')

    with open(filename, 'r') as file:
        reader = csv.reader(file)
        next(reader)
        devices = []
    
        for row in reader:
            devices.append(Cisco(row))

    return devices


def find_interface(mac_address, site):
    for device in devices:
        if device.site == site and device.type == 'switch':
            print(f"\tsearching {device.hostname}...")

            count = 0
            while count < 5:
                try:
                    c = Connect(device.mgmt_ip)
                    break
                except:
                    print(f"\t\nunable to connect to {device.hostname}")
                    print("\tretrying in 3 seconds for a maximum of 5 attempts.\n")
                    time.sleep(3)
                    count += 1

            mac_table = c.send_command('sh mac add', use_textfsm=True)
            switchports = c.send_command('sh int status', use_textfsm=True)

            for mac in mac_table:
                if mac['destination_address'] == mac_address:
                    for port in switchports:
                        if port['port'] == mac['destination_port'][0] and port['vlan'] != 'trunk':
                            return [port, device]

    c.disconnect()
    return [None, None]


def find_ip(mac_address, site):
    table = []
    for device in devices:
        if device.site == site and device.type == 'router':
            count = 0
            while count < 5:
                try:
                    c = Connect(device.mgmt_ip)
                    break
                except:
                    print(f"\t\nunable to connect to {device.hostname}")
                    print("\tretrying in 3 seconds for a maximum of 5 attempts.\n")
                    time.sleep(3)
                    count += 1

            arp_table = c.send_command('sh ip arp')

            if device.device_os == 'nxos':
                arp_table = po(platform="cisco_nxos", command="sh ip arp", data=arp_table)
            elif device.device_os == 'ios':
                arp_table = po(platform="cisco_ios", command="sh ip arp", data=arp_table)

            for arp in arp_table:
                if arp['mac'] == mac_address:
                    if device.device_os == 'nxos':
                        arp['age'] = int(arp['age'].split(':')[1])
                    table.append([arp['address'], arp['age']])
            c.disconnect()

    if table:
        minAge = table[0]
        for entry in table:
            if int(entry[1]) < int(minAge[1]):
                minAge = entry
        return minAge[0]

    return None


def gather_mac_location():
    print("What is your location?")
    site = pyip.inputMenu(['cmo', 'gannett', 'portland', 'saco', 'windham', 'brunswick'], numbered=True)
    mac_address = input("What is the mac address you're trying to locate? (enter in format xxxx.xxxx.xxxx)\n").strip()
    return site, mac_address


def gather_vlan(int_to_change, switch):
    answer = pyip.inputYesNo(f"Would you like to change the vlan assignment of {int_to_change['port']} on {switch.hostname}? (Y/n)")

    if answer == 'yes':
        answer = pyip.inputMenu(list(switch.avail_vlans.values()), numbered=True)
        for key, value in switch.avail_vlans.items():
            if value == answer:
                return key
    else:
        sys.exit()


def change_vlan(vlan, port_desc, msg, int_to_change, switch):
    c = Connect(switch.mgmt_ip)
    print("changing vlan...")
    c.send_config_set(['int ' + int_to_change['port'], 
                        'switchport access vlan ' + str(vlan),
                        'shutdown',
                        'end'])
    print("changing description...")
    c.send_config_set(['int ' + int_to_change['port'], 
                        'no shutdown',
                        'description ' + port_desc,
                        'end'])
    c.disconnect()
    log_changes(vlan, port_desc, msg, int_to_change, switch)


def log_changes(vlan, port_desc, msg, int_to_change, switch):
    t         = time.localtime()
    d         = f"{t.tm_year}-{t.tm_mon}-{t.tm_mday}"
    t         = f"{t.tm_hour}:{t.tm_min}:{t.tm_sec}"
    user      = getpass.getuser()
    switch    = switch.hostname
    port      = int_to_change['port']
    old_vlan  = str(int_to_change['vlan'])
    new_vlan  = str(vlan)
    old_desc  = int_to_change['name']
    new_desc  = port_desc
    data      = [d, t, user, switch, port, old_vlan,
                 new_vlan, old_desc, new_desc, msg]


    dir = os.path.dirname(__file__)
    filename = os.path.join(dir, '../switchport_log.csv')

    with open(filename, 'a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(data)

    
if __name__ == '__main__':
    dir = os.path.dirname(__file__)
    filename = os.path.join(dir, '../templates/')
    os.environ["NET_TEXTFSM"] = filename
    
    devices = create_network_device_objs()

    int_to_change, switch = None, None
    while (int_to_change == None and switch == None):
        site, mac_address = gather_mac_location()
        int_to_change, switch = find_interface(mac_address, site)

        if int_to_change == None and switch == None:
            print(f"MAC address {mac_address} was not found.")
            answer = pyip.inputYesNo("Would you like to search again? (Y/n)")
            if answer == 'no':
                sys.exit()
    
    ip_address = find_ip(mac_address, site)

    print(f"\n\tMAC address {mac_address} found on {switch.hostname} int {int_to_change['port']}\n"
          f"\tSwitchport {int_to_change['port']} currently assigned VLAN is: VLAN {int_to_change['vlan']}\n"
          f"\tSwitchport description is: {int_to_change['name']}\n"
          f"\tMost recent ARP entry is: {ip_address}\n")
    
    vlan = gather_vlan(int_to_change, switch)

    while True:
        port_desc = input("\nPlease enter a new switchport description under 80 characters: ")
        if len(port_desc) < 80 and port_desc:
            break
    
    while True:
        msg = input("\nPlease enter a brief message explaining why you're making this change. (Max 750 characters):\n")
        if len(msg) < 750 and msg:
            break

    change_vlan(vlan, port_desc, msg, int_to_change, switch)
    print('waiting 5 seconds to reconnect...\n')
    time.sleep(5)
    new_ip_address = find_ip(mac_address, site)
    if ip_address == new_ip_address:
        new_ip_address = 'unassigned. Could indicate a DHCP problem.'
    
    print(f"\tInterface {int_to_change['port']}'s VLAN has been changed to {vlan}\n"
          f"\tMost recent ARP entry is: {new_ip_address}\n"
          f"\tSwitchport description is: {port_desc}\n"
          f"\tPlease create a DHCP reservation on {switch.domain_controller} for this IP if this is a new printer.\n")
    input("Press enter to Quit.")


