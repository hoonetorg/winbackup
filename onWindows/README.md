# Steps to prepare Windows installation for backup

## Running Install-Linux on machine with Windows installed

Download sdelete with `get_sdelete.sh`

Ensure you have the correct version of sdelete with
`sha512sum -c SHA512SUMS_sdelete`

Extract `sdelete64.exe` with

`unzip SDelete.zip sdelete64.exe`

Run `windeploy.sh` in root of git repo in order to 

- Create a folder `<windrive>:\Program Files\winbackup` on Windows disk
- Copy `winbackup*.ps1` and `sdelete64.exe` files to Windows disk `<windrive>:\Program Files\winbackup`

## on Windows host

### Steps for preparation of Windows backup

Open powershell as Administrator!!!

In Powershell do:

`cd "<windrive>:\Program Files\winbackup"`

`powershell -ExecutionPolicy Bypass -File ".\winbackup_prepare.b4_reboot.ps1"`

Reboot Windows to apply changes that need a reboot

Open Powershell in Windows as Administrator!!! again and: 

`cd "<windrive>:\Program Files\winbackup"`

`powershell -ExecutionPolicy Bypass -File ".\winbackup_prepare.after_reboot.ps1"`

Poweroff Windows

### Optional: Remove activation for migrating Install to a new computer

`slmgr /upk`

`slmgr /cpky`

check success with

`slmgr /dli`

restart test period if possible

`slmgr /rearm`

... continue creating the backup on Linux

# Steps after restore of Windows

## on Windows host

### check the recovery partition by dis- and re-enabling  

```
reagentc /disable
reagentc /enable
reagentc /info
```

### probably you want to do a filesystem check on windrive

`chkdsk <windrive>: /f`

followed by a reboot

### Steps to revert backup preparations after restore

we assume that scripts are already copied from preparation 

Open powershell as Administrator!!!

In Powershell do:

`cd "<windrive>:\Program Files\winbackup"`

`powershell -ExecutionPolicy Bypass -File ".\winbackup_revert.ps1"`

reboot

... restore finished

