# PowerShell Scripts to prepare Windows drive for backup and revert preparations after restore
# (overall 4 scripts: common, prepare.b4_reboot, prepare.after_reboot, revert)
# this is script common

function Recursively-Remove-Files-If-Possible {
    param (
        [string]${Path}
    )

    if (-Not (Test-Path ${Path})) {
        Write-Host "[ERROR] Path '${Path}' does not exist. Skipping cleanup." -ForegroundColor Red
        return
    }

    Write-Host "[INFO] Deleting files from: ${Path}" -ForegroundColor Green

    Get-ChildItem -Path ${Path} -File -Recurse | ForEach-Object {
        Try {
            ${filePath} = $_.FullName
            Write-Host "[INFO] Deleting ${filePath}" -ForegroundColor Green
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
        } Catch {
            Write-Host "[WARNING] Could not delete: ${filePath} (File in use)" -ForegroundColor Yellow
        }
    }

    Write-Host "[INFO] File cleanup in ${Path} completed." -ForegroundColor Green
}


function Disable-Automatic-Suspend-Hibernate {
    ${currentScheme} = (powercfg -getactivescheme) -replace '.*GUID:\s*([a-f0-9\-]+).*', '$1'

    # Get all power scheme GUIDs
    ${schemes} = powercfg -l | ForEach-Object {
        if ($_ -match 'Power Scheme GUID: ([\w-]+)') { $matches[1] }
    }

    foreach (${scheme} in ${schemes}) {
        Write-Host "Modifying scheme: ${scheme}"

        # Disable Sleep
        powercfg /setacvalueindex ${scheme} SUB_SLEEP STANDBYIDLE 0
        powercfg /setdcvalueindex ${scheme} SUB_SLEEP STANDBYIDLE 0
    
        # Disable Hibernate
        powercfg /setacvalueindex ${scheme} SUB_SLEEP HIBERNATEIDLE 0
        powercfg /setdcvalueindex ${scheme} SUB_SLEEP HIBERNATEIDLE 0
    
        # Optionally disable display timeout
        #powercfg /setacvalueindex ${scheme} SUB_VIDEO VIDEOIDLE 0
        #powercfg /setdcvalueindex ${scheme} SUB_VIDEO VIDEOIDLE 0

        # Apply scheme (optional: only if you want to activate each one)
        powercfg /S ${scheme}
    }

    powercfg /S ${currentScheme}
}

    
function Enable-Bitlocker-If-Needed {
    param (
        [Parameter(Mandatory)]
        [ValidatePattern("^[A-Z]:$")]
        [string]${Drive}
    )

    ${volume} = Get-BitLockerVolume -MountPoint ${Drive}
    ${pStat} =  $volume.ProtectionStatus
    Write-Host "[INFO] BitLocker status on ${Drive} (volume ${volume}):  ${pStat}" -ForegroundColor Green

    if (${volume} -and ${pStat} -ne 'On') {
        Write-Host "[INFO] Enabling BitLocker on ${Drive}" -ForegroundColor Green
        manage-bde -protectors -add ${Drive} -TPM
        manage-bde -protectors -add ${Drive} -RecoveryPassword

        ${keysDrive} = Get-Volume | Where-Object { $_.FileSystemLabel -eq ${keysDriveLabel} -and $_.DriveType -eq 'Removable' }
        Write-Host "[INFO] USB drive with LABEL ${keysDriveLabel} to save Bitlocker protectors: ${keysDrive}" -ForegroundColor Green
        if (${keysDrive}) {
            ${keysDriveRoot} = (${keysDrive}.DriveLetter + ":\")
            ${filePath} = Join-Path -Path ${keysDriveRoot} -ChildPath "bitlocker_protectors.txt"
            manage-bde -protectors -get c: | Out-File -FilePath ${filePath} -Encoding utf8
            Write-Host "[INFO] Bitlocker protectors saved successfully to ${filePath}" -ForegroundColor Green
        }
        else {
            Write-Host "[ERROR] No removable drive found with label '${keysDriveLabel}'" -ForegroundColor Red
            exit 1
        }

        manage-bde -on ${Drive} -UsedSpaceOnly -SkipHardwareTest -Synchronous
        Start-Sleep -Seconds 20
    } 
    Write-Host "[INFO] BitLocker fully enabled on ${Drive}" -ForegroundColor Green
}

function Disable-BitLockerAndWait {
    param (
        [Parameter(Mandatory)]
        [ValidatePattern("^[A-Z]:$")]
        [string]${Drive}
    )

    Write-Host "[INFO] Starting BitLocker decryption on ${Drive}" -ForegroundColor Green

    # Initiate decryption
    manage-bde -off ${Drive}

    # Polling loop to check decryption status
    while ($true) {
        ${statusOutput} = manage-bde -status ${Drive}

        ${percentageLine} = ${statusOutput} | Where-Object { $_ -match 'Percentage Encrypted' }

        if (${percentageLine} -match ':\s+([0-9]+)') {
            ${percent} = [int]$matches[1]
            Write-Host "Decryption progress: ${percent}%"

            if (${percent} -eq 0) {
                Write-Host "Decryption completed."
                break
            }
        } else {
            Write-Warning "Unable to parse status output. Retrying..."
        }

        Start-Sleep -Seconds 10
    }
}

${windowsDrive} = ((Get-PSDrive -PSProvider FileSystem | Where-Object { Test-Path "$_`:\Windows" }).Root).TrimEnd("\")

${windowsDriveLetter} = ${windowsDrive}.TrimEnd(":")

$keysDriveLabel = "KEYS"

Write-Host "[INFO] windowsDrive: ${windowsDrive}" -ForegroundColor Green
Write-Host "[INFO] windowsDriveLetter: ${windowsDriveLetter}" -ForegroundColor Green

if (-not ${windowsDrive}) {
    Write-Host "[ERROR] Could not determine the Windows installation drive" -ForegroundColor Red
    exit 1
}

