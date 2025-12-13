function Display-Options {
    param([string]$Header = "Main Menu")
    
    Clear-Host
    Write-Host ""
    Write-Host "========================================" 
    Write-Host "  $Header"
    Write-Host "========================================" 
    Write-Host ""
    Write-Host "  [1] VM Quick Info"
    Write-Host "  [2] VM 5 Details"
    Write-Host "  [3] Restore From Latest Snapshot"
    Write-Host "  [4] Create a Full Clone of a VM"
    Write-Host "  [5] Set VM Memory"
    Write-Host "  [q] Exit"
    Write-Host ""
    Write-Host "========================================" 
    Write-Host ""
}

function Retrieve-VMData {
    Get-VM | Select-Object Name, State, @{Name="IP Address";Expression={(Get-VMNetworkAdapter -VMName $_.Name).IPAddresses}} | Format-Table -AutoSize
}

function Retrieve-VMInfo {
    param([string]$Name)
    
    Get-VM -Name $Name | Select-Object Name, ComputerName, Version, Uptime, @{Name="CPU Usage";Expression={(Get-VM -Name $_.Name).CPUUsage}}, @{Name="Assigned Memory";Expression={(Get-VM -Name $_.Name).MemoryAssigned}}
}

function Restore-LatestSnapshot {
    param([string]$Name)
    
    $snapshot = Get-VMSnapshot -VMName $Name | Sort-Object CreationTime -Descending | Select-Object -First 1
    Restore-VMSnapshot -Name $snapshot.Name -VMName $Name
}

function Create-VMClone {
    param([string]$Name, [string]$CloneVMName)
    
    $ExportPath = "C:\Exports"
    $ClonePath = "C:\Clone VM Storage"

    If (Test-Path $ClonePath) {
        Write-Warning "Clone directory already exists at: $ClonePath. Aborting operation."
        Break
    }
    
    Export-VM $Name -Path $ExportPath
    Get-ChildItem -Path $ExportPath -File -Name
    Import-VM -Path $ExportPath -Copy -GenerateNewId | Rename-VM -NewName $CloneVMName
}

function Modify-VMMemory {
    param([string]$Name)
}

function Start-Menu {
    while($true) {
        Display-Options
        $selection = Read-Host "Select an option"
        
        switch ($selection) {
            '1' {
                Write-Host "Displaying VM Information..."
                Retrieve-VMData
            }
            '2' {
                Write-Host "Retrieving VM Summary..."
                $vm = Read-Host "Enter VM Name"
                Retrieve-VMInfo -Name $vm
            }
            '3'{
                Write-Host "Restoring Latest Snapshot..."
                $vm = Read-Host "Enter VM Name"
                Restore-LatestSnapshot -Name $vm
            }
            '4'{
                Write-Host "Cloning VM..."
                $vm = Read-Host "Enter VM Name"
                $clone = Read-Host "Enter Clone VM Name"
                Create-VMClone -Name $vm -CloneVMName $clone
            }
            '5'{
                Write-Host "Modifying VM Memory..."
                $vm = Read-Host "Enter VM Name"
                Modify-VMMemory -Name $vm
            }
            'q' {
                Write-Host "Exiting..."
                return
            }
            default {
                Write-Host "Invalid selection. Try again."
            }
        }
        
        Write-Host "Press any key to continue..."
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
}

Start-Menu
