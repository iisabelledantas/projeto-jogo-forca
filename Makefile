ASM = nasm
DD = dd
QEMU = qemu-system-i386

BOOT_BIN = boot.bin
KERNEL_BIN = kernel.bin
IMAGE = image.bin

$(BOOT_BIN): boot/boot.asm
	$(ASM) -f bin -o $@ $<

$(KERNEL_BIN): kernel/kernel_entry.asm
	$(ASM) -f bin -o $@ $<

$(IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	$(DD) if=/dev/zero of=$@ bs=512 count=2880
	$(DD) if=$(BOOT_BIN) of=$@ bs=512 count=1 conv=notrunc
	$(DD) if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc

build: $(IMAGE)
	@echo "=== Build Jogo Forca ==="

run: $(IMAGE)
	$(QEMU) -fda $(IMAGE) -boot a -display sdl

clean:
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(IMAGE)

.PHONY: build run clean