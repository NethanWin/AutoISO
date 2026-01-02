FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    ISO_FILE=ubuntu-22.04.5-desktop-amd64.iso \
    OS_VERSION=22.04.5

ENV damn="""RUN apt-get update && \
    apt-get install -y \
        wget \
        squashfs-tools \
        xorriso \
        genisoimage \
        casper \
        rsync \
        grub-pc-bin \
        grub-efi-amd64-bin \
        grub-efi-amd64-signed \
        mtools \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*"""

RUN apt-get update && \
    apt-get install -y \
        wget \
        squashfs-tools \
        rsync && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /builder

RUN wget -q https://releases.ubuntu.com/${OS_VERSION}/${ISO_FILE}

COPY docker-build-iso.sh /builder/docker-build-iso.sh
COPY chroot /builder/chroot
RUN chmod +x /builder/docker-build-iso.sh

CMD ["/builder/docker-build-iso.sh"]