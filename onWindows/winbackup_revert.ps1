# PowerShell Scripts to prepare Windows drive for backup and revert preparations after restore
# (overall 4 scripts: common, prepare.b4_reboot, prepare.after_reboot, revert)
# this is script revert

. ".\winbackup.common.ps1"

Write-Host "[INFO] Step 1 Check BitLocker status and enable if needed" -ForegroundColor Green
Enable-Bitlocker-If-Needed -Drive "${windowsDrive}"

Write-Host "[INFO] Step 2: Disable fast startup/enable hibernation and enable pagefile" -ForegroundColor Green
Write-Host "[INFO] Disable fast startup/enable hibernation" -ForegroundColor Green
powercfg -h on
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0

Write-Host "[INFO] Enabling system-managed paging file" -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
                 -Name "PagingFiles" -Value "?:\pagefile.sys" -Type MultiString
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
                 -Name "AutomaticManagedPagefile" -Value 1 -Type DWord
Write-Host "[INFO] Pagefile has been set to Windows-managed" -ForegroundColor Green
Write-Host "[WARNING] Reboot required..." -ForegroundColor Yellow


Write-Host "[INFO] Step 3: Enable prefetch and superfetch (SysMain)" -ForegroundColor Green
Write-Host "[INFO] Enabling prefetch" -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3

Write-Host "[INFO] Enabling superfetch(SysMain)" -ForegroundColor Green
Set-Service -Name "SysMain" -StartupType Automatic
Start-Service -Name "SysMain"
Write-Host "[INFO] prefetch and superfetch enabled" -ForegroundColor Green

Write-Host "[INFO] Step 4: Expand partition to max size" -ForegroundColor Green
${partition} = Get-Partition -DriveLetter ${windowsDriveLetter}
${supportedSize} = ${partition} | Get-PartitionSupportedSize
${maxSize} = ${supportedSize}.SizeMax

Write-Host "[INFO] Current partition size: $(${partition}.Size / 1MB) MB" -ForegroundColor Green
Write-Host "[INFO] Maximum supported size: $(${maxSize} / 1MB) MB" -ForegroundColor Green

if (${partition}.Size -lt ${maxSize}) {
    Resize-Partition -DriveLetter ${windowsDriveLetter} -Size ${maxSize}
    Write-Host "[INFO] Partition expanded to full available size" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Partition is already at max size - no expansion needed" -ForegroundColor Yellow
}

Write-Host "[INFO]  Step 5: Final TRIM" -ForegroundColor Green
Write-Host "[INFO] Performing final TRIM operation" -ForegroundColor Green
optimize-volume -DriveLetter ${windowsDriveLetter} -ReTrim
Write-Host "[INFO] Final TRIM completed successfully" -ForegroundColor Green

Write-Host "Reversal of Windows preparation steps complete! Reboot and use your System as usual ..."
