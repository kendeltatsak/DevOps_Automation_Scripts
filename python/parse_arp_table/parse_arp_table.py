# Kendel Tatsak

import netmiko, keyring, time, pyodbc, re, smtplib, time

# Switches for polling
# Gannett Core-3850 10.20.100.1
# OA Portland SW001 10.40.100.10
# OA Saco SW001 10.50.100.10
# OA Windham SW001 10.60.100.10
# OA Brunswick 10.70.100.1

# Main Method
def main():    
        pollGannett()
        pollPortland()
        pollSaco()
        pollWindham()
        pollBrunswick()

 # Helper method to return a connection to a switch
def switchConnect(mgmtIP):
        switch = {
        'device_type' : 'cisco_ios',
        'ip'          : mgmtIP,
        'username'    : 'svc.net.automation',
        'password'    : 'xxxxxxxxxxxx',
        #'password'    : keyring.get_password("svcAccount", "svc.net.automation"),
        'port'        : '22'
        }
        return netmiko.ConnectHandler(**switch)
    
# Helper method to return parsed data returned from a cisco IOS command
def returnARPTable(mgmtIP, cmd, router):
        # ssh into switch with service account
        connect = switchConnect(mgmtIP)
        
        # regular expression to find IP addresses and MAC addresses from a returned string
        arpTable = re.findall(r"[0-9a-f]{4}[.][0-9a-f]{4}[.][0-9a-f]{4}|[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}|INCOMPLETE|Incomplete", \
                              connect.send_command("sh ip arp " + cmd))
        
        # loop through array to create an array of arrays
        for mac in range(len(arpTable)):
            if mac % 2 == 0:
                arpTable[mac] = [arpTable[mac], arpTable[mac + 1], router]
                
                arpTable[mac][1] = arpTable[mac][1].replace(".", "-")
                arpTable[mac][1] = arpTable[mac][1][:2] + "-" + arpTable[mac][1][2:7] + "-" + \
                                arpTable[mac][1][7:12] + "-" + arpTable[mac][1][12:]
                if "com" in arpTable[mac][1]:
                    arpTable[mac][1] = "00-00-00-00-00-00"

        # delete every odd numbered index (not needed anymore)
        del arpTable[1::2]

        # import to SQL Database
        importARPTableToDB(arpTable)

        # disconnect from router
        connect.disconnect()

        return arpTable

# Method to import MAC table into SQL DB
def importARPTableToDB(arpTable):
        # Connect to SQL DB
        conDB = pyodbc.connect("Driver={SQL Server Native Client 11.0};"
                      "Server=xxxxxxxx;"
                      "Database=xxxxxxxxxxxxxx;"
                      "Trusted_Connection=yes;")
        cursor = conDB.cursor()
        i = 0
        for arp in arpTable:
                sqlCode = """
                        INSERT INTO SysAidDataInterface.dbo.NetworkDeviceAddresses (IPAddress, MacAddress, SwitchLabel)
                        VALUES
                       ('{}', '{}', '{}')
                        """.format(arpTable[i][0], arpTable[i][1], arpTable[i][2])
                cursor.execute(sqlCode)
                conDB.commit()
                i += 1

# Method to email helpdesk if an exception is thrown
def sendMail(e):
    server   = smtplib.SMTP('xxx-xxxx.xxxxxxxxxx.com')
    sender   = 'xxxxxxxx@xxxxxxxxxxxx.com'
    receiver = 'helpdesk@xxxxxxxxxxxx.com' 
    message  = """Subject: MAC Find script has encountered an error \n
                Visual cron job running on SMG-APP1 has encountered an error. \
                Assign ticket to Network Administrator. Message triggered at """ + time.asctime() + ". \n\n" + str(e)
    server.sendmail(sender, receiver, message)

def pollGannett():
        # get lists of wanted mac table values
        returnARPTable('10.20.140.3', 'vlan90', "SMG-Nexus-2")
        returnARPTable('10.20.100.1', 'vlan112', "SMG-Core-3850")
        returnARPTable('10.20.140.3', 'vlan149', "SMG-Nexus-2")
    
def pollPortland():
        # get lists of wanted mac table values
        returnARPTable('10.40.100.3', 'gi0/1/1.1', "SMG40RTR002")
        returnARPTable('10.40.100.3', 'gi0/1/1.2', "SMG40RTR002")
        returnARPTable('10.40.100.3', 'gi0/1/1.11', "SMG40RTR002")
        returnARPTable('10.40.100.3', 'gi0/1/1.90', "SMG40RTR002")

def pollSaco():
        # get lists of wanted mac table values
        returnARPTable('10.50.100.3', 'gi0/1/1.1', "SMG50RTR002")
        returnARPTable('10.50.100.3', 'gi0/1/1.90', "SMG50RTR002")
        returnARPTable('10.50.100.3', 'gi0/1/1.112', "SMG50RTR002")

def pollWindham():
        # get lists of wanted mac table values
        returnARPTable('10.60.100.3', 'gi0/1/1.1', "SMG60RTR002")
        returnARPTable('10.60.100.3', 'gi0/1/1.90', "SMG60RTR002")
        returnARPTable('10.60.100.3', 'gi0/1/1.112', "SMG60RTR002")

def pollBrunswick():
        # get lists of wanted mac table values
        returnARPTable('10.70.100.3', 'gi0/1/1.1', "SMG70RTR002")
        returnARPTable('10.70.100.3', 'gi0/1/1.90', "SMG70RTR002")
        returnARPTable('10.70.100.3', 'gi0/1/1.112', "SMG70RTR002")

# run program, handle exceptions with email to helpdesk@xxxxxxxxx.com
try:    
        main()
except Exception as e:
        sendMail(e)