#!/bin/bash

# 配置
ASM=nasm
ASMFLAGS="-f elf32"
LD=ld
LDFLAGS="-m elf_i386 -Ttext 0x1000"
SRC_DIR="src"
BIN_DIR="bin"
OUTPUT="kernel.bin"

# 清理旧文件
echo "Cleaning up..."
rm -rf $BIN_DIR/*
mkdir -p $BIN_DIR

# 编译引导程序
echo "Building bootloader..."
$ASM -f bin $SRC_DIR/boot/boot.asm -o $BIN_DIR/boot.bin

# 编译内核模块

echo "Linking kernel..."

echo "Creating disk image..."
dd if=/dev/zero of=$BIN_DIR/os.img bs=512 count=2880
dd if=$BIN_DIR/boot.bin of=$BIN_DIR/os.img conv=notrunc
dd if=$BIN_DIR/$OUTPUT of=$BIN_DIR/os.img bs=512 seek=1 conv=notrunc

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "Build successful! Output: $BIN_DIR/os.img"
else
    echo "Build failed!"
fi
