DISK="/dev/disk/by-id/usb-QEMU_QEMU_HARDDISK_keys-0:0"
MOUNTDIR="/winbackup/keys"

echo
echo "create mountdir"
sudo mkfs.vfat -n KEYS -F16 -v "${DISK}"

echo
echo "mkdir"
sudo mkdir -p  "${MOUNTDIR}"

echo
echo "mount"
sudo mount "${DISK}" "${MOUNTDIR}"

echo
echo "umount"
sudo umount "${MOUNTDIR}"

echo
echo "rmdir"
sudo rmdir -p  "${MOUNTDIR}"

echo
echo "sync"
sudo sync
