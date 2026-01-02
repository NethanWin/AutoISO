#!/bin/bash
set -e

ISO_FILE="${ISO_FILE:-ubuntu-22.04.5-desktop-amd64.iso}"

mkdir -p /work/{mnt,extract-cd,edit,dev,run,proc,sys,tmp}
cd /work

# 1) Mount ISO using losetup (Docker-safe)
echo "before mount"
LOOP_DEV=$(losetup -f --show /builder/${ISO_FILE})
mount "${LOOP_DEV}" mnt
rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd/
unsquashfs mnt/casper/filesystem.squashfs
mv squashfs-root edit
umount mnt
losetup -d "${LOOP_DEV}"

# 2) Create customization script
cat <<'CUST' > edit/customize.sh
#!/bin/sh
set -e

mkdir -p /usr/share/backgrounds
cp /usr/share/backgrounds/warty-final-ubuntu.png /usr/share/backgrounds/custom-wallpaper.png || true

mkdir -p /usr/share/glib-2.0/schemas
cat >/usr/share/glib-2.0/schemas/99_custom_wallpaper.gschema.override <<'OVR'
[org.gnome.desktop.background]
picture-uri='file:///usr/share/backgrounds/custom-wallpaper.png'
picture-uri-dark='file:///usr/share/backgrounds/custom-wallpaper.png'
OVR

glib-compile-schemas /usr/share/glib-2.0/schemas
CUST

chmod +x edit/customize.sh

# 3) Create ALL mount points FIRST
mkdir -p edit/{dev,run,proc,sys,tmp,lib,lib64}

# 4) Bind mount host filesystems
mount --bind /dev    edit/dev
mount --bind /run    edit/run
mount --bind /proc   edit/proc
mount --bind /sys    edit/sys
mount --bind /tmp    edit/tmp
mount --bind /lib    edit/lib
mount --bind /lib64  edit/lib64

# 5) Run customization in chroot
#chroot edit /bin/bash -c "/customize.sh"
chroot edit /bin/bash -c "echo customize.sh"

# 6) Unmount (reverse order)
umount edit/tmp
umount edit/sys
umount edit/proc
umount edit/run
umount edit/dev
umount edit/lib64 edit/lib
rm edit/customize.sh

# 7) Rebuild SquashFS
mksquashfs edit extract-cd/casper/filesystem.squashfs -noappend

# 8) Update filesystem size
printf "$(du -sx --block-size=1 edit | cut -f1)" > extract-cd/casper/filesystem.size

# 9) Generate new ISO
mkdir -p /output
xorriso \
  -as mkisofs \
  -r -V "CustomUbuntu" \
  -o /output/custom-ubuntu.iso \
  -J -l -cache-inodes \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  extract-cd

echo "ISO created at /output/custom-ubuntu.iso"
