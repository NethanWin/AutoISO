#!/bin/bash

sp -S squashfs-tools

mkdir -p ubuntu-iso-work/{iso,edit,squashfs}
cd ubuntu-iso-work

cp .iso .


sudo mount -o loop .iso iso

sudo unsqu
