function Show-Menu {
    param(
        [string]$title = "Main Menu"
    )

    Clear-Host
    Write-Host "================== $title =================="
    Write-Host "1: VM Quick Info"
    Write-Host "2: VM Details"
    Write-Host "3: Restore From Latest Snapshot"
    Write-Host "4: Create a Full Clone of a VM"
    Write-Host "5: Set VM Memory"
    Write-Host
    Write-Host "q: Quit"
    Write-Host "============================================"
}

function get-data {
    Get-VM |
        Select-Object Name, State,
            @{Name="IP Address";Expression={(Get-VMNetworkAdapter -VMName $_.Name).IPAddresses}} |
        Format-Table -AutoSize |
        Out-Host
}

function get-info {
    param (
        [string]$Name
    )

    Get-VM -Name $Name -ErrorAction Stop |
        Select-Object Name, ComputerName, Version, Uptime,
            @{Name="CPU Usage";Expression={(Get-VM -Name $_.Name).CPUUsage}},
            @{Name="Assigned Memory (MB)";Expression={[math]::Round((Get-VM -Name $_.Name).MemoryAssigned / 1MB)}} |
        Format-List |
        Out-Host
}

function restore-snapshot {
    param (
        [string]$Name
    )

    $latestSnapshot = Get-VMSnapshot -VMName $Name |
        Sort-Object CreationTime -Descending |
        Select-Object -First 1

    if (-not $latestSnapshot) {
        Write-Host "No snapshots found for VM '$Name'" -ForegroundColor Yellow
        return
    }

    Restore-VMSnapshot -VMName $Name -Name $latestSnapshot.Name -Confirm:$false
    Write-Host "Restored snapshot '$($latestSnapshot.Name)' for VM '$Name'" -ForegroundColor Green
}

function clone-vm {
    param (
        [string]$Name,
        [string]$CloneVMName
    )

    $ExportFolder = "C:\Exports\$Name"
    $CloneFolder  = "C:\Clone VM Storage"

    if (Test-Path $ExportFolder) {
        Remove-Item $ExportFolder -Recurse -Force
    }

    Write-Host "Exporting VM '$Name'..."
    Export-VM -Name $Name -Path $ExportFolder

    Write-Host "Importing VM as '$CloneVMName'..."
    Import-VM -Path $ExportFolder -Copy -GenerateNewId |
        Rename-VM -NewName $CloneVMName

    Write-Host "Clone '$CloneVMName' created successfully" -ForegroundColor Green
}

function set-memory {
    param (
        [string]$Name
    )

    $memoryMB = Read-Host "Enter startup memory in MB"

    Stop-VM -Name $Name -Force
    Set-VM -Name $Name -MemoryStartupBytes (${memoryMB}MB)
    Start-VM -Name $Name

    Write-Host "Memory updated for VM '$Name'" -ForegroundColor Green
}

function main {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Please select an option"

        switch ($choice) {
            '1' {
                Write-Host "`nVM Quick Info:`n"
                get-data
            }
            '2' {
                $vmName = Read-Host "Enter a VM Name"
                get-info -Name $vmName
            }
            '3' {
                $vmName = Read-Host "Enter a VM Name"
                restore-snapshot -Name $vmName
            }
            '4' {
                $vmName = Read-Host "Enter source VM Name"
                $cloneName = Read-Host "Enter clone VM Name"
                clone-vm -Name $vmName -CloneVMName $cloneName
            }
            '5' {
                $vmName = Read-Host "Enter a VM Name"
                set-memory -Name $vmName
            }
            'q' {
                Write-Host "Exiting..."
                return
            }
            default {
                Write-Host "Invalid option, try again." -ForegroundColor Red
            }
        }

        Write-Host
        Write-Host "Press any key to continue..."
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
}

main
