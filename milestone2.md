# Milestone - 2: AD, vCenter, and SSO
## Overview: 
- **Deploy Domain Controller (DC1-Peyton)**
- **Configure Domain Controller and User**
- **vCenter Installation**
- **SSO Integration**

## VM Configuration Table
> Always select 'thin provison' when configuring storage

VM Config | Domain Controller    | vCenter
----------|----------------------|---------------|
CPU       | 2 Cores              | 4 Cores       |
RAM       | 6-8GB                | 19GB          |
DISK      | 80GB                 | 480GB         |
OS        | WinServer 2019       | VCSA          |

## Deploying Domain Controller:
### Requirements: 
> Uploaded WinServer 2019 and VCSA ISO's into ***datastore2-superX***
1. Create a new VM (dc1-peyton)
2. Upload Windows Server 2019 ISO into CD/Rom Drive
3. Proceed with Windows Server 2019 Installation
4. **Do not** set the admin password
5. Use Sconfig to configure static IP address and gateway
> Refer to Domain Controller Network Configuration
6. Install VMWare Tools to Domain Controller
7. Install SSH and Sysprep the system. 

Run the following script on the machine through PowerShell

7. Create clean snapshot (Use sconfig to update windows before hand)

## Domain Controller Network Configuration:
```
IP Address: 10.0.17.4
Subnet:     255.255.255.0
Gateway:    10.0.17.2
DNS:        10.0.17.2
Hostname:   dc1-peyton
Domain:     peyton.local
```

## Domain Controller ADDS/DNS: 
1. Install ADDS/DNS with Management Tools
2. Create forest and promote Domain Controller
3. Created named admin user and promote to Domain Admins and Enterprise Admins Group
4. Create A Records and PTR Records for 
    - pf-14 ```10.0.17.2```
    - mgmt-01 ```10.0.17.100```
    - dc1-peyton ```10.0.17.4```
    - super14 ```192.168.3.214```
    - vCenter ```10.0.17.3```
    - Reverse Lookup Zone ```0.17.0.10```
5. Afterwards change your management server to use dc1-peyton as its DNS Server. 

## vCenter Installation:
> This process takes two stages, both stages taking around 20 minutes.
### Requirements:
Create DNS records within AD for vCenter and ESXi and ensure your ESXi host is synced to ```pool.ntp.org```. Make sure your Management and ESXi hosts time servers are synced. 

1. Mount your VCSA ISO to Management (**mgmt01**)
2. Begin the installer ```/media/user/VMWare VCSA/vcsa-ui-installer/lin64```
3. Select small install size, and use 'thin disk', on ***datastore2-superX***
4. Configure VCSA root password and Default admin password
5. Create default vCenter domain and Admin
6. Update vCenter

## vCenter Configuration: 
1. Create a DataCenter in vCenter called SYS-350
2. Add superX (super14) as a host to SYS-350 DataCenter 
3. Licensing - Use Eval License

## SSO Integration:
> Double check time servers, before proceeding
1. Join vCenter to the domain
2. Add yourdomain.local SSO provider as default
> This is hidden under Administration>Single Sign On>Configuration
3. Reboot the vCenter Server for the source to be added (Use MGMT)
4. Add yourdomain.local Domain Admins to the vCenter Administrators group
> Users & Groups>Groups>Administrators>Add Members>yourdomain.local

## Connectivity Testing:
Domain Controller AD Admin Accounts should be able to login to vCenter using yourdomain.local







