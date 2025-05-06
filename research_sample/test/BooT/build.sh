# compile nasm to bin file
nasm -f bin src/boot/boot.asm -o bin/boot.bin
nasm -f bin src/boot/bootloader.asm -o bin/kernel.bin

# make up disk img
dd if=/dev/zero of=bin/os.img bs=512 count=2880

# write bin file down to img
dd if=bin/boot.bin of=bin/os.img conv=notrunc
dd if=bin/kernel.bin of=bin/os.img conv=notrunc

# run!
qemu-system-x86_64 -fda bin/os.img

# HACK: other method to run it up
# qemu(){}
# bochs(){}
# others(){}
# 
# for DEBUG
# qemu-system-x86_64 -fda bin/os.img -s -S
# gdb
# qemu_debug()
# bochs_debuug()
