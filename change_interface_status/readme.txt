This Python script was created to automate the enabling and disabling of a switch's interface that was connected to a cold storage backup SAN.
The goal was to keep this SAN disconnected from the network as much as possible. 
The switch's interface is enabled between 7:55AM and 5:05PM on Fridays; just long enough to complete its incremental backup.