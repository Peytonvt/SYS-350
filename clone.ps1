# Specificy path to the origianl VM VHD.
$parentVHD = Get-Item "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\rocky-base.vhdx"

# Change the origianl VHD to read only.
$parentVHD.Attributes = $parentVHD.Attributes -bor [System.IO.FileAttributes]::ReadOnly

# Create the new Differencing VHD
New-VHD -Path "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\rocky-clone1.vhdx" -ParentPath $parentVHD -Differencing
$childVHD = Get-Item "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\rocky-clone1.vhdx"

# Create the VM using the Differencing VHD and configure settings
New-VM -Name rocky-clone1 -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath $childVHD -Path .\VMData -Generation 2 -Switch HyperV-WAN
Set-VMProcessor -VMName rocky-clone1 -Count 4

# Disable Secure Boot
Set-VMFirmware -VMName rocky-clone1 -EnableSecureBoot off

# Start up the VM and Display Details
Start-VM -Name rocky-clone1
Get-VM -Name rocky-clone1