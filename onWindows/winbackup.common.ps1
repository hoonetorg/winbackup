# PowerShell Scripts to prepare Windows drive for backup and revert preparations after restore
# (overall 4 scripts: common, prepare.b4_reboot, prepare.after_reboot, revert)
# this is script common

function recursively-Remove-Files-If-Possible {
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

${windowsDrive} = ((Get-PSDrive -PSProvider FileSystem | Where-Object { Test-Path "$_`:\Windows" }).Root).TrimEnd("\")

${windowsDriveLetter} = ${windowsDrive}.TrimEnd(":")

$keysDriveLabel = "KEYS"

Write-Host "[INFO] windowsDrive: ${windowsDrive}" -ForegroundColor Green
Write-Host "[INFO] Windows Drive Letter: ${windowsDriveLetter}" -ForegroundColor Green

if (-not ${windowsDrive}) {
    Write-Host "[ERROR] Could not determine the Windows installation drive." -ForegroundColor Red
    exit 1
}

