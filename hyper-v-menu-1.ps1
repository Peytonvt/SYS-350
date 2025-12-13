function Show-Menu {
    param(
        [string]$title = "Main Menu"
    )

    Clear-Host
    Write-Host "==================$title=================="
    Write-Host "1: VM Quick Info"
    Write-Host "2: VM 5 Details"
    Write-Host "3: Restore From Latest Snapshot"
    Write-Host "4: Create a Full Clone of a VM"
    Write-Host "5: Set VM Memory"
    Write-Host "Q: Quit"
    Write-Host
    Write-Host "==================$title=================="

}

function get-data {
    try {
        Write-Host "`nRetrieving VM Information...`n" -ForegroundColor Green
        
        $vms = Get-VM | Select-Object Name, State,
            @{Name="IP Address";Expression={
                $ips = (Get-VMNetworkAdapter -VMName $_.Name).IPAddresses
                if ($ips) {
                    $ips -join ", "
                } else {
                    "N/A"
                }
            }}
        
        if ($vms) {
            $vms | Format-Table -AutoSize | Out-Host
        } else {
            Write-Host "No VMs found." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error retrieving VM data: $_" -ForegroundColor Red
        Write-Host "Make sure you're running as Administrator and Hyper-V is installed." -ForegroundColor Yellow
    }
}

function get-info {
    param (
        [string]$Name
    )
    try {
        Write-Host "`nRetrieving detailed info for VM: $Name`n" -ForegroundColor Green
        
        $vm = Get-VM -Name $Name -ErrorAction Stop
        
        $vmInfo = [PSCustomObject]@{
            Name = $vm.Name
            ComputerName = $vm.ComputerName
            State = $vm.State
            Version = $vm.Version
            Uptime = $vm.Uptime
            'CPU Usage' = "$($vm.CPUUsage)%"
            'Assigned Memory (MB)' = [math]::Round($vm.MemoryAssigned / 1MB, 2)
            'Startup Memory (MB)' = [math]::Round($vm.MemoryStartup / 1MB, 2)
            ProcessorCount = $vm.ProcessorCount
        }
        
        $vmInfo | Format-List | Out-Host
    }
    catch {
        Write-Host "Error retrieving VM info: $_" -ForegroundColor Red
        Write-Host "Make sure the VM name is correct and you have permissions." -ForegroundColor Yellow
    }
}

function restore-snapshot {
    param (
        [string]$Name
    )
    try {
        Write-Host "`nSearching for snapshots for VM: $Name" -ForegroundColor Green
        
        $latest_snapshot = Get-VMSnapshot -VMName $Name -ErrorAction Stop |
        Sort-Object CreationTime -Descending | Select-Object -First 1
        
        if ($latest_snapshot) {
            Write-Host "Found snapshot: $($latest_snapshot.Name) (Created: $($latest_snapshot.CreationTime))" -ForegroundColor Cyan
            $confirm = Read-Host "Do you want to restore this snapshot? (Y/N)"
            
            if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                Restore-VMSnapshot -Name $latest_snapshot.Name -VMName $Name -Confirm:$false
                Write-Host "Successfully restored to snapshot: $($latest_snapshot.Name)" -ForegroundColor Green
            } else {
                Write-Host "Restore cancelled." -ForegroundColor Yellow
            }
        } else {
            Write-Host "No snapshots found for VM: $Name" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error restoring snapshot: $_" -ForegroundColor Red
    }
}

function clone-vm {
   
}

function set-memory {
    param (
        [string]$Name
    )
    try {
        # Get current memory info
        $vm = Get-VM -Name $Name -ErrorAction Stop
        $currentMemoryGB = [math]::Round($vm.MemoryStartup / 1GB, 2)
        
        Write-Host "`nCurrent startup memory for $Name : $currentMemoryGB GB" -ForegroundColor Cyan
        
        $memoryGB = Read-Host "Enter new memory size in GB"
        $memoryBytes = [int64]$memoryGB * 1GB
        
        # Check if VM is running
        if ($vm.State -eq 'Running') {
            Write-Host "Warning: VM is currently running. It must be stopped to change startup memory." -ForegroundColor Yellow
            $confirm = Read-Host "Do you want to stop the VM and change memory? (Y/N)"
            
            if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                Stop-VM -Name $Name -Force
                Write-Host "VM stopped." -ForegroundColor Cyan
            } else {
                Write-Host "Memory change cancelled." -ForegroundColor Yellow
                return
            }
        }
        
        Set-VMMemory -VMName $Name -StartupBytes $memoryBytes
        Write-Host "`nMemory successfully set to $memoryGB GB for VM: $Name" -ForegroundColor Green
        
        # Show updated info
        $updatedVM = Get-VM -Name $Name
        Write-Host "New startup memory: $([math]::Round($updatedVM.MemoryStartup / 1GB, 2)) GB" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error setting memory: $_" -ForegroundColor Red
    }
}

function Pause-Script {
    Write-Host "`nPress Enter to continue..." -ForegroundColor Yellow
    $null = Read-Host
}

function main {
    # Check if running as Administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "`n========================================" -ForegroundColor Red
        Write-Host "WARNING: NOT RUNNING AS ADMINISTRATOR" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "This script requires Administrator privileges." -ForegroundColor Yellow
        Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
        Pause-Script
        return
    }

    while($true) {
        Show-Menu
        $choice = Read-Host "Please select an option"
        
        switch ($choice) {
            '1' {
                Write-Host "`n=== Display VM Information ===" -ForegroundColor Cyan
                get-data
            }
            '2' {
                Write-Host "`n=== Display VM Details ===" -ForegroundColor Cyan
                $vmName = Read-Host "Please Enter a VM Name"
                get-info -Name $vmName
            }
            '3' {
                Write-Host "`n=== Restore To Latest Snapshot ===" -ForegroundColor Cyan
                $vmName = Read-Host "Please Enter a VM Name"
                restore-snapshot -Name $vmName
            }
            '4' {
                Write-Host "`n=== Creating Full Clone ===" -ForegroundColor Cyan
                $vmName = Read-Host "Enter source VM Name"
                $CloneVMName = Read-Host "Enter new VM Name for the Clone"
                clone-vm -Name $vmName -CloneVMName $CloneVMName
            }
            '5' {
                Write-Host "`n=== Change VM Memory ===" -ForegroundColor Cyan
                $vmName = Read-Host "Enter a VM Name"
                set-memory -Name $vmName
            }
            'q' {
                Write-Host "`nExiting ..." -ForegroundColor Green
                return
            }
            default {
                Write-Host "`nInvalid option, please try again." -ForegroundColor Red
            }
        }
        
        Pause-Script
    }
}

# Run the main function with error handling
try {
    main
}
catch {
    Write-Host "`nFatal error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Ensure the window doesn't close immediately
    Write-Host "`nScript completed. Press Enter to exit..."
    $null = Read-Host
}


