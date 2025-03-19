# Use an official Ubuntu base image
FROM ubuntu:24.04

# Set environment to suppress interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    partclone \
    xorriso \
    python3 \
    qemu-utils \
    dosfstools \
    btrfs-progs \
    kpartx \
    parted \
    fuse3 \
    sudo \
    rsync \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create working directories
WORKDIR /winbackup

# Create the data files directory
#RUN mkdir -p /winbackup/input /winbackup/output 
RUN mkdir -p /work 

# Copy the build script into the container
COPY src/winbackupbuildimage.py /winbackup/

# Set the entrypoint to the build script
ENTRYPOINT ["python3", "-u", "/winbackup/winbackup.py"]
