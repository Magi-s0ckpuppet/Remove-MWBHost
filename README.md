# Remove-MWB-Hosts
Script that removes host(s) from MalwareBytes Threatdown service using 
PowerShell + API Key

# Overview
Below are the 3 main componets of this script needed to runs sucessfully:


```
Remove-MWBHost.ps1   main script, that connects to MalwareBytes/Threatdowns API to remove 
                     provided hosts from tenant 
config.json          configuration file, contains required authentication info to connect to
                     MalwareBytes/Threatdowns API for your tenant.
MWB_hosts.txt        (opt) text file containing list of hostnames to be removed from 
                     MalwareBytes/Threatdowns API. One of three methods of host removal
```

# Quick Start

1. Clone code to location
2. Create/fill out JSON config file
3. Execute script (using 1 of 3 input methods)


# Setup

## clone

```
git clone https://github.com/Magi-s0ckpuppet/Remove-MWBHost.git
```

## config
The config.json file requires 3 key pieces of information from your MalwareBytes/Threatdowns tenant.

1. Client ID
2. Client secret
3. Account ID

For more information on getting setup, visit the official [ThreatDown documentation](https://api.malwarebytes.com/nebula/v1/docs#section/Authentication) section on authentication

## execute script (w/ 3 removal methods)

- Give individual hostname to remove, using the `-Hosts` parameter
```
.\Remove-MWBHost.ps1 -ConfigJSON .\config.json -Hosts CLIENT01
```

- Give a comma-seperated list of hostnames to remove, using the `-Hosts` parameter
```
.\Remove-MWBHost.ps1 -ConfigJSON .\config.json -Hosts 'CLIENT02, SERVER01, SERVER02'
```

- Put hostnames to remove in a text file, going line by line for each hostname value, using the `-HostsFile` parameter
```
.\Remove-MWBHost.ps1 -ConfigJSON .\config.json -HostsFile .\MWB_hosts.txt
```
