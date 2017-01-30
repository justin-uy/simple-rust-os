#![feature(unique, lang_items, const_fn)]
#![no_std]
extern crate rlibc;
extern crate volatile;
mod vga_buffer;

#[no_mangle]
pub extern fn rust_main() {
    vga_buffer::print_something();

    loop {}
}

#[lang = "eh_personality"]
extern fn eh_personality() {
}

#[lang = "panic_fmt"]
#[no_mangle]
pub extern fn panic_fmt() -> ! {
    loop {}
}

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! {
    loop {}
}
