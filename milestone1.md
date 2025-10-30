# Milestone - 1: Hypervisor Installation
## Overview: 
- **Installation of ESXI on SuperMicro Server**
- **Configuration of Data Stores**
- **Creation of Internal Virtual Network**
- **Configuration of Firewall and Management Systems**

## Install ESXi:
### Requirements:
> Created bootable ESXi using Rufus
1. Connect ESXi USB to IMPI
2. Login to IMPI Super Micro Server via IP Address
3. Under "Remote Control" > Select HTML5 to access the console
4. Use iKVM for the installation, pressing F11 allows to boot from USB
5. Configure Static IP and DNS

## Configuration of Datastores:
> Two Datastores will be required 
1. Access VSphere via web broswer
2. Create two datastores, ***datastore1-superX*** and ***datastore2-superX***
3. Create an ISO folder within ***datastore2-superX***
4. Upload necessary ISO's within ISO folder, (**Xubuntu** and **pfsense**)


## Create VSwitch: 
> We will need to create an internal network for our VM's
1. Add a virtual switch, (***350-internal***)
2. Create a new port group called **350-internal**

## Create VM's (pf14, mgmt-01)
> We will start with pfSense, switch to mgmt, then come back to finish pfSense

VM Config | pfSense              | mgmt-01
----------|----------------------|---------------|
CPU       | 1                    | 2             |
RAM       | 2                    | 5             |
DISK      | 8                    | 30            |
OS        | FreeBSD (64-bit) 12+ | Ubuntu 64-bit |

1. Using the configuration table above, create your pfSense vm
> Be sure to select FreeBSD (64-bit) 12+
2. Ensure you add an extra network card, one for VM network, and one for 350-internal. 
> ISO's for install can be found in Datastore folder from the previous step
### Initial pfSense Setup:
```
WAN IP: 192.168.3.52/24
WAN Gateway: 192.168.3.250

LAN IP: 10.0.17.2/24
```
**Configure the pfSense vm, through the CLI, and set the IP addresses and gateway of the LAN and WAN network adapters.** 

### Management Setup:
3. Now Create another VM using the table above, this VM will act as a Management Server and will be running Xubuntu. 
> Ensure minimal installation is selected
4. Configure the Networking as follows:
```
IP Address: 10.0.17.100
Subnet:     255.255.255.0
Gateway:    10.0.17.2
DNS:        1.1.1.1

Hostname:   mgmt-01
```
### Final pfSense Setup:
5. Now, using the mgmt-01 VM, head back to the pfSense internal ip via a web broswer. Follow the setup and change the following values;
```
Hostname: pf14
Domain:   peyton.local
DNS:      1.1.1.1
```
> Uncheck "Unblock RFC1918 Private Networks"

## Connectivity Testing:
### Ping from mgmt-01
```bash
ping -c 2 google.com
```






 


