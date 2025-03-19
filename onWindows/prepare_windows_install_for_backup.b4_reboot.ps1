# PowerShell Scripts to prepare Windows drive for backup (overall 3 scripts: common, b4_reboot, after_reboot)
# this is script b4 reboot
# Required sdelete64.exe from https://download.sysinternals.com/files/SDelete.zip
# Scripts and sdelete64.exe must be copied to <windowsDrive>\Program Files\winbackup\

. ".\prepare_windows_install_for_backup.common.ps1"

Write-Host "[INFO] Step 1 Check BitLocker status and disable if needed" -ForegroundColor Green

${volume} = Get-BitLockerVolume -MountPoint ${windowsDrive}
${pStat} =  $volume.ProtectionStatus
Write-Host "[INFO] BitLocker status on ${windowsDrive} (volume ${volume}):  ${pStat}" -ForegroundColor Yellow

if (${volume} -and ${pStat} -ne 'On') {
    Write-Host "[INFO] Enabling BitLocker on ${windowsDrive} to ensure full deactivation." -ForegroundColor Yellow
    manage-bde -on ${windowsDrive}
    Start-Sleep -Seconds 20
} 

Write-Host "[INFO] Disabling BitLocker on ${windowsDrive}." -ForegroundColor Yellow
manage-bde -off ${windowsDrive}
Write-Host "[INFO] BitLocker fully disabled on Windows volume." -ForegroundColor Green


Write-Host "[INFO] Step 2: Disable Hibernation and Pagefile " -ForegroundColor Green
Write-Host "[INFO] Disable Hibernation" -ForegroundColor Yellow
powercfg -h off

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

