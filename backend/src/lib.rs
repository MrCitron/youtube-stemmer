use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn HelloWorld() {
    println!("Hello from Rust Shared Library!");
}

#[no_mangle]
pub extern "C" fn CheckStatus() -> *mut c_char {
    let s = CString::new("Rust backend is alive and well").unwrap();
    s.into_raw()
}

#[no_mangle]
pub extern "C" fn FreeString(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(s);
    }
}

// TODO: Implement other functions to match Go signatures:
// MixStems, CreateZip, CreateMp3Zip, InitStemmer, SplitAudio, GetMetadata, DownloadAudio
