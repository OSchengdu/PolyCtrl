#!/bin/bash

ASM=nasm
ASMFLAGS="-f elf64"
LD=ld
LDFLAGS="-m elf_x86_64"
SRC_DIR="src"
BIN_DIR="bin"
OUTPUT="nasm_k.bin"


echo "Cleaning up..."
rm -rf $BIN_DIR/*
mkdir -p $BIN_DIR


echo "Building bootloader..."
$ASM $ASMFLAGS $SRC_DIR/boot/boot.asm -o $BIN_DIR/boot.o
$ASM $ASMFLAGS $SRC_DIR/boot/bootloader.asm -o $BIN_DIR/bootloader.o


echo "Building kernel..."
$ASM $ASMFLAGS $SRC_DIR/kernel/memory.asm -o $BIN_DIR/memory.o
$ASM $ASMFLAGS $SRC_DIR/interrupt/interrupt.asm -o $BIN_DIR/interrupt.o
$ASM $ASMFLAGS $SRC_DIR/drivers/apic.asm -o $BIN_DIR/apic.o
$ASM $ASMFLAGS $SRC_DIR/drivers/hpet.asm -o $BIN_DIR/hpet.o
$ASM $ASMFLAGS $SRC_DIR/drivers/serial.asm -o $BIN_DIR/serial.o
$ASM $ASMFLAGS $SRC_DIR/fs/fs.asm -o $BIN_DIR/fs.o
$ASM $ASMFLAGS $SRC_DIR/init/64Bmode.asm -o $BIN_DIR/64Bmode.o
$ASM $ASMFLAGS $SRC_DIR/init/bus.asm -o $BIN_DIR/bus.o
$ASM $ASMFLAGS $SRC_DIR/init/storage.asm -o $BIN_DIR/storage.o
$ASM $ASMFLAGS $SRC_DIR/kernel/scheduler.asm -o $BIN_DIR/scheduler.o
$ASM $ASMFLAGS $SRC_DIR/net/net.asm -o $BIN_DIR/net.o
$ASM $ASMFLAGS $SRC_DIR/user/cli.asm -o $BIN_DIR/cli.o
$ASM $ASMFLAGS $SRC_DIR/user/syscall.asm -o $BIN_DIR/syscall.o
$ASM $ASMFLAGS $SRC_DIR/sysvar/sysvar.asm -o $BIN_DIR/sysvar.o


echo "Linking..."
$LD $LDFLAGS -o $BIN_DIR/$OUTPUT $BIN_DIR/*.o


if [ $? -eq 0 ]; then
    echo "Build successful! Output: $BIN_DIR/$OUTPUT"
else
    echo "Build failed!"
fi
