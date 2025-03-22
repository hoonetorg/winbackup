DISK="/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_winbackup"
#DISK="/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_winrestore"
MOUNTDIR="/winbackup/windows"
APPDIR="${MOUNTDIR}/Program Files/winbackup"

echo
echo "create mountdir"
sudo mkdir -p "${MOUNTDIR}"

echo
echo "mount"
sudo mount "${DISK}-part3" "${MOUNTDIR}"

echo
echo "create app dir"
sudo mkdir -p "${APPDIR}"

echo
echo "deploy app"
sudo cp onWindows/winbackup* onWindows/sdelete64.exe "${APPDIR}"

echo
echo "umount"
sudo umount "${MOUNTDIR}"

echo
echo "rmdir"
sudo rmdir -p  "${MOUNTDIR}"

echo
echo "sync"
sudo sync
