# Milestone - 3: Additional Networks & Services
## Overview: 
- **Deploy 2 New Virtual Networks (DMZ and MGMT)**
- **Create a VM and Deploy a Web Server**
- **Create and Ubuntu Backup Server**
- **Configure Firewall Settings and Access**

## VM Configuration Table: 
> Always select 'thin provison' when configuring storage

VM Config | Web Server           | Backup Server
----------|----------------------|---------------|
CPU       | 2 Cores              | 2 Cores       |
RAM       | 4GB                  | 5GB           |
DISK      | 30GB                 | 30GB          |
OS        | Rocky Linux 10       | Ubuntu 24.04.3|

## Create vSwitches for DMZ and MGMT: 
1. Add 2 Network Adapters within the ESXi host for pfX (pf14 firewall)
2. Label the first DMZ and the second MGMT, create and assign port-groups. 
3. on pfSense machine, assign interfaces for DMZ and MGMT and configure static IP's, avoid DHCP and IPv6. 
> **You may have to rename interfaces for a clean setup due to MAC addresses**

### DMZ Configuration:
``` py
DMZ: 10.0.18.x/24
Gateway 10.0.18.2
```
### MGMT Configuration:
``` py
MGMT: 10.0.19.x/24
Gateway 10.0.19.2
```

Now on pfSense's online portal, configure the following Firewall Rules,
> Firewall > Rules > Edit
### DMZ pfSense Rules:
``` py
Action: Pass
Interface: DMZ
Address Family: IPv4
Protocol: Any
Source: DMZ net
Destination: Any

Enabled
```
### MGMT pfSense Rules:
``` py
Action: Pass
Interface: DMZ
Address Family: IPv4
Protocol: Any
Source: MGMT net
Destination: Any

Enabled
```
## Firewall Rules: 
> You will need to configure pfSense to allow MGMT and LAN to access DMZ but not the other way around. DMZ Should not be able to connect to MGMT and LAN. Set a rule to allow web ports (80,443) from anywhere to DMZ.

### pfSense DMZ Rules: (Top Down)

INSERT FIREWALL RULES IMAGE

