# PowerShell Scripts to prepare Windows drive for backup and revert preparations after restore
# (overall 4 scripts: common, prepare.b4_reboot, prepare.after_reboot, revert)
# this is script revert

. ".\winbackup.common.ps1"

Write-Host "[INFO] Step 1 Check BitLocker status and enable if needed" -ForegroundColor Green

${volume} = Get-BitLockerVolume -MountPoint ${windowsDrive}
${pStat} =  $volume.ProtectionStatus
Write-Host "[INFO] BitLocker status on ${windowsDrive} (volume ${volume}):  ${pStat}" -ForegroundColor Green

if (${volume} -and ${pStat} -ne 'On') {
    Write-Host "[INFO] Enabling BitLocker on ${windowsDrive} to ensure full deactivation." -ForegroundColor Green
    manage-bde -on ${windowsDrive}
    Start-Sleep -Seconds 20
} 
Write-Host "[INFO] BitLocker fully enabled on Windows volume." -ForegroundColor Green

Write-Host "[INFO] Step 2: Enable Hibernation and Pagefile " -ForegroundColor Green
Write-Host "[INFO] Enable Hibernation" -ForegroundColor Green
powercfg -h on

Write-Host "[INFO] Enabling system-managed paging file..." -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
                 -Name "PagingFiles" -Value "?:\pagefile.sys" -Type MultiString
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
                 -Name "AutomaticManagedPagefile" -Value 1 -Type DWord
Write-Host "[INFO] Pagefile has been set to Windows-managed." -ForegroundColor Green
Write-Host "[WARNING] Reboot required..." -ForegroundColor Yellow


Write-Host "[INFO] Step 3: Enable Prefetch and Superfetch (Sysmain)" -ForegroundColor Green
Write-Host "[INFO] Enabling Prefetch" -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3

Write-Host "[INFO] Enabling Superfetch(SysMain)" -ForegroundColor Green
Set-Service -Name "SysMain" -StartupType Automatic
Start-Service -Name "SysMain"
Write-Host "[INFO] Prefetch and Superfetch enabled." -ForegroundColor Green

Write-Host "[INFO] Step 4: Expand Partition to Maximum Size" -ForegroundColor Green
$partition = Get-Partition -DriveLetter ${windowsDriveLetter}
$supportedSize = $partition | Get-PartitionSupportedSize
$maxSize = $supportedSize.SizeMax

Write-Host "[INFO] Current partition size: $($partition.Size / 1MB) MB" -ForegroundColor Green
Write-Host "[INFO] Maximum supported size: $($maxSize / 1MB) MB" -ForegroundColor Green

if ($partition.Size -lt $maxSize) {
    Resize-Partition -DriveLetter ${windowsDriveLetter} -Size ${maxSize}
    Write-Host "[INFO] Partition expanded to full available size." -ForegroundColor Green
} else {
    Write-Host "[WARNING] Partition is already at max size. No expansion needed." -ForegroundColor Yellow
}

Write-Host "[INFO]  Step 5: Final TRIM" -ForegroundColor Green
Write-Host "[INFO] Performing final TRIM operation..." -ForegroundColor Green
optimize-volume -DriveLetter ${windowsDrive}[0] -ReTrim
Write-Host "[INFO] Final TRIM completed successfully." -ForegroundColor Green

Write-Host "Reversal of Windows preparation steps complete! Reboot and use your System as usual ..."

