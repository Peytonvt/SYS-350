function Show-Menu {
    param(
        [string]$title = "HyperV Automation Menu"
    )

    Clear-Host
    Write-Host "==================$title=================="
    Write-Host "Information Gathering:"
    Write-Host "  1: VM Quick Info (Summary View)"
    Write-Host "  2: VM Detailed Info (5 Properties)"
    Write-Host ""
    Write-Host "Automation Functions:"
    Write-Host "  3: Restore From Latest Snapshot"
    Write-Host "  4: Create a Full Clone of a VM"
    Write-Host "  5: Tweak VM Performance (Memory/CPU)"
    Write-Host "  6: Delete a VM from Disk"
    Write-Host "  7: Copy File to VM"
    Write-Host "  8: Execute Command on VM"
    Write-Host ""
    Write-Host "  Q: Quit"
    Write-Host "==================$title=================="
    Write-Host ""
}

function Get-VMQuickInfo {
    Write-Host "`nFetching VM Quick Info..." -ForegroundColor Cyan
    
    Get-VM | Select-Object Name, State,
        @{Name="IP Address";Expression={
            $ips = (Get-VMNetworkAdapter -VMName $_.Name).IPAddresses
            if ($ips) {
                ($ips | Where-Object { $_ -notmatch ':' }) -join ', '
            } else {
                "N/A"
            }
        }} | Format-Table -AutoSize
}

function Get-VMDetailedInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    Write-Host "`nFetching Detailed Info for VM: $VMName" -ForegroundColor Cyan
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction Stop
        
        $vmInfo = Get-VM -Name $VMName | Select-Object Name, State, Uptime, 
            @{Name="CPU Count";Expression={$_.ProcessorCount}},
            @{Name="Memory Assigned (GB)";Expression={[math]::Round($_.MemoryAssigned/1GB, 2)}},
            @{Name="Memory Startup (GB)";Expression={[math]::Round($_.MemoryStartup/1GB, 2)}},
            @{Name="Generation";Expression={$_.Generation}},
            @{Name="Version";Expression={$_.Version}}
        
        $vmInfo | Format-List
        
        Write-Host "`nNetwork Adapters:" -ForegroundColor Yellow
        Get-VMNetworkAdapter -VMName $VMName | Select-Object Name, SwitchName, 
            @{Name="MAC Address";Expression={$_.MacAddress}},
            @{Name="IP Addresses";Expression={$_.IPAddresses -join ', '}} | Format-Table -AutoSize
            
    } catch {
        Write-Host "Error: VM '$VMName' not found or inaccessible." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

function Restore-LatestSnapshot {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    Write-Host "`nRestoring Latest Snapshot for VM: $VMName" -ForegroundColor Cyan
    
    try {
        $snapshots = Get-VMSnapshot -VMName $VMName -ErrorAction Stop
        
        if ($snapshots) {
            $latestSnapshot = $snapshots | Sort-Object CreationTime -Descending | Select-Object -First 1
            
            Write-Host "Latest Snapshot: $($latestSnapshot.Name)" -ForegroundColor Yellow
            Write-Host "Created: $($latestSnapshot.CreationTime)" -ForegroundColor Yellow
            
            $confirm = Read-Host "Do you want to restore this snapshot? (Y/N)"
            if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                Restore-VMSnapshot -Name $latestSnapshot.Name -VMName $VMName -Confirm:$false
                Write-Host "Snapshot restored successfully!" -ForegroundColor Green
            } else {
                Write-Host "Restore cancelled." -ForegroundColor Yellow
            }
        } else {
            Write-Host "No snapshots found for VM: $VMName" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error restoring snapshot: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function New-VMClone {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourceVMName,
        [Parameter(Mandatory=$true)]
        [string]$CloneVMName
    )
    
    Write-Host "`nCreating Full Clone..." -ForegroundColor Cyan
    Write-Host "Source VM: $SourceVMName" -ForegroundColor Yellow
    Write-Host "Clone Name: $CloneVMName" -ForegroundColor Yellow
    
    try {
        $exportPath = "C:\Temp\VMExport\$SourceVMName"
        $importPath = "C:\Temp\VMClone\$CloneVMName"
        
        if (Get-VM -Name $CloneVMName -ErrorAction SilentlyContinue) {
            Write-Host "Error: A VM with name '$CloneVMName' already exists!" -ForegroundColor Red
            return
        }
        
        if (-not (Test-Path $exportPath)) {
            New-Item -ItemType Directory -Path $exportPath -Force | Out-Null
        }
        
        Write-Host "Exporting source VM..." -ForegroundColor Yellow
        Export-VM -Name $SourceVMName -Path $exportPath
        
        $vmConfigPath = Get-ChildItem -Path $exportPath -Recurse -Filter "*.vmcx" | Select-Object -First 1
        
        if ($vmConfigPath) {
            Write-Host "Importing clone..." -ForegroundColor Yellow
            Import-VM -Path $vmConfigPath.FullName -Copy -GenerateNewId -VhdDestinationPath "C:\Temp\VMClone\$CloneVMName" | 
                Rename-VM -NewName $CloneVMName
            
            Write-Host "Clone created successfully!" -ForegroundColor Green
            
            Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
            Remove-Item -Path $exportPath -Recurse -Force
        } else {
            Write-Host "Error: Could not find VM configuration file." -ForegroundColor Red
        }
        
    } catch {
        Write-Host "Error creating clone: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-VMPerformance {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    Write-Host "`nTweaking Performance for VM: $VMName" -ForegroundColor Cyan
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction Stop
        
        Write-Host "`nCurrent Settings:" -ForegroundColor Yellow
        Write-Host "  CPU Count: $($vm.ProcessorCount)"
        Write-Host "  Memory Startup: $([math]::Round($vm.MemoryStartup/1GB, 2)) GB"
        Write-Host "  Memory Assigned: $([math]::Round($vm.MemoryAssigned/1GB, 2)) GB"
        
        if ($vm.State -eq 'Running') {
            Write-Host "`nWarning: VM is currently running." -ForegroundColor Yellow
            $continue = Read-Host "Some changes require the VM to be off. Continue? (Y/N)"
            if ($continue -ne 'Y' -and $continue -ne 'y') {
                return
            }
        }
        
        Write-Host "`nWhat would you like to modify?"
        Write-Host "1: CPU Count"
        Write-Host "2: Memory"
        Write-Host "3: Both"
        $choice = Read-Host "Selection"
        
        switch ($choice) {
            '1' {
                $newCPU = Read-Host "Enter new CPU count (current: $($vm.ProcessorCount))"
                if ($newCPU -match '^\d+$') {
                    Set-VM -Name $VMName -ProcessorCount ([int]$newCPU)
                    Write-Host "CPU count updated to $newCPU" -ForegroundColor Green
                } else {
                    Write-Host "Invalid CPU count." -ForegroundColor Red
                }
            }
            '2' {
                $newMemoryGB = Read-Host "Enter new startup memory in GB (current: $([math]::Round($vm.MemoryStartup/1GB, 2)))"
                if ($newMemoryGB -match '^\d+(\.\d+)?$') {
                    $newMemoryBytes = [int64]([double]$newMemoryGB * 1GB)
                    Set-VM -Name $VMName -MemoryStartupBytes $newMemoryBytes
                    Write-Host "Memory updated to $newMemoryGB GB" -ForegroundColor Green
                } else {
                    Write-Host "Invalid memory value." -ForegroundColor Red
                }
            }
            '3' {
                $newCPU = Read-Host "Enter new CPU count (current: $($vm.ProcessorCount))"
                $newMemoryGB = Read-Host "Enter new startup memory in GB (current: $([math]::Round($vm.MemoryStartup/1GB, 2)))"
                
                if ($newCPU -match '^\d+$' -and $newMemoryGB -match '^\d+(\.\d+)?$') {
                    $newMemoryBytes = [int64]([double]$newMemoryGB * 1GB)
                    Set-VM -Name $VMName -ProcessorCount ([int]$newCPU) -MemoryStartupBytes $newMemoryBytes
                    Write-Host "CPU and Memory updated successfully!" -ForegroundColor Green
                } else {
                    Write-Host "Invalid input values." -ForegroundColor Red
                }
            }
            default {
                Write-Host "Invalid selection." -ForegroundColor Red
            }
        }
        
    } catch {
        Write-Host "Error modifying VM: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-VMFromDisk {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    Write-Host "`nDeleting VM from Disk: $VMName" -ForegroundColor Cyan
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction Stop
        
        $vhdPaths = Get-VMHardDiskDrive -VMName $VMName | Select-Object -ExpandProperty Path
        
        Write-Host "`nWarning: This will permanently delete the VM and all its files!" -ForegroundColor Red
        Write-Host "VM Name: $VMName" -ForegroundColor Yellow
        Write-Host "State: $($vm.State)" -ForegroundColor Yellow
        Write-Host "Virtual Hard Drives:" -ForegroundColor Yellow
        $vhdPaths | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        
        $confirm = Read-Host "`nAre you absolutely sure? Type 'DELETE' to confirm"
        
        if ($confirm -eq 'DELETE') {
            if ($vm.State -eq 'Running') {
                Write-Host "Stopping VM..." -ForegroundColor Yellow
                Stop-VM -Name $VMName -Force
            }
            
            Write-Host "Removing VM..." -ForegroundColor Yellow
            Remove-VM -Name $VMName -Force
            
            Write-Host "Deleting VHD files..." -ForegroundColor Yellow
            foreach ($vhdPath in $vhdPaths) {
                if (Test-Path $vhdPath) {
                    Remove-Item -Path $vhdPath -Force
                    Write-Host "Deleted: $vhdPath" -ForegroundColor Green
                }
            }
            
            Write-Host "`nVM '$VMName' has been completely removed from disk!" -ForegroundColor Green
        } else {
            Write-Host "Deletion cancelled." -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "Error deleting VM: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Copy-FileToVM {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    Write-Host "`nCopy File to VM: $VMName" -ForegroundColor Cyan
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction Stop
        
        if ($vm.State -ne 'Running') {
            Write-Host "Error: VM must be running to copy files." -ForegroundColor Red
            return
        }
        
        Write-Host "Checking Integration Services..." -ForegroundColor Yellow
        $guestService = Get-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"
        if (-not $guestService.Enabled) {
            Write-Host "Enabling Guest Service Interface..." -ForegroundColor Yellow
            Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"
        }
        
        $sourcePath = Read-Host "Enter source file path on host (e.g., C:\temp\file.txt)"
        if (-not (Test-Path $sourcePath)) {
            Write-Host "Error: Source file not found." -ForegroundColor Red
            return
        }
        
        $destPath = Read-Host "Enter destination path on VM (e.g., C:\temp\file.txt)"
        
        Write-Host "Copying file..." -ForegroundColor Yellow
        Copy-VMFile -VMName $VMName -SourcePath $sourcePath -DestinationPath $destPath -FileSource Host -Force
        
        Write-Host "File copied successfully!" -ForegroundColor Green
        Write-Host "From: $sourcePath" -ForegroundColor Yellow
        Write-Host "To:   $destPath (on $VMName)" -ForegroundColor Yellow
        
    } catch {
        Write-Host "Error copying file: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nNote: This requires:" -ForegroundColor Yellow
        Write-Host "  - VM must be running" -ForegroundColor Yellow
        Write-Host "  - Guest Service Interface integration service enabled" -ForegroundColor Yellow
        Write-Host "  - Windows guest OS with Integration Services installed" -ForegroundColor Yellow
    }
}

function Invoke-VMCommand {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    Write-Host "`nExecute Command on VM: $VMName" -ForegroundColor Cyan
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction Stop
        
        if ($vm.State -ne 'Running') {
            Write-Host "Error: VM must be running to execute commands." -ForegroundColor Red
            return
        }
        
        Write-Host "`nNote: This requires PowerShell Direct, which works with:" -ForegroundColor Yellow
        Write-Host "  - Windows 10/Server 2016 or later guests" -ForegroundColor Yellow
        Write-Host "  - Valid credentials for the guest OS" -ForegroundColor Yellow
        Write-Host ""
        
        $credential = Get-Credential -Message "Enter credentials for VM '$VMName'"
        
        Write-Host "`nCommon Commands:" -ForegroundColor Yellow
        Write-Host "1: Test network connectivity (ping 1.1.1.1)"
        Write-Host "2: Get IP configuration"
        Write-Host "3: Get running processes"
        Write-Host "4: Custom command"
        $choice = Read-Host "Selection"
        
        $scriptBlock = switch ($choice) {
            '1' { { Test-Connection -ComputerName 1.1.1.1 -Count 4 } }
            '2' { { Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4'} | Format-Table } }
            '3' { { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 } }
            '4' { 
                $customCmd = Read-Host "Enter PowerShell command"
                [scriptblock]::Create($customCmd)
            }
            default { 
                Write-Host "Invalid selection." -ForegroundColor Red
                return
            }
        }
        
        Write-Host "`nExecuting command on $VMName..." -ForegroundColor Yellow
        $result = Invoke-Command -VMName $VMName -Credential $credential -ScriptBlock $scriptBlock
        
        Write-Host "`nCommand Output:" -ForegroundColor Green
        $result
        
    } catch {
        Write-Host "Error executing command: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
        Write-Host "  - Verify credentials are correct" -ForegroundColor Yellow
        Write-Host "  - Ensure VM is running Windows 10/Server 2016+" -ForegroundColor Yellow
        Write-Host "  - Check that Integration Services are enabled" -ForegroundColor Yellow
    }
}

function Main {
    Write-Host "`n=== SYS-350 Milestone 7.2 - HyperV Automation ===" -ForegroundColor Green
    Write-Host "Author: Your Name" -ForegroundColor Green
    Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd')`n" -ForegroundColor Green
    
    while($true) {
        Show-Menu
        $choice = Read-Host "Please select an option"
        
        switch ($choice) {
            '1' {
                Get-VMQuickInfo
            }
            '2' {
                $vmName = Read-Host "Enter VM Name"
                Get-VMDetailedInfo -VMName $vmName
            }
            '3' {
                $vmName = Read-Host "Enter VM Name"
                Restore-LatestSnapshot -VMName $vmName
            }
            '4' {
                $sourceVM = Read-Host "Enter Source VM Name"
                $cloneVM = Read-Host "Enter Clone VM Name"
                New-VMClone -SourceVMName $sourceVM -CloneVMName $cloneVM
            }
            '5' {
                $vmName = Read-Host "Enter VM Name"
                Set-VMPerformance -VMName $vmName
            }
            '6' {
                $vmName = Read-Host "Enter VM Name"
                Remove-VMFromDisk -VMName $vmName
            }
            '7' {
                $vmName = Read-Host "Enter VM Name"
                Copy-FileToVM -VMName $vmName
            }
            '8' {
                $vmName = Read-Host "Enter VM Name"
                Invoke-VMCommand -VMName $vmName
            }
            'q' {
                Write-Host "`nExiting HyperV Automation Menu..." -ForegroundColor Green
                return
            }
            default {
                Write-Host "`nInvalid option, please try again." -ForegroundColor Red
            }
        }
        
        Write-Host "`nPress any key to continue..." -ForegroundColor Cyan
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
}

Main
