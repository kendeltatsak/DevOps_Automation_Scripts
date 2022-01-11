This is a Python script that pulls certain IP addresses and MAC addresses from the ARP on Cisco devices and imports the data into an SQL database.
It is executed every 4 hours using visual cron.
This was a part of a project to compare known MAC address values in a hardware asset database to the MAC addresses learned on Cisco switches to identify rogue devices.