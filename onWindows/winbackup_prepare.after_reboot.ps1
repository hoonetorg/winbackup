# PowerShell Scripts to prepare Windows drive for backup and revert preparations after restore
# (overall 4 scripts: common, prepare.b4_reboot, prepare.after_reboot, revert)
# this is script prepare.after_reboot

. ".\winbackup.common.ps1"

Write-Host "[INFO] Step 5: Deleting all system restore points" -ForegroundColor Green
vssadmin delete shadows /all /quiet

Write-Host "[INFO] Step 6: Running disk cleanup and Storage Sense" -ForegroundColor Green
Write-Host "[INFO] Running disk cleanup" -ForegroundColor Green
cleanmgr /sagerun:1

Write-Host "[INFO] Running Storage Sense" -ForegroundColor Green
Start-Process -NoNewWindow -Wait -FilePath "cmd.exe" -ArgumentList "/c cleanmgr /verylowdisk"

Write-Host "[INFO] Step 7: Compacting Windows system files" -ForegroundColor Green
compact.exe /CompactOS:always

Write-Host "[INFO] Step 8: Removing user and system temp files" -ForegroundColor Green
Recursively-Remove-Files-If-Possible -Path "$env:TEMP\*"
Recursively-Remove-Files-If-Possible -Path "${windowsDrive}\Windows\Temp\*"

Write-Host "[INFO] Step 9: Deleting Windows update cache" -ForegroundColor Green
Stop-Service wuauserv -Force
Recursively-Remove-Files-If-Possible -Path "${windowsDrive}\Windows\SoftwareDistribution\Download\*"
# not required, we poweroff and backup
#Start-Service wuauserv

Write-Host "[INFO] Step 10: Deleting Windows logs" -ForegroundColor Green
Recursively-Remove-Files-If-Possible -Path "${windowsDrive}\Windows\Logs\*"

Write-Host "[INFO] Step 11: Clear Windows delivery optimization cache ${windowsDrive}\ProgramData\Microsoft\Windows\DeliveryOptimization" -ForegroundColor Green
Recursively-Remove-Files-If-Possible -Path "${windowsDrive}\ProgramData\Microsoft\Windows\DeliveryOptimization\*"

Write-Host "[INFO] Step 12: Defragmenting the volume ${windowsDrive}" -ForegroundColor Green
optimize-volume -DriveLetter ${windowsDriveLetter} -Defrag

Write-Host "[INFO] Step 13: Trimming the volume ${windowsDrive}" -ForegroundColor Green
optimize-volume -DriveLetter ${windowsDriveLetter} -ReTrim
Write-Host "[INFO] Optimization completed for ${windowsDrive}." -ForegroundColor Green

Write-Host "[INFO] Step 14: Shrink partition to min size + buffer" -ForegroundColor Green
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
    Write-Host "[INFO] Partition shrink complete" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Not enough shrinkable space - skipping shrink step" -ForegroundColor Yellow
}

Write-Host "[INFO] Step 15: Zero free space (use sdelete64 from Sysinternals)" -ForegroundColor Green
Write-Host "[INFO] Zero free space of Windows volume ${windowsDrive}" -ForegroundColor Green
Start-Process -NoNewWindow -Wait -FilePath "${windowsDrive}\Program Files\winbackup\sdelete64.exe" -ArgumentList "-accepteula -q -z ${windowsDrive}"
Write-Host "[INFO] Wrinting zeros completed for ${windowsDrive}" -ForegroundColor Green

Write-Host "[INFO]  Step 16: Final TRIM" -ForegroundColor Green
Write-Host "[INFO] Performing final TRIM operation" -ForegroundColor Green
optimize-volume -DriveLetter ${windowsDriveLetter} -ReTrim
Write-Host "[INFO] Final TRIM completed successfully" -ForegroundColor Green

Write-Host "Windows preparation complete! Poweroff and proceed with Linux backup ..."
