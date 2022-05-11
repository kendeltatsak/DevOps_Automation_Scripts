import netmiko, time, smtplib, csv, keyring, getpass, os

# Kendel Tatsak
# The purpose of this script is to keep our cold storage NAS offline as much as possible.
# The switch interfaces it's connected to are only enabled between 8AM and 5PM on Fridays.
# During that time, incremental backups are copied to the NAS.


class Cisco:
    def __init__(self, dev_attrs):
        self.hostname  = dev_attrs[0]
        self.mgmt_ip   = dev_attrs[1]
        self.type      = dev_attrs[2]
        self.device_os = dev_attrs[3]
        self.site      = dev_attrs[4]
        self.site_code = int(dev_attrs[5])
        self.mgmt_port = dev_attrs[6]


# accpets an instance of the class Cisco and returns a dictionary representation of the object
def toDict(device):
    return {
        'hostname'  : device.hostname,
        'mgmt_ip'   : device.mgmt_ip,
        'type'      : device.type,
        'device_os' : device.device_os,
        'site'      : device.site,
        'site_code' : device.site_code,
        'mgmt_port' : device.mgmt_port
    }


def create_network_device_objs():
    filename = 'inventory.csv'
    with open(filename, 'r') as file:
        reader = csv.reader(file)
        next(reader)
        devices = {}
    
        for row in reader:
            devices[row[0]] = Cisco(row)

    return devices


def connect(device):
    switch = {
        'device_type' : device.device_os,
        'ip'          : device.mgmt_ip,
        'username'    : 'svc.net.automation',
        'password'    : os.getenv('svc.net.automation'),
        'port'        : device.mgmt_port
        }

    return netmiko.ConnectHandler(**switch)



def change_int_status(device, interfaces, status):
    connection = connect(device)
    for int in interfaces:
        connection.send_config_set(['int ' + int, 
                                    status,
                                   'end'])
        print(device.hostname)
        print(connection.send_command('sh run int ' + int ) + '\n')

    connection.disconnect()


def main():
    if time.localtime().tm_hour < 2:
        status = 'no shutdown'
    else:
        status = 'shutdown'

    devices = create_network_device_objs()
    change_int_status(devices['SMG10SW001'], ['Gi1/0/15', 'Gi2/0/15'], status)
    change_int_status(devices['SMG10NX001'], ['Eth1/13'], status)
    change_int_status(devices['SMG10NX002'], ['Eth1/13'], status)


# Method to email helpdesk if an exception is thrown
def sendMail(e):
    server   = smtplib.SMTP('xxxxx-xxx.xxx.xxxxxxx.com')
    sender   = 'xxx.xxxx@xxxx.com'
    receiver = ['helpdesk@xxxxxxx.com', 'kendel.tatsak@xxxxxxx.com'] 
    message  = """Subject: Enable/Disable coldstore interfaces script has encountered an error \n
                Visual cron job running on SMG-APP1 has encountered an error. Assign ticket to Network Administrator. Message triggered at """ + time.asctime() + ". \n\n" + str(e)
    server.sendmail(sender, receiver, message)

try:
    main()
except Exception as e:
    sendMail(e)
