# Steps to prepare Windows installation for backup
Download sdelete with `get_sdelete.sh` on Linux

Ensure you have the correct version of sdelete with
`sha512sum -c SHA512SUMS_sdelete`

Extract `sdelete64.exe` with

`unzip SDelete.zip sdelete64.exe`

On Windows Host create a folder `<windrive>:\Program Files\winbackup`

Copy `winbackup*.ps1` and `sdelete64.exe` files to Windows Host `<windrive>:\Program Files\winbackup`

Open powershell as Administrator!!!

In Powershell do:

`cd "<windrive>:\Program Files\winbackup"`

`powershell -ExecutionPolicy Bypass -File ".\winbackup_prepare.b4_reboot.ps1"`

Reboot Windows to apply changes that need a reboot

Open Powershell in Windows as Administrator!!! again and: 

`cd "<windrive>:\Program Files\winbackup"`

`powershell -ExecutionPolicy Bypass -File ".\winbackup_prepare.after_reboot.ps1"`

Poweroff Windows

... continue creating the backup on Linux

# Steps to revert backup preparations after restore

we assume that scripts are already copied from preparation 

Open powershell as Administrator!!!

In Powershell do:

`cd "<windrive>:\Program Files\winbackup"`

`powershell -ExecutionPolicy Bypass -File ".\winbackup_revert.ps1"`

reboot

... restore finished

