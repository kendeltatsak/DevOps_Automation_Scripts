import netmiko, json, keyring, time, smtplib

# Kendel Tatsak
# The purpose of this script is to keep our cold storage NAS offline as much as possible.
# The switch interfaces it's connected to are only enabled between 8AM and 5PM on Fridays.
# During that time, incremental backups are copied to the NAS.

def main():
    # Script is executed twice per day on Fridays. Once at 7:55AM and once at 5:05PM.
    # Conditional statement is to determine which command set to execute
    # based on the time of day. 
    if time.localtime().tm_hour < 12:
        enableInterfaces()
    else:
        disableInterfaces()

def enableInterfaces():
    # ssh into switch with service account
    connect = switchConnection('10.10.100.10')
    
    # execute command set
    connect.send_config_set(['int Gi1/0/15', 
                                'no shutdown',
                                    'end'])
    connect.send_config_set(['int Gi2/0/15', 
                                'no shutdown',
                                    'end'])

    # disconnect form switch
    connect.disconnect()

def disableInterfaces():
    # ssh into switch with service account
    connect = switchConnection('10.10.100.10')
    
    # execute command set
    connect.send_config_set(['int Gi1/0/15', 
                                'shutdown',
                                    'end'])
    connect.send_config_set(['int Gi2/0/15', 
                                'shutdown',
                                    'end'])

    # disconnect form switch
    connect.disconnect()

def switchConnection(mgmtIP):
    switch = {
        'device_type' : 'cisco_ios',
        'ip'          : mgmtIP,
        'username'    : 'svc.net.automation',
        'password'    : keyring.get_password("svc.net.automation", "svc.net.automation"),
        'port'        : '22'
        }
    return netmiko.ConnectHandler(**switch)

    # Method to email helpdesk if an exception is thrown
def sendMail(e):
    server   = smtplib.SMTP('xxx-exch2013.xxx.xxxxxxxxx.com')
    sender   = 'Network.Notifications@xxxxxxxx.com'
    receiver = ["helpdesk@xxxxxxxxxxxx.com", "kendel.tatsak@xxxxxxxxxxx.com"] 
    message  = """Subject: Enable/Disable coldstore interfaces script has encountered an error \n
                Visual cron job running on SMG-APP1 has encountered an error. Assign ticket to Network Administrator. Message triggered at """ + time.asctime() + ". \n\n" + str(e)
    server.sendmail(sender, receiver, message)

try:
    main()
except Exception as e:
    sendMail(e)