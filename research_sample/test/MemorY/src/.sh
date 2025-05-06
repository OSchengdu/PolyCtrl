rm -rf bin
mkdir bin
nasm -f bin boot/boot.asm -o bin/boot.bin
nasm -f bin boot/bootloader.asm -o bin/bootloader.bin
nasm -f bin user/cli.asm -o bin/cli.bin
