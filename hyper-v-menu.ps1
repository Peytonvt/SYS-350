function Draw-Menu {
    param (
        [string]$Header = "Hyper-V Control Panel"
    )

    Clear-Host
    Write-Host "================== $Header =================="
    Write-Host "1) View VM Quick Status"
    Write-Host "2) View Detailed VM Info"
    Write-Host "3) Restore Latest Checkpoint"
    Write-Host "4) Create Full VM Clone"
    Write-Host "5) Modify VM Memory"
    Write-Host "Q) Quit"
    Write-Host "================================================"
}

function Get-VMQuickStatus {
    Get-VM | Select-Object `
        Name,
        State,
        @{Name="IP Address"; Expression={
            (Get-VMNetworkAdapter -VMName $_.Name).IPAddresses -join ", "
        }} |
        Format-Table -AutoSize
}

function Get-VMDetailedInfo {
    param (
        [Parameter(Mandatory)]
        [string]$VMName
    )

    Get-VM -Name $VMName | Select-Object `
        Name,
        ComputerName,
        Version,
        Uptime,
        @{Name="CPU Usage (%)"; Expression={ $_.CPUUsage }},
        @{Name="Assigned Memory (MB)"; Expression={ [math]::Round($_.MemoryAssigned / 1MB, 0) }} |
        Format-List
}

function Restore-LatestCheckpoint {
    param (
        [Parameter(Mandatory)]
        [string]$VMName
    )

    $checkpoint = Get-VMSnapshot -VMName $VMName |
        Sort-Object CreationTime -Descending |
        Select-Object -First 1

    if (-not $checkpoint) {
        Write-Warning "No checkpoints found for $VMName"
        return
    }

    Restore-VMSnapshot -VMName $VMName -Name $checkpoint.Name -Confirm:$false
    Write-Host "Restored VM '$VMName' to latest checkpoint."
}

function Copy-VirtualMachine {
    param (
        [Parameter(Mandatory)]
        [string]$SourceVM,

        [Parameter(Mandatory)]
        [string]$NewVMName
    )

    $exportPath = "C:\VM_Exports"
    $importPath = "C:\VM_Clones"

    if (-not (Test-Path $exportPath)) {
        New-Item -ItemType Directory -Path $exportPath | Out-Null
    }

    if (Get-VM -Name $NewVMName -ErrorAction SilentlyContinue) {
        Write-Warning "A VM named '$NewVMName' already exists."
        return
    }

    Write-Host "Exporting VM..."
    Export-VM -Name $SourceVM -Path $exportPath

    Write-Host "Importing as new VM..."
    Import-VM -Path $exportPath -Copy -GenerateNewId |
        Rename-VM -NewName $NewVMName

    Write-Host "Clone '$NewVMName' created successfully."
}

function Update-VMMemory {
    param (
        [Parameter(Mandatory)]
        [string]$VMName
    )

    $memoryMB = Read-Host "Enter new startup memory in MB"

    if (-not ($memoryMB -as [int])) {
        Write-Warning "Invalid memory value."
        return
    }

    Stop-VM -Name $VMName -Force -Confirm:$false

    Set-VM -Name $VMName -MemoryStartupBytes ($memoryMB * 1MB)

    Start-VM -Name $VMName

    Write-Host "Memory updated to $memoryMB MB and VM restarted."
}

function Start-ControlLoop {
    while ($true) {
        Draw-Menu
        $selection = Read-Host "Select an option"

        switch ($selection.ToLower()) {
            '1' {
                Get-VMQuickStatus
            }
            '2' {
                $name = Read-Host "Enter VM name"
                Get-VMDetailedInfo -VMName $name
            }
            '3' {
                $name = Read-Host "Enter VM name"
                Restore-LatestCheckpoint -VMName $name
            }
            '4' {
                $source = Read-Host "Enter source VM name"
                $clone  = Read-Host "Enter new clone VM name"
                Copy-VirtualMachine -SourceVM $source -NewVMName $clone
            }
            '5' {
                $name = Read-Host "Enter VM name"
                Update-VMMemory -VMName $name
            }
            'q' {
                Write-Host "Exiting Hyper-V Menu..."
                break
            }
            default {
                Write-Host "Invalid selection. Try again."
            }
        }

        Write-Host "`nPress any key to continue..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
}

# Script Entry Point
Start-ControlLoop
