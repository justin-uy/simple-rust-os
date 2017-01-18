# simple-rust-os - learning the basics of how Operating Systems are constructed

Following the tutorials by Philipp Oppermann: http://os.phil-opp.com/

## Progress

* [x] Minimal x86 kernel that boots using multiboot 2.0 spec
* [x] Setup page tables and GDT to enter long mode
* [x] Setup rust and call compiled rust binary in kernel
* [ ] Print to Screen - create a VGA Text Buffer abstraction for writing strings in different colors to the screen.

## Issues / Notes

There are issues building the ISO natively in my Ubuntu installation because my
hardware utilizes an EFI system partition. To get around this, I started using
an LXD managed container that is setup with the appropriate grub package
(grub-pc instead of grub-efi), where I build the iso and run it in qemu on the
host.

Unfortunately, this still causes issues later once we setup rust which is
built into the iso because the tutorial has the Makefile setup so that it
builds the iso every time we do: `make run`. In order to get around that issue,
we avoid calling `make run` on the host and install call qemu directly using:
```
qemu-system-x86_64 -d int -no-reboot -cdrom build/os-x86_64.iso 2> debug.log
```
I also chose to write stderr to a file to make debugging runtime errors
more easily.



