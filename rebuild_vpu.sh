#!/bin/bash

BOARD_IP="192.168.1.41"
MODULE_PATH=".src/linux/drivers/media/platform/verisilicon/hantro-vpu.ko"

echo "1. Compiling module inside BSP container (Bypassing .deb packaging)..."
# We pipe the exact make command into the container shell and exit automatically
echo "cd .src/linux && make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- M=drivers/media/platform/verisilicon modules" | ./bsp --container-shell linux rk2410

echo "2. Pushing new module to Rock 5B..."
scp "$MODULE_PATH" rock@$BOARD_IP:/home/rock/

echo "3. Hot-reloading driver on board..."
ssh -t rock@$BOARD_IP "
sudo modprobe videobuf2-dma-contig
sudo modprobe v4l2-mem2mem
sudo insmod /home/rock/hantro-vpu.ko
lsmod | grep hantro || true
dmesg | tail -n 20
"

echo "✅ Done! Run 'sudo dmesg | tail' on the board."
