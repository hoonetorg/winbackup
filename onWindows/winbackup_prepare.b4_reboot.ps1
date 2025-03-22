# PowerShell Scripts to prepare Windows drive for backup and revert preparations after restore
# (overall 4 scripts: common, prepare.b4_reboot, prepare.after_reboot, revert)
# this is script prepare.b4_reboot

. ".\winbackup.common.ps1"

Write-Host "[INFO] Step 1: Disable automatic suspend and hibernate" -ForegroundColor Green
Disable-Automatic-Suspend-Hibernate

Write-Host "[INFO] Step 2: Check BitLocker status and enable first if needed and disable afterwards" -ForegroundColor Green
Enable-Bitlocker-If-Needed -Drive "${windowsDrive}"

Write-Host "[INFO] Disabling BitLocker on ${windowsDrive}" -ForegroundColor Green
Disable-BitLockerAndWait -Drive "${windowsDrive}"
Write-Host "[INFO] BitLocker fully disabled on ${windowsDrive}" -ForegroundColor Green

Write-Host "[INFO] Step 3: Disable fast startup/hibernation and pagefile" -ForegroundColor Green
Write-Host "[INFO] Disable fast startup/hibernation" -ForegroundColor Green
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0
powercfg -h off

Write-Host "[INFO] Disabling pagefile" -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
                 -Name "PagingFiles" -Value "" -Type MultiString
Write-Host "[WARNING] Reboot required..." -ForegroundColor Yellow


Write-Host "[INFO] Step 4: Stop and disable prefetch and superfetch (SysMain) and delete prefetch and superfetch files" -ForegroundColor Green
Write-Host "[INFO] Disabling prefetch" -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0

Write-Host "[INFO] Disabling superfetch(SysMain)" -ForegroundColor Green
Stop-Service -Name "SysMain" -Force
Set-Service -Name "SysMain" -StartupType Disabled

Write-Host "[INFO] Removing files in ${windowsDrive}\Windows\Prefetch" -ForegroundColor Green
#Remove-Item -Path "${windowsDrive}\Windows\Prefetch\*" -Force -Recurse
Recursively-Remove-Files-If-Possible -Path "${windowsDrive}\Windows\Prefetch\*"

Write-Host "[INFO] Prefetch and superfetch(SysMain) disabled, cache cleared" -ForegroundColor Green

Write-Host "Windows preparation part 1 (b4 reboot) complete, please reboot and continue with part 2 ..."

