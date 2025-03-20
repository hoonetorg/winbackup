# PowerShell Scripts to prepare Windows drive for backup and revert preparations after restore
# (overall 4 scripts: common, prepare.b4_reboot, prepare.after_reboot, revert)
# this is script revert

. ".\winbackup.common.ps1"

Write-Host "[INFO] Step 1 Check BitLocker status and enable if needed" -ForegroundColor Green

${volume} = Get-BitLockerVolume -MountPoint ${windowsDrive}
${pStat} =  $volume.ProtectionStatus
Write-Host "[INFO] BitLocker status on ${windowsDrive} (volume ${volume}):  ${pStat}" -ForegroundColor Yellow

if (${volume} -and ${pStat} -ne 'On') {
    Write-Host "[INFO] Enabling BitLocker on ${windowsDrive} to ensure full deactivation." -ForegroundColor Yellow
    manage-bde -on ${windowsDrive}
    Start-Sleep -Seconds 20
} 
Write-Host "[INFO] BitLocker fully enabled on Windows volume." -ForegroundColor Green

Write-Host "[INFO] Step 2: Enable Hibernation and Pagefile " -ForegroundColor Green
Write-Host "[INFO] Enable Hibernation" -ForegroundColor Yellow
powercfg -h on

Write-Host "[INFO] Disabling pagefile..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
                 -Name "PagingFiles" -Value "" -Type MultiString
Write-Host "[WARNING] Reboot required..." -ForegroundColor Red


Write-Host "[INFO] Step 3: Stop and disable Prefetch and Superfetch (Sysmain) and delete Prefetch and Superfetch Files" -ForegroundColor Green
Write-Host "[INFO] Disabling Prefetch" -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0

Write-Host "[INFO] Disabling Superfetch(SysMain)" -ForegroundColor Yellow
Stop-Service -Name "SysMain" -Force
Set-Service -Name "SysMain" -StartupType Disabled

Write-Host "[INFO] Removing files in C:\Windows\Prefetch" -ForegroundColor Yellow
#Remove-Item -Path "C:\Windows\Prefetch\*" -Force -Recurse
recursively-Remove-Files-If-Possible -Path "C:\Windows\Prefetch\*"

Write-Host "[INFO] Prefetch and Superfetch disabled. Cache cleared." -ForegroundColor Green

Write-Host "Please reboot"

# PowerShell Scripts to prepare Windows drive for backup (overall 3 scripts: common, b4_reboot, after_reboot)
# this is script after_reboot
# Required sdelete64.exe from https://download.sysinternals.com/files/SDelete.zip
# Scripts and sdelete64.exe must be copied to <windowsDrive>\Program Files\winbackup\


. ".\prepare_windows_install_for_backup.common.ps1"

Write-Host "[INFO] Step 4: Deleting all system restore points..." -ForegroundColor Green
vssadmin delete shadows /all /quiet

Write-Host "[INFO] Step 5: Running Disk Cleanup and Storage Sense" -ForegroundColor Green
Write-Host "[INFO] Running Disk Cleanup" -ForegroundColor Yellow
cleanmgr /sagerun:1

Write-Host "[INFO] Running Storage Sense to free up space" -ForegroundColor Yellow
Start-Process -NoNewWindow -Wait -FilePath "cmd.exe" -ArgumentList "/c cleanmgr /verylowdisk"

Write-Host "[INFO] Step 6: Compacting Windows system files..." -ForegroundColor Green
compact.exe /CompactOS:always

Write-Host "[INFO] Step 7: Removing user and system Temp files" -ForegroundColor Green
recursively-Remove-Files-If-Possible -Path "$env:TEMP\*"
recursively-Remove-Files-If-Possible -Path "${windowsDrive}\Windows\Temp\*"

Write-Host "[INFO] Step 8: Deleting Windows Update cache..." -ForegroundColor Green
Stop-Service wuauserv -Force
recursively-Remove-Files-If-Possible -Path "${windowsDrive}\Windows\SoftwareDistribution\Download\*"
# not required, we poweroff and backup
#Start-Service wuauserv

Write-Host "[INFO] Step 9: Deleting Windows logs..." -ForegroundColor Green
recursively-Remove-Files-If-Possible -Path "${windowsDrive}\Windows\Logs\*"

Write-Host "[INFO] Step 10: Clear Windows Delivery Optimization Cache ${windowsDrive}\ProgramData\Microsoft\Windows\DeliveryOptimization" -ForegroundColor Green
recursively-Remove-Files-If-Possible -Path "${windowsDrive}\ProgramData\Microsoft\Windows\DeliveryOptimization\*"

Write-Host "[INFO] Step 11: Defragmenting the volume ${windowsDrive}" -ForegroundColor Green
optimize-volume -DriveLetter ${windowsDrive}[0] -Defrag

Write-Host "[INFO] Step 12: Trimming the volume ${windowsDrive}" -ForegroundColor Green
optimize-volume -DriveLetter ${windowsDrive}[0] -ReTrim
Write-Host "[INFO] Optimization completed for ${windowsDrive}." -ForegroundColor Green

Write-Host "[INFO] Step 13: Shrink Partition to Min Size + Buffer ${bufferSize} MB" -ForegroundColor Green
${partition} = Get-Partition -DriveLetter ${windowsDriveLetter}
${supportedSize} = ${partition} | Get-PartitionSupportedSize
${maxShrinkSize} = ${supportedSize}.SizeMin
${bufferSize} = 5 * 1024 * 1024 * 1024  # 5GB buffer
${shrinkSize} = ${maxShrinkSize} + ${bufferSize}

Write-Host "[INFO] partition ${partition}" -ForegroundColor Yellow
Write-Host "[INFO] supportedSize ${supportedSize}" -ForegroundColor Yellow
Write-Host "[INFO] maxShrinkSize ${maxShrinkSize}" -ForegroundColor Yellow
Write-Host "[INFO] bufferSize ${bufferSize}" -ForegroundColor Yellow
Write-Host "[INFO] shrinkSize ${shrinkSize}" -ForegroundColor Yellow


if (${maxShrinkSize} -gt 0) {
    Write-Host "[INFO] Shrinking partition to $(${shrinkSize} / 1MB) MB..." -ForegroundColor Yellow
    Resize-Partition -DriveLetter ${windowsDriveLetter} -Size ${shrinkSize}
    Write-Host "[INFO] Partition shrink complete." -ForegroundColor Green
} else {
    Write-Host "[WARNING] Not enough shrinkable space. Skipping shrink step." -ForegroundColor Yellow
}

Write-Host "[INFO] Step 14: Zero free space (use sdelete64 from Sysinternals)" -ForegroundColor Green
Write-Host "[INFO] Zero free space of Windows volume ${windowsDrive}..." -ForegroundColor Yellow
Start-Process -NoNewWindow -Wait -FilePath "${windowsDrive}\Program Files\winbackup\sdelete64.exe" -ArgumentList "-accepteula -q -z ${windowsDrive}"
Write-Host "[INFO] Wrinting zeros completed for ${windowsDrive}." -ForegroundColor Green

Write-Host "[INFO]  Step 15: Final TRIM" -ForegroundColor Green
Write-Host "[INFO] Performing final TRIM operation..." -ForegroundColor Yellow
optimize-volume -DriveLetter ${windowsDrive}[0] -ReTrim
Write-Host "[INFO] Final TRIM completed successfully." -ForegroundColor Green

Write-Host "Windows preparation complete! Poweroff and proceed with Linux backup."
