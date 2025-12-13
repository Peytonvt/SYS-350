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
        Get-VM | Select-Object Name, State,
            @{Name="IP Address";Expression={(Get-VMNetworkAdapter -VMName $_.Name).IPAddresses}} | Format-Table -AutoSize
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
        Get-VM -Name $Name | Select-Object Name, ComputerName, Version, Uptime,
            @{Name="CPU Usage";Expression={(Get-VM -Name $_.Name).CPUUsage}},
            @{Name="Assigned Memory";Expression={(Get-VM -Name $_.Name).MemoryAssigned}}
    }
    catch {
        Write-Host "Error retrieving VM info: $_" -ForegroundColor Red
    }
}

function restore-snapshot {
    param (
        [string]$Name
    )
    try {
        $latest_snapshot = Get-VMSnapshot -VMName $Name |
        Sort-Object CreationTime -Descending | Select-Object -First 1
        
        if ($latest_snapshot) {
            Restore-VMSnapshot -Name $latest_snapshot.Name -VMName $Name -Confirm:$false
            Write-Host "Restored to snapshot: $($latest_snapshot.Name)" -ForegroundColor Green
        } else {
            Write-Host "No snapshots found for VM: $Name" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error restoring snapshot: $_" -ForegroundColor Red
    }
}

function clone-vm {
    param (
        [string]$Name,
        [string]$CloneVMName
    )
    try {
        $ExportFolder = "C:\Exports"
        $CloneFolder = "C:\Clone VM Storage"

        If (Test-Path $CloneFolder) {
            Write-Warning "Clone Folder: $CloneFolder already exists. Aborting Script ..."
            return
        }
        # Export the Source VM
        Export-VM $Name -Path $ExportFolder

        # Import Exported VM
        Get-ChildItem -Path $ExportFolder -File -Name
        Import-VM -Path $ExportFolder -Copy -GenerateNewId |
            Rename-VM -NewName $CloneVMName
        
        Write-Host "VM cloned successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error cloning VM: $_" -ForegroundColor Red
    }
}

function set-memory {
    param (
        [string]$Name
    )
    try {
        $memoryGB = Read-Host "Enter memory size in GB"
        $memoryBytes = [int64]$memoryGB * 1GB
        
        Set-VMMemory -VMName $Name -StartupBytes $memoryBytes
        Write-Host "Memory set to $memoryGB GB for VM: $Name" -ForegroundColor Green
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
        Write-Host "WARNING: Not running as Administrator. Hyper-V commands may fail." -ForegroundColor Yellow
        Pause-Script
    }

    while($true) {
        Show-Menu
        $choice = Read-Host "Please select an option"
        
        switch ($choice) {
            '1' {
                Write-Host "Display VM Information" -ForegroundColor Cyan
                get-data
            }
            '2' {
                Write-Host "Display VM Summary ..." -ForegroundColor Cyan
                $vmName = Read-Host "Please Enter a VM Name"
                get-info -Name $vmName
            }
            '3' {
                Write-Host "Restore To Latest Snapshot ..." -ForegroundColor Cyan
                $vmName = Read-Host "Please Enter a VM Name"
                restore-snapshot -Name $vmName
            }
            '4' {
                Write-Host "Creating Full Clone ..." -ForegroundColor Cyan
                $vmName = Read-Host "Enter a VM Name"
                $CloneVMName = Read-Host "Enter a VM Name for the Clone"
                clone-vm -Name $vmName -CloneVMName $CloneVMName
            }
            '5' {
                Write-Host "Change RAM Count" -ForegroundColor Cyan
                $vmName = Read-Host "Enter a VM Name"
                set-memory -Name $vmName
            }
            'q' {
                Write-Host "Exiting ..." -ForegroundColor Green
                return
            }
            default {
                Write-Host "Invalid option, please try again." -ForegroundColor Red
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
    Write-Host "Fatal error occurred: $_" -ForegroundColor Red
}
finally {
    # Ensure the window doesn't close immediately
    Write-Host "`nScript completed. Press Enter to exit..."
    $null = Read-Host
}
