global start
extern long_mode_start

section .text
bits 32
start:
  mov esp, stack_top

  call check_multiboot
  call check_cpuid
  call check_long_mode

  call set_up_page_tables
  call enable_paging

  ; load the 64-bit GDT
  lgdt [gdt64.pointer]

  jmp gdt64.code:long_mode_start
  hlt
set_up_page_tables:
  ; map first p4 entry  to p4 table
  mov eax, p3_table
  or eax, 0b11 ; present + writable
  mov [p4_table], eax

  ; mpa first p3 entry to p2 table
  mov eax, p2_table
  or eax, 0b11 ; present + wriable
  mov [p3_table], eax

  ; map each p2 entry to a huge 2 MiB page
  mov ecx, 0 ; counter variable

.map_p2_table:
  ; map ecx-th p2 entry to a huge page that starts at address 2MiB*ecx
  mov eax, 0x200000 ; 2MiB
  mul ecx ; start address of ecx
  or eax, 0b10000011 ; [resent + writable
  mov [p2_table + ecx * 8], eax ; map ecx-th entry

  inc ecx ; increase counter
  cmp ecx, 512 ; if counter == 512, te whole p2 table is mapped
  jne .map_p2_table ; else map the next entry

  ret

enable_paging:
  ; load p3 to cr3 register (cpu uses this to access the p4 table)
  mov eax, p4_table
  mov cr3, eax

  ; enable PAE-flag in cr4 (Physical Address extension)
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; set the long mode bit in the EFER SMR (model specific register)
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  ; enable paging in the cr0 register
  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax

  ret

; Prints `ERR: ` and the given error code to screen and hangs
; parameter: error code (in ascii) in al
error:
  mov dword [0xb8000], 0x4f524f45
  mov dword [0xb8000], 0x4f3a4f52
  mov dword [0xb8000], 0x4f204f20
  mov byte [0xb800a], al
  hlt

check_multiboot:
  cmp eax, 0x36d76289
  jne .no_multiboot
  ret
.no_multiboot:
  mov al, "0"
  jmp error

check_cpuid:
  ; Check if CPUID is supported by attempting to flip this ID bit (bit 21)
  ; in the FLAGS register. If we can flip it, CPUID is available

  ; Copy FLAGS into EAX via stack
  pushfd
  pop eax

  ; Copy to ECX as well for comparing later
  mov ecx, eax

  ; Flip the ID bit
  xor eax, 1 << 21

  ; Copy EAX to FLAGS via the stack
  push eax
  popfd

  ; Compare EAX and ECX. If they are equal then that means the bit
  ; wasn't flipped, and CPUID isn't supported.
  cmp eax, ecx
  je .no_cpuid
  ret
.no_cpuid:
  mov al, "1"
  jmp error
check_long_mode:
  ; test if extended processor info is available
  mov eax, 0x80000000 ; implicit argument for cpuid
  cpuid
  cmp eax, 0x80000001 ; it needs to be at least 0x80000001
  jb .no_long_mode ; if it's less, the CPU is too old for long mode

  ; use extended info to test if long mode is available
  mov eax, 0x80000001 ; argument for extended processor info
  cpuid ; returns various feature bit in ecx and edx
  test edx, 1 << 29 ; if it's not set, there is no long mode
  jz .no_long_mode ; if it's not set, there is no long mode
  ret
.no_long_mode:
  mov al, "2"
  jmp error

section .rodata
gdt64:
  dq 0 ; zero entry
.code: equ $ - gdt64
  dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segment
.pointer:
  dw $ - gdt64 - 1
  dq gdt64



section .bss
align 4096
p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096
stack_bottom:
  resb 64
stack_top:
