qemu-system-x86_64  \
    -machine q35 \
    -name "PolyCtrl" \
    -m 256 \
    -smp sockets=1,cpus=4 \
    -netdev socket,id=testnet,listen=:1234 \
    -device e1000,netdev=testnet,mac=10:11:12:08:25:40 \
    -drive id=disk0,file="sys/PolyCtrl.img",if=none,format=raw \
    -device ide-hd,drive=disk0 \
    -serial file:"sys/S.log" \
    -monitor telnet:localhost:8086,server,nowait

