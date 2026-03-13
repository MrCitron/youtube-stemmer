use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_double};
use std::path::Path;
use std::fs::File;
use std::io::{Read, BufRead, BufReader, Write};
use std::process::{Command, Stdio};
use ort::session::Session;
use ort::value::Value;
use ndarray::Array3;
use once_cell::sync::Lazy;
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, Ordering};
use symphonia::core::audio::Signal;
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

mod tempo;
mod click_gen;

static ABORT: AtomicBool = AtomicBool::new(false);

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

#[no_mangle]
pub extern "C" fn CancelTasks() {
    println!("Rust: Abort signal received");
    ABORT.store(true, Ordering::SeqCst);
}

pub type ProgressCallback = extern "C" fn(progress: c_double);

fn normalize_youtube_url(url: &str) -> String {
    if url.contains("youtu.be/") {
        if let Some(id) = url.split("youtu.be/").last() {
            let id = id.split('?').next().unwrap_or(id);
            return format!("https://www.youtube.com/watch?v={}", id);
        }
    }
    url.to_string()
}

fn get_ytdlp_path() -> String {
    let bin_name = if cfg!(windows) { "yt-dlp.exe" } else { "yt-dlp" };

    if let Ok(exe_path) = std::env::current_exe() {
        if let Some(dir) = exe_path.parent() {
            // 1. Check next to executable (Contents/MacOS/yt-dlp)
            let bundled = dir.join(bin_name);
            if bundled.exists() {
                return bundled.to_string_lossy().to_string();
            }

            // 2. Check in Resources (Contents/Resources/yt-dlp) - Standard for macOS
            #[cfg(target_os = "macos")]
            {
                if let Some(contents_dir) = dir.parent() {
                    let resources_bin = contents_dir.join("Resources").join(bin_name);
                    if resources_bin.exists() {
                        return resources_bin.to_string_lossy().to_string();
                    }
                }
            }
        }
    }
    let cwd_bin = Path::new(".").join(bin_name);
    if cwd_bin.exists() {
        return cwd_bin.to_string_lossy().to_string();
    }

    bin_name.to_string()
}

#[no_mangle]
pub extern "C" fn GetMetadata(url: *const c_char) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if url.is_null() {
            return "Error: Null URL".to_string();
        }
        let url_raw = unsafe { CStr::from_ptr(url) }.to_string_lossy();
        let url_str = normalize_youtube_url(&url_raw);
        
        println!("Rust: GetMetadata for URL: {}", url_str);

        let output = Command::new(get_ytdlp_path())
            .arg("--print")
            .arg("title")
            .arg("--print")
            .arg("uploader")
            .arg("--no-playlist")
            .arg(&url_str)
            .output();

        match output {
            Ok(out) => {
                if out.status.success() {
                    let stdout = String::from_utf8_lossy(&out.stdout);
                    let mut lines = stdout.lines();
                    let title = lines.next().unwrap_or("Unknown Title");
                    let author = lines.next().unwrap_or("Unknown Author");
                    format!("Title: {}, Author: {}", title, author)
                } else {
                    format!("Error: yt-dlp failed: {}", String::from_utf8_lossy(&out.stderr))
                }
            }
            Err(e) => format!("Error: Failed to execute yt-dlp: {}", e),
        }
    });

    let final_res = match result {
        Ok(s) => s,
        Err(_) => "Error: Panic in GetMetadata".to_string(),
    };
    CString::new(final_res).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn FreeStemmer() {
    println!("Rust: FreeStemmer entered");
    let mut guard = STEMMER.lock().unwrap();
    *guard = None;
    println!("Rust: Stemmer session dropped");
}

#[no_mangle]
pub extern "C" fn GetEstimatedBPM(path: *const c_char) -> *mut c_char {
    let result = std::panic::catch_unwind(|| {
        if path.is_null() {
            return "Error: Null path".to_string();
        }
        let path_raw = unsafe { CStr::from_ptr(path) }.to_string_lossy();
        let path_obj = Path::new(&*path_raw);
        
        match tempo::estimate_bpm(path_obj) {
            Ok(bpm) => format!("{:.2}", bpm),
            Err(e) => format!("Error: {}", e),
        }
    });

    let final_res = match result {
        Ok(s) => s,
        Err(_) => "Error: Panic in GetEstimatedBPM".to_string(),
    };
    CString::new(final_res).unwrap().into_raw()
}

fn convert_to_wav(input_path: &str, output_path: &str) -> Result<(), String> {
    let src = File::open(input_path).map_err(|e| e.to_string())?;
    let mss = MediaSourceStream::new(Box::new(src), Default::default());
    
    let mut hint = Hint::new();
    if input_path.ends_with(".mp4") || input_path.ends_with(".m4a") {
        hint.with_extension("mp4");
    } else if input_path.ends_with(".webm") {
        hint.with_extension("mkv");
    } else if input_path.ends_with(".mp3") {
        hint.with_extension("mp3");
    }

    let probed = symphonia::default::get_probe()
        .format(&hint, mss, &FormatOptions::default(), &MetadataOptions::default())
        .map_err(|e| e.to_string())?;

    let mut format = probed.format;
    let track = format.tracks().iter()
        .find(|t| t.codec_params.codec != symphonia::core::codecs::CODEC_TYPE_NULL)
        .ok_or("No supported audio track found")?;

    let mut decoder = symphonia::default::get_codecs()
        .make(&track.codec_params, &symphonia::core::codecs::DecoderOptions::default())
        .map_err(|e| e.to_string())?;

    let track_id = track.id;
    let sample_rate = track.codec_params.sample_rate.ok_or("Unknown sample rate")?;
    let target_rate = 44100;

    let mut all_samples: Vec<f32> = Vec::new();

    while let Ok(packet) = format.next_packet() {
        if ABORT.load(Ordering::Relaxed) {
            return Err("Conversion aborted".to_string());
        }
        if packet.track_id() != track_id {
            continue;
        }

        match decoder.decode(&packet) {
            Ok(decoded) => {
                let num_frames = decoded.frames();
                match decoded {
                    symphonia::core::audio::AudioBufferRef::F32(ref buf) => {
                        for i in 0..num_frames {
                            let mut sum = 0.0;
                            let planes = buf.planes().planes().len();
                            for ch in 0..2 {
                                let p = if ch < planes { ch } else { 0 };
                                sum += buf.chan(p)[i];
                            }
                            // Store as mono first for easy processing, or keep stereo?
                            // HTDemucs expects stereo, so let's keep it interleaved.
                            for ch in 0..2 {
                                let p = if ch < planes { ch } else { 0 };
                                all_samples.push(buf.chan(p)[i]);
                            }
                        }
                    },
                    _ => return Err("Unsupported audio format".to_string()),
                }
            }
            Err(symphonia::core::errors::Error::IoError(_)) => break,
            Err(e) => return Err(e.to_string()),
        }
    }

    // Resample if needed
    let final_samples = if sample_rate != target_rate {
        println!("Rust: Resampling from {}Hz to {}Hz...", sample_rate, target_rate);
        let ratio = sample_rate as f64 / target_rate as f64;
        let num_input_frames = all_samples.len() / 2;
        let num_output_frames = (num_input_frames as f64 / ratio) as usize;
        let mut resampled = Vec::with_capacity(num_output_frames * 2);

        for i in 0..num_output_frames {
            let pos = i as f64 * ratio;
            let idx = pos as usize;
            let frac = pos - idx as f64;

            for ch in 0..2 {
                let s1 = all_samples[idx * 2 + ch];
                let s2 = if idx + 1 < num_input_frames {
                    all_samples[(idx + 1) * 2 + ch]
                } else {
                    s1
                };
                resampled.push(s1 * (1.0 - frac as f32) + s2 * frac as f32);
            }
        }
        resampled
    } else {
        all_samples
    };

    let spec = hound::WavSpec {
        channels: 2,
        sample_rate: target_rate,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };
    let mut writer = hound::WavWriter::create(output_path, spec).map_err(|e| e.to_string())?;

    for s in final_samples {
        writer.write_sample((s * 32767.0) as i16).map_err(|e| e.to_string())?;
    }

    Ok(())
}

#[no_mangle]
pub extern "C" fn DownloadAudio(url: *const c_char, output_path: *const c_char, cb: Option<ProgressCallback>) -> *mut c_char {
    ABORT.store(false, Ordering::SeqCst);
    let result = std::panic::catch_unwind(|| -> Result<(), String> {
        if url.is_null() || output_path.is_null() {
            return Err("Error: Null arguments".to_string());
        }
        
        let url_raw = unsafe { CStr::from_ptr(url) }.to_string_lossy().to_string();
        let url_str = normalize_youtube_url(&url_raw);
        let out_str = unsafe { CStr::from_ptr(output_path) }.to_string_lossy().to_string();

        let path = Path::new(&out_str);
        if let Some(parent) = path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }

        let download_path = out_str.clone() + ".download";
        
        println!("Rust: Starting download via yt-dlp for {}", url_str);

        let mut child = Command::new(get_ytdlp_path())
            .arg("-f")
            .arg("ba/best")
            .arg("--extractor-args")
            .arg("youtube:player_client=ios,web,android")
            .arg("--no-playlist")
            .arg("-o")
            .arg(&download_path)
            .arg(&url_str)
            .arg("--newline")
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| format!("Failed to execute yt-dlp: {}", e))?;

        if let Some(stdout) = child.stdout.take() {
            let reader = BufReader::new(stdout);
            for line in reader.lines() {
                if ABORT.load(Ordering::Relaxed) {
                    let _ = child.kill();
                    return Err("Download aborted".to_string());
                }
                if let Ok(l) = line {
                    if l.contains("[download]") && l.contains('%') {
                        let parts: Vec<&str> = l.split_whitespace().collect();
                        for p in parts {
                            if p.contains('%') {
                                if let Ok(val) = p.replace('%', "").parse::<f64>() {
                                    if let Some(callback) = cb {
                                        if !ABORT.load(Ordering::Relaxed) {
                                            callback(val / 100.0 * 0.8);
                                        }
                                    }
                                }
                                break;
                            }
                        }
                    }
                }

            }
        }

        let status = child.wait().map_err(|e| format!("yt-dlp wait failed: {}", e))?;

        if !status.success() {
            return Err(format!("yt-dlp failed with exit code: {:?}", status.code()));
        }

        if ABORT.load(Ordering::Relaxed) {
            return Err("Download aborted".to_string());
        }

        let actual_download_path = if Path::new(&download_path).exists() {
            download_path.clone()
        } else {
            let mut found = None;
            for ext in &["m4a", "webm", "opus", "mp3"] {
                let p = format!("{}.{}", download_path, ext);
                if Path::new(&p).exists() {
                    found = Some(p);
                    break;
                }
            }
            found.ok_or_else(|| "yt-dlp finished but no output file was found".to_string())?
        };

        if let Some(callback) = cb {
            if !ABORT.load(Ordering::Relaxed) {
                callback(0.85);
            }
        }

        println!("Rust: Download complete, converting to WAV...");
        convert_to_wav(&actual_download_path, &out_str)?;
        
        if let Some(callback) = cb {
            if !ABORT.load(Ordering::Relaxed) {
                callback(1.0);
            }
        }

        let _ = std::fs::remove_file(actual_download_path);
        Ok(())
    });

    match result {
        Ok(Ok(_)) => std::ptr::null_mut(),
        Ok(Err(e)) => CString::new(e).unwrap().into_raw(),
        Err(_) => CString::new("Error: Panic in DownloadAudio").unwrap().into_raw(),
    }
}

struct Stemmer {
    session: Session,
}

static STEMMER: Lazy<Mutex<Option<Stemmer>>> = Lazy::new(|| Mutex::new(None));
static ORT_INITIALIZED: Lazy<Mutex<bool>> = Lazy::new(|| Mutex::new(false));

#[no_mangle]
pub extern "C" fn InitStemmer(model_path: *const c_char, lib_path: *const c_char) -> *mut c_char {
    // CRITICAL: The 'ort' crate MUST be pinned to 'api-19' in Cargo.toml to match 
    // libonnxruntime 1.19.2. Higher versions (e.g. api-24) cause null API pointers
    // and re-entrant deadlocks during error handling on macOS.
    let result = std::panic::catch_unwind(|| -> Result<(), String> {
        let model_path_str = unsafe { CStr::from_ptr(model_path) }.to_string_lossy().to_string();
        let lib_path_str = if !lib_path.is_null() {
            Some(unsafe { CStr::from_ptr(lib_path) }.to_string_lossy().to_string())
        } else {
            None
        };
        
        println!("Rust: InitStemmer entered. Model: {}", model_path_str);

        if !Path::new(&model_path_str).exists() {
            return Err(format!("Model file not found: {}", model_path_str));
        }

        let mut init_needed = false;
        {
            let init_guard = ORT_INITIALIZED.lock().unwrap();
            if !*init_guard {
                init_needed = true;
            }
        }

        if init_needed {
            println!("Rust: Setting ORT environment variables...");
            std::env::set_var("ORT_DISABLE_TELEMETRY", "1");

            #[cfg(target_os = "macos")]
            {
                if let Some(ref lp) = lib_path_str {
                    println!("Rust: macOS detected. Setting ORT_DYLIB_PATH to: {}", lp);
                    std::env::set_var("ORT_DYLIB_PATH", lp);
                }

                // Workaround for ort 2.0.0-rc.12 deadlock on macOS with load-dynamic:
                // When Session::builder() triggers G_ORT_API.get_or_init(setup_api), setup_api
                // tries G_ORT_LIB.get_or_init(...) which calls libloading::Library::new(path).
                // If that fails (or even during success), any ort::Error creation calls
                // Error::new_internal() → api() → G_ORT_API.get_or_init(setup_api), but
                // setup_api is already running → std::sync::Once deadlocks on itself.
                //
                // Fix: pre-initialize G_ORT_API via ort::set_api() BEFORE Session::builder().
                // We load the library ourselves with a plain dlopen, get OrtGetApiBase, build
                // the OrtApi vtable, and hand it to ort. We intentionally skip dlclose so the
                // library remains loaded for the lifetime of the ORT session (G_ORT_LIB stays
                // None, but Flutter's process keeps the library mapped anyway).
                let api_initialized = if let Some(ref lp) = lib_path_str {
                    println!("Rust: Pre-initializing ORT API via dlopen (macOS deadlock workaround)...");
                    let c_path = std::ffi::CString::new(lp.as_str()).unwrap();
                    unsafe {
                        let lib_handle = libc::dlopen(c_path.as_ptr(), libc::RTLD_LAZY);
                        if lib_handle.is_null() {
                            let err = libc::dlerror();
                            let msg = if err.is_null() { "(no error)".to_string() }
                                      else { std::ffi::CStr::from_ptr(err).to_string_lossy().into_owned() };
                            println!("Rust: Warning: dlopen failed: {}", msg);
                            false
                        } else {
                            let fn_ptr = libc::dlsym(
                                lib_handle,
                                b"OrtGetApiBase\0".as_ptr() as *const libc::c_char,
                            );
                            if fn_ptr.is_null() {
                                println!("Rust: Warning: OrtGetApiBase not found in library");
                                libc::dlclose(lib_handle);
                                false
                            } else {
                                type GetApiBaseFn = unsafe extern "C" fn() -> *const ort::sys::OrtApiBase;
                                let get_api_base: GetApiBaseFn = std::mem::transmute(fn_ptr);
                                let base = get_api_base();
                                if base.is_null() {
                                    println!("Rust: Warning: OrtGetApiBase() returned null");
                                    libc::dlclose(lib_handle);
                                    false
                                } else {
                                    let api_ptr = ((*base).GetApi)(ort::sys::ORT_API_VERSION);
                                    if api_ptr.is_null() {
                                        println!("Rust: Warning: GetApi({}) returned null", ort::sys::ORT_API_VERSION);
                                        libc::dlclose(lib_handle);
                                        false
                                    } else {
                                        ort::set_api((*api_ptr).clone());
                                        // Intentionally no dlclose: keep library loaded so ORT
                                        // API vtable function pointers remain valid.
                                        println!("Rust: ORT API pre-initialized via dlopen");
                                        true
                                    }
                                }
                            }
                        }
                    }
                } else {
                    false
                };

                if !api_initialized {
                    println!("Rust: Warning: ORT API pre-init failed; setup_api deadlock may occur");
                }
                let _ = ort::init().commit();
            }

            #[cfg(not(target_os = "macos"))]
            {
                if let Some(lp) = lib_path_str {
                    println!("Rust: Initializing ORT from path: {}", lp);
                    let _ = ort::init_from(&lp).map(|b| b.commit());
                } else {
                    let _ = ort::init().commit();
                }
            }

            let mut init_guard = ORT_INITIALIZED.lock().unwrap();
            *init_guard = true;
            println!("Rust: ORT initialization block finished");
        } else {
            println!("Rust: ORT already initialized");
        }

        println!("Rust: Creating session for model at {}...", model_path_str);
        // We use a separate thread for session creation to allow us to "detect" a hang
        // even if we can't easily kill it (since Session::builder is synchronous).
        let session = Session::builder()
            .map_err(|e| e.to_string())?
            .commit_from_file(&model_path_str)
            .map_err(|e| e.to_string())?;

        println!("Rust: Session created successfully");
        let mut guard = STEMMER.lock().unwrap();
        *guard = Some(Stemmer { session });
        Ok(())
    });

    match result {
        Ok(Ok(_)) => std::ptr::null_mut(),
        Ok(Err(e)) => {
            println!("Rust: InitStemmer failed: {}", e);
            CString::new(e).unwrap().into_raw()
        },
        Err(_) => {
            println!("Rust: InitStemmer panicked!");
            CString::new("Error: Panic in InitStemmer").unwrap().into_raw()
        }
    }
}

#[no_mangle]
pub extern "C" fn SplitAudio(
    input_path: *const c_char,
    output_dir: *const c_char,
    stem_names: *const c_char,
    cb: Option<ProgressCallback>,
) -> *mut c_char {
    ABORT.store(false, Ordering::SeqCst);
    let result = std::panic::catch_unwind(|| -> Result<(), String> {
        let input_path_str = unsafe { CStr::from_ptr(input_path) }.to_string_lossy().to_string();
        let output_dir_str = unsafe { CStr::from_ptr(output_dir) }.to_string_lossy().to_string();
        let stem_names_str = unsafe { CStr::from_ptr(stem_names) }.to_string_lossy().to_string();
        let stem_names_vec: Vec<&str> = stem_names_str.split(';').collect();

        println!("Rust: SplitAudio starting for {}", input_path_str);

        let mut guard = STEMMER.lock().unwrap();
        let stemmer = guard.as_mut().ok_or("Stemmer not initialized")?;

        let mut reader = hound::WavReader::open(&input_path_str).map_err(|e| e.to_string())?;
        let spec = reader.spec();
        let samples: Vec<f32> = reader.samples::<i16>().map(|s| s.unwrap() as f32 / 32767.0).collect();
        let num_channels = spec.channels as usize;
        let num_frames = samples.len() / num_channels;

        let chunk_size = 343980;
        let num_chunks = (num_frames + chunk_size - 1) / chunk_size;

        let mut output_stems: Vec<Vec<f32>> = vec![Vec::with_capacity(samples.len()); stem_names_vec.len()];

        for c in 0..num_chunks {
            if ABORT.load(Ordering::Relaxed) {
                return Err("Stemming aborted".to_string());
            }

            let start = c * chunk_size;
            let end = std::cmp::min(start + chunk_size, num_frames);
            let current_chunk_len = end - start;

            let mut input_tensor = Array3::<f32>::zeros((1, 2, chunk_size));
            for i in 0..current_chunk_len {
                for ch in 0..2 {
                    let sample_idx = (start + i) * num_channels + (if ch < num_channels { ch } else { 0 });
                    input_tensor[[0, ch, i]] = samples[sample_idx];
                }
            }

            let input_value = Value::from_array(input_tensor).map_err(|e| e.to_string())?;
            println!("Rust: [Chunk {}/{}] Running AI inference...", c + 1, num_chunks);
            let outputs = stemmer.session.run(ort::inputs![input_value]).map_err(|e| e.to_string())?;
            println!("Rust: [Chunk {}/{}] AI inference complete.", c + 1, num_chunks);
            
            let output_tensor = outputs[0].try_extract_tensor::<f32>().map_err(|e| e.to_string())?;
            let output_data = output_tensor.1;

            println!("Rust: [Chunk {}/{}] Processing output data...", c + 1, num_chunks);
            for s in 0..stem_names_vec.len() {
                for i in 0..current_chunk_len {
                    for ch in 0..2 {
                        let idx = s * 2 * chunk_size + ch * chunk_size + i;
                        output_stems[s].push(output_data[idx]);
                    }
                }
            }

            if let Some(callback) = cb {
                if !ABORT.load(Ordering::Relaxed) {
                    println!("Rust: [Chunk {}/{}] Invoking progress callback...", c + 1, num_chunks);
                    callback(c as f64 / num_chunks as f64);
                }
            }
        }

        let _ = std::fs::create_dir_all(&output_dir_str);
        for (idx, name) in stem_names_vec.iter().enumerate() {
            let path = Path::new(&output_dir_str).join(format!("{}.wav", name));
            let mut writer = hound::WavWriter::create(path, spec).map_err(|e| e.to_string())?;
            for s in &output_stems[idx] {
                writer.write_sample((s * 32767.0) as i16).map_err(|e| e.to_string())?;
            }
        }

        if let Some(callback) = cb {
            callback(1.0);
        }

        Ok(())
    });

    match result {
        Ok(Ok(_)) => std::ptr::null_mut(),
        Ok(Err(e)) => CString::new(e).unwrap().into_raw(),
        Err(_) => CString::new("Error: Panic in SplitAudio").unwrap().into_raw(),
    }
}

#[no_mangle]
pub extern "C" fn MixStems(
    paths: *const c_char,
    weights: *const f64,
    weights_len: usize,
    output_path: *const c_char,
) -> *mut c_char {
    let result = std::panic::catch_unwind(|| -> Result<(), String> {
        let paths_str = unsafe { CStr::from_ptr(paths) }.to_string_lossy();
        let paths_vec: Vec<&str> = paths_str.split(';').collect();
        let weights_slice = unsafe { std::slice::from_raw_parts(weights, weights_len) };
        let output_path_str = unsafe { CStr::from_ptr(output_path) }.to_string_lossy();

        if paths_vec.is_empty() {
            return Err("No stems to mix".to_string());
        }

        let mut mixed_samples: Vec<f32> = Vec::new();
        let mut final_spec = None;

        for (idx, path) in paths_vec.iter().enumerate() {
            let mut reader = hound::WavReader::open(path).map_err(|e| e.to_string())?;
            let spec = reader.spec();
            let weight = weights_slice[idx] as f32;

            if final_spec.is_none() {
                final_spec = Some(spec);
            }

            let samples: Vec<f32> = reader.samples::<i16>().map(|s| s.unwrap() as f32 / 32767.0).collect();
            
            if mixed_samples.is_empty() {
                mixed_samples = samples.iter().map(|s| s * weight).collect();
            } else {
                for (i, s) in samples.iter().enumerate() {
                    if i < mixed_samples.len() {
                        mixed_samples[i] += s * weight;
                    }
                }
            }
        }

        if let Some(spec) = final_spec {
            let mut writer = hound::WavWriter::create(&*output_path_str, spec).map_err(|e| e.to_string())?;
            for s in mixed_samples {
                let clipped = s.clamp(-1.0, 1.0);
                writer.write_sample((clipped * 32767.0) as i16).map_err(|e| e.to_string())?;
            }
        }

        Ok(())
    });

    match result {
        Ok(Ok(_)) => std::ptr::null_mut(),
        Ok(Err(e)) => CString::new(e).unwrap().into_raw(),
        Err(_) => CString::new("Error: Panic in MixStems").unwrap().into_raw(),
    }
}

#[no_mangle]
pub extern "C" fn CreateZip(paths: *const c_char, output_path: *const c_char) -> *mut c_char {
    let result = std::panic::catch_unwind(|| -> Result<(), String> {
        let paths_str = unsafe { CStr::from_ptr(paths) }.to_string_lossy();
        let paths_vec: Vec<&str> = paths_str.split(';').collect();
        let output_path_str = unsafe { CStr::from_ptr(output_path) }.to_string_lossy();

        let file = File::create(&*output_path_str).map_err(|e| e.to_string())?;
        let mut zip = zip::ZipWriter::new(file);
        let options = zip::write::SimpleFileOptions::default()
            .compression_method(zip::CompressionMethod::Deflated);

        for path in paths_vec {
            let p = Path::new(path);
            let name = p.file_name().ok_or("Invalid filename")?.to_string_lossy();
            
            zip.start_file(name, options).map_err(|e| e.to_string())?;
            let mut f = File::open(path).map_err(|e| e.to_string())?;
            let mut buffer = Vec::new();
            f.read_to_end(&mut buffer).map_err(|e| e.to_string())?;
            zip.write_all(&buffer).map_err(|e| e.to_string())?;
        }

        zip.finish().map_err(|e| e.to_string())?;
        Ok(())
    });

    match result {
        Ok(Ok(_)) => std::ptr::null_mut(),
        Ok(Err(e)) => CString::new(e).unwrap().into_raw(),
        Err(_) => CString::new("Error: Panic in CreateZip").unwrap().into_raw(),
    }
}

#[no_mangle]
pub extern "C" fn CreateMp3Zip(paths: *const c_char, output_path: *const c_char) -> *mut c_char {
    CreateZip(paths, output_path)
}
