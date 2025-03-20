# PowerShell Scripts to prepare Windows drive for backup and revert preparations after restore
# (overall 4 scripts: common, prepare.b4_reboot, prepare.after_reboot, revert)
# this is script prepare.b4_reboot

. ".\winbackup.common.ps1"

Write-Host "[INFO] Step 1 Check BitLocker status and disable if needed" -ForegroundColor Green

${volume} = Get-BitLockerVolume -MountPoint ${windowsDrive}
${pStat} =  $volume.ProtectionStatus
Write-Host "[INFO] BitLocker status on ${windowsDrive} (volume ${volume}):  ${pStat}" -ForegroundColor Green

if (${volume} -and ${pStat} -ne 'On') {
    Write-Host "[INFO] Enabling BitLocker on ${windowsDrive} to ensure full deactivation." -ForegroundColor Green
    manage-bde -on ${windowsDrive}
    Start-Sleep -Seconds 20
} 

Write-Host "[INFO] Disabling BitLocker on ${windowsDrive}." -ForegroundColor Green
manage-bde -off ${windowsDrive}
Write-Host "[INFO] BitLocker fully disabled on Windows volume." -ForegroundColor Green


Write-Host "[INFO] Step 2: Disable Hibernation and Pagefile " -ForegroundColor Green
Write-Host "[INFO] Disable Hibernation" -ForegroundColor Green
powercfg -h off

Write-Host "[INFO] Disabling pagefile..." -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" `
                 -Name "PagingFiles" -Value "" -Type MultiString
Write-Host "[WARNING] Reboot required..." -ForegroundColor Yellow


Write-Host "[INFO] Step 3: Stop and disable Prefetch and Superfetch (Sysmain) and delete Prefetch and Superfetch Files" -ForegroundColor Green
Write-Host "[INFO] Disabling Prefetch" -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0

Write-Host "[INFO] Disabling Superfetch(SysMain)" -ForegroundColor Green
Stop-Service -Name "SysMain" -Force
Set-Service -Name "SysMain" -StartupType Disabled

Write-Host "[INFO] Removing files in C:\Windows\Prefetch" -ForegroundColor Green
#Remove-Item -Path "C:\Windows\Prefetch\*" -Force -Recurse
recursively-Remove-Files-If-Possible -Path "C:\Windows\Prefetch\*"

Write-Host "[INFO] Prefetch and Superfetch disabled. Cache cleared." -ForegroundColor Green

Write-Host "Windows preparation part 1 (b4 reboot) complete. Please reboot and continue with part 2 ..."

