DISK="/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_winrestore"
#DISK="/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_winbackup"

echo
echo "GPT partition table"
#sudo sgdisk --load-backup=/backup/gpt_table.sgdisk.img ${DISK}
sudo sgdisk --load-backup=/backup/ptable_gpt_sgdisk.img ${DISK}

echo
echo "UDEV trigger and settle"
sudo udevadm trigger
sudo udevadm settle


echo
echo "lsblk and ls -al /dev/disk/by-id"
lsblk
ls -al ${DISK}*

echo
echo "p1: FAT"
#sudo partclone.fat -r -d -s /backup/p1.efi.partclone.fat.img -o ${DISK}-part1 
sudo partclone.fat -r -d -s /backup/p1_fat_partclone.fat.img -o ${DISK}-part1 

echo
echo "p2: Reserved"
#sudo dd             if=/backup/p2.reserved.dd.img i         of=${DISK}-part2 bs=1M status=progress
#sudo partclone.dd -d -s /backup/p2.reserved.partclone.dd.img -o ${DISK}-part2 
sudo partclone.dd -d -s /backup/p2_raw_partclone.dd.img -o ${DISK}-part2 

echo
echo "sync"
sudo sync

echo
echo "p3: WINDOWS NTFS"
#sudo ntfsclone --restore-image --overwrite ${DISK}-part3 /backup/p3.windows.ntfsclone.img
sudo ntfsclone --restore-image --overwrite ${DISK}-part3 /backup/p3_ntfs_ntfsclone.img

echo
echo "p4: Recovery NTFS"
#sudo ntfsclone --restore-image --overwrite ${DISK}-part4 /backup/p4.recovery.ntfsclone.img
sudo ntfsclone --restore-image --overwrite ${DISK}-part4 /backup/p4_ntfs_ntfsclone.img

echo
echo "Dummy"
