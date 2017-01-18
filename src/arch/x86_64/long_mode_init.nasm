global long_mode_start

section .text
bits 64
long_mode_start:
  ; load 0 into all data segment registers
  mov ax, 0
  mov ss, ax
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  ; call rust_main
  extern rust_main
  call rust_main

  ; print `OKAY` to the screen
  mov rax, 0x4f724f204f534f4f
  mov qword [0xb8000], rax
  mov rax, 0x4f724f754f744f65
  mov qword [0xb8008], rax
  mov rax, 0x4f214f644f654f6e
  mov qword [0xb8010], rax
  hlt
