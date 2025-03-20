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


Write-Host "[INFO] Step 3: Stop and disable Prefetch and Superfetch (Sysmain) and delete Prefetch and Superfetch Files" -ForegroundColor Green
Write-Host "[INFO] Disabling Prefetch" -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0

Write-Host "[INFO] Disabling Superfetch(SysMain)" -ForegroundColor Green
Stop-Service -Name "SysMain" -Force
Set-Service -Name "SysMain" -StartupType Disabled

Write-Host "[INFO] Prefetch and Superfetch disabled. Cache cleared." -ForegroundColor Green

Write-Host "[INFO] Step 4: Expand Partition to partition size" -ForegroundColor Green
${partition} = Get-Partition -DriveLetter ${windowsDriveLetter}
${supportedSize} = ${partition} | Get-PartitionSupportedSize
${maxShrinkSize} = ${supportedSize}.SizeMin
${bufferSize} = 5 * 1024 * 1024 * 1024  # 5GB buffer
${shrinkSize} = ${maxShrinkSize} + ${bufferSize}

Write-Host "[INFO] partition ${partition}" -ForegroundColor Green
Write-Host "[INFO] supportedSize ${supportedSize}" -ForegroundColor Green
Write-Host "[INFO] maxShrinkSize ${maxShrinkSize}" -ForegroundColor Green
Write-Host "[INFO] bufferSize ${bufferSize}" -ForegroundColor Green
Write-Host "[INFO] shrinkSize ${shrinkSize}" -ForegroundColor Green


if (${maxShrinkSize} -gt 0) {
    Write-Host "[INFO] Shrinking partition to $(${shrinkSize} / 1MB) MB..." -ForegroundColor Green
    Resize-Partition -DriveLetter ${windowsDriveLetter} -Size ${shrinkSize}
    Write-Host "[INFO] Partition shrink complete." -ForegroundColor Green
} else {
    Write-Host "[WARNING] Not enough shrinkable space. Skipping shrink step." -ForegroundColor Green
}

Write-Host "[INFO]  Step 15: Final TRIM" -ForegroundColor Green
Write-Host "[INFO] Performing final TRIM operation..." -ForegroundColor Green
optimize-volume -DriveLetter ${windowsDrive}[0] -ReTrim
Write-Host "[INFO] Final TRIM completed successfully." -ForegroundColor Green

Write-Host "Reversal of Windows preparation steps complete! Reboot and use your System as usual ..."
