DISK="/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_winbackup"
#DISK="/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_winrestore"

echo
echo "Dummy"

echo
echo "p1: FAT"
sudo partclone.fat -c -d -s ${DISK}-part1 -o /backup/p1.efi.partclone.fat.img

echo
echo "p2: Reserved"
sudo partclone.dd  -d -s ${DISK}-part2 -o /backup/p2.reserved.partclone.dd.img
#sudo dd              if=${DISK}-part2 of=/backup/p2.reserved.dd.img bs=1M status=progress

echo
echo "sync"
sudo sync

echo
echo "p3: WINDOWS NTFS"
sudo ntfsclone --save-image -o /backup/p3.windows.ntfsclone.img ${DISK}-part3

echo
echo "p4: Recovery NTFS"
sudo ntfsclone --save-image -o /backup/p4.recovery.ntfsclone.img ${DISK}-part4

echo
echo "GPT partition table"
sudo sgdisk --backup=/backup/gpt_table.sgdisk.img ${DISK}
