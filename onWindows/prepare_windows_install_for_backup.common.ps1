# PowerShell Scripts to prepare Windows drive for backup (overall 3 scripts: common, b4_reboot, after_reboot)
# this is script common
# Required sdelete64.exe from https://download.sysinternals.com/files/SDelete.zip
# Scripts and sdelete64.exe must be copied to <windowsDrive>\Program Files\winbackup\

function recursively-Remove-Files-If-Possible {
    param (
        [string]${Path}
    )

    if (-Not (Test-Path ${Path})) {
        Write-Host "[ERROR] Path '${Path}' does not exist. Skipping cleanup." -ForegroundColor Red
        return
    }

    Write-Host "[INFO] Deleting files from: ${Path}" -ForegroundColor Cyan

    Get-ChildItem -Path ${Path} -File -Recurse | ForEach-Object {
        Try {
            ${filePath} = $_.FullName
            Write-Host "[INFO] Deleting ${filePath}" -ForegroundColor Yellow
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
        } Catch {
            Write-Host "[WARNING] Could not delete: ${filePath} (File in use)" -ForegroundColor Yellow
        }
    }

    Write-Host "[INFO] File cleanup in ${Path} completed." -ForegroundColor Green
}

${windowsDrive} = ((Get-PSDrive -PSProvider FileSystem | Where-Object { Test-Path "$_`:\Windows" }).Root).TrimEnd("\")

${windowsDriveLetter} = ${windowsDrive}.TrimEnd(":")


Write-Host "[INFO] windowsDrive: ${windowsDrive}" -ForegroundColor Yellow
Write-Host "[INFO] Windows Drive Letter: ${windowsDriveLetter}" -ForegroundColor Yellow

if (-not ${windowsDrive}) {
    Write-Host "[ERROR] Could not determine the Windows installation drive." -ForegroundColor Red
    exit 1
}

