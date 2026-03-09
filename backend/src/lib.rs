use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_double};
use std::path::Path;
use std::fs::File;
use ort::session::Session;
use ort::value::Value;
use ndarray::Array3;
use once_cell::sync::Lazy;
use std::sync::Mutex;
use symphonia::core::audio::Signal;
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

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

#[no_mangle]
pub extern "C" fn GetMetadata(url: *const c_char) -> *mut c_char {
    if url.is_null() {
        return CString::new("Error: Null URL").unwrap().into_raw();
    }
    let url_raw = unsafe { CStr::from_ptr(url) }.to_string_lossy();
    let url_str = normalize_youtube_url(&url_raw);
    
    let output = std::process::Command::new("yt-dlp")
        .arg("--print")
        .arg("title")
        .arg("--print")
        .arg("uploader")
        .arg("--no-playlist")
        .arg(&url_str)
        .output();

    let result = match output {
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
    };

    CString::new(result).unwrap().into_raw()
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

    let spec = hound::WavSpec {
        channels: 2,
        sample_rate: 44100,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };
    let mut writer = hound::WavWriter::create(output_path, spec).map_err(|e| e.to_string())?;

    while let Ok(packet) = format.next_packet() {
        if packet.track_id() != track_id {
            continue;
        }

        match decoder.decode(&packet) {
            Ok(decoded) => {
                let num_frames = decoded.frames();
                match decoded {
                    symphonia::core::audio::AudioBufferRef::F32(ref buf) => {
                        for i in 0..num_frames {
                            for ch in 0..2 {
                                let p = if ch < buf.planes().planes().len() { ch } else { 0 };
                                writer.write_sample((buf.chan(p)[i] * 32767.0) as i16).map_err(|e| e.to_string())?;
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

    Ok(())
}

#[no_mangle]
pub extern "C" fn DownloadAudio(url: *const c_char, output_path: *const c_char, cb: Option<ProgressCallback>) -> *mut c_char {
    if url.is_null() || output_path.is_null() {
        return CString::new("Error: Null arguments").unwrap().into_raw();
    }
    
    let url_raw = unsafe { CStr::from_ptr(url) }.to_string_lossy().to_string();
    let url_str = normalize_youtube_url(&url_raw);
    let out_str = unsafe { CStr::from_ptr(output_path) }.to_string_lossy().to_string();

    let result: Result<(), String> = (|| {
        let path = Path::new(&out_str);
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
        }

        let download_path = out_str.clone() + ".download";
        
        println!("Rust: Starting download via yt-dlp for {}", url_str);
        
        let status = std::process::Command::new("yt-dlp")
            .arg("-f")
            .arg("ba/best")
            .arg("--extractor-args")
            .arg("youtube:player_client=ios,web,android")
            .arg("--no-playlist")
            .arg("-o")
            .arg(&download_path)
            .arg(&url_str)
            .status()
            .map_err(|e| format!("Failed to execute yt-dlp: {}", e))?;

        if !status.success() {
            return Err(format!("yt-dlp failed with exit code: {:?}", status.code()));
        }

        // Check if the file was actually created (yt-dlp sometimes appends extension)
        println!("Rust: Checking for download file at {}", download_path);
        
        if let Ok(entries) = std::fs::read_dir(".") {
            for entry in entries {
                if let Ok(entry) = entry {
                    println!("Rust: Local file found: {:?}", entry.file_name());
                }
            }
        }

        let actual_download_path = if Path::new(&download_path).exists() {
            download_path.clone()
        } else {
            // Try common extensions
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

        println!("Rust: Download complete, converting to WAV...");
        if let Some(callback) = cb {
            callback(0.5);
        }

        convert_to_wav(&actual_download_path, &out_str)?;
        
        if let Some(callback) = cb {
            callback(1.0);
        }

        let _ = std::fs::remove_file(actual_download_path);
        Ok(())
    })();

    match result {
        Ok(_) => std::ptr::null_mut(),
        Err(e) => CString::new(format!("Error: {}", e)).unwrap().into_raw(),
    }
}

struct Stemmer {
    session: Session,
}

static STEMMER: Lazy<Mutex<Option<Stemmer>>> = Lazy::new(|| Mutex::new(None));

#[no_mangle]
pub extern "C" fn InitStemmer(model_path: *const c_char, lib_path: *const c_char) -> *mut c_char {
    let model_path_str = unsafe { CStr::from_ptr(model_path) }.to_string_lossy();
    let lib_path_str = if !lib_path.is_null() {
        Some(unsafe { CStr::from_ptr(lib_path) }.to_string_lossy())
    } else {
        None
    };
    
    let result: Result<(), String> = (|| {
        if let Some(lp) = lib_path_str {
            ort::init_from(&*lp).map_err(|e| e.to_string())?;
        }

        let session = Session::builder()
            .map_err(|e| e.to_string())?
            .commit_from_file(&*model_path_str)
            .map_err(|e| e.to_string())?;

        let mut guard = STEMMER.lock().unwrap();
        *guard = Some(Stemmer { session });
        Ok(())
    })();

    match result {
        Ok(_) => std::ptr::null_mut(),
        Err(e) => CString::new(format!("Error: {}", e)).unwrap().into_raw(),
    }
}

#[no_mangle]
pub extern "C" fn SplitAudio(
    input_path: *const c_char,
    output_dir: *const c_char,
    stem_names: *const c_char,
    cb: Option<ProgressCallback>,
) -> *mut c_char {
    let input_path_str = unsafe { CStr::from_ptr(input_path) }.to_string_lossy();
    let output_dir_str = unsafe { CStr::from_ptr(output_dir) }.to_string_lossy();
    let stem_names_str = unsafe { CStr::from_ptr(stem_names) }.to_string_lossy();
    let stem_names_vec: Vec<&str> = stem_names_str.split(';').collect();

    let result: Result<(), String> = (|| {
        let mut guard = STEMMER.lock().unwrap();
        let stemmer = guard.as_mut().ok_or("Stemmer not initialized")?;

        let mut reader = hound::WavReader::open(&*input_path_str).map_err(|e| e.to_string())?;
        let spec = reader.spec();
        let samples: Vec<f32> = reader.samples::<i16>().map(|s| s.unwrap() as f32 / 32767.0).collect();
        let num_channels = spec.channels as usize;
        let num_frames = samples.len() / num_channels;

        let chunk_size = 343980; // Match export dummy input size
        let num_chunks = (num_frames + chunk_size - 1) / chunk_size;

        let mut output_stems: Vec<Vec<f32>> = vec![Vec::with_capacity(samples.len()); stem_names_vec.len()];

        for c in 0..num_chunks {
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

            println!("Rust: Running inference for chunk {}/{} (len={}, padded to {})", c+1, num_chunks, current_chunk_len, chunk_size);
            let input_value = Value::from_array(input_tensor).map_err(|e| e.to_string())?;
            let outputs = stemmer.session.run(ort::inputs![input_value]).map_err(|e| e.to_string())?;
            
            let output_tensor = outputs[0].try_extract_tensor::<f32>().map_err(|e| e.to_string())?;
            let output_data = output_tensor.1;

            for s in 0..stem_names_vec.len() {
                for i in 0..current_chunk_len {
                    for ch in 0..2 {
                        // shape is [1, Stems, 2, Time]
                        // Note: chunk_size here is fixed at 343980
                        let idx = s * 2 * chunk_size + ch * chunk_size + i;
                        output_stems[s].push(output_data[idx]);
                    }
                }
            }

            if let Some(callback) = cb {
                callback(c as f64 / num_chunks as f64);
            }
        }

        std::fs::create_dir_all(&*output_dir_str).map_err(|e| e.to_string())?;
        for (idx, name) in stem_names_vec.iter().enumerate() {
            let path = Path::new(&*output_dir_str).join(format!("{}.wav", name));
            let mut writer = hound::WavWriter::create(path, spec).map_err(|e| e.to_string())?;
            for s in &output_stems[idx] {
                writer.write_sample((s * 32767.0) as i16).map_err(|e| e.to_string())?;
            }
        }

        if let Some(callback) = cb {
            callback(1.0);
        }

        Ok(())
    })();

    match result {
        Ok(_) => std::ptr::null_mut(),
        Err(e) => CString::new(format!("Error: {}", e)).unwrap().into_raw(),
    }
}

#[no_mangle]
pub extern "C" fn MixStems(
    paths: *const c_char,
    weights: *const f64,
    weights_len: usize,
    output_path: *const c_char,
) -> *mut c_char {
    let paths_str = unsafe { CStr::from_ptr(paths) }.to_string_lossy();
    let paths_vec: Vec<&str> = paths_str.split(';').collect();
    let weights_slice = unsafe { std::slice::from_raw_parts(weights, weights_len) };
    let output_path_str = unsafe { CStr::from_ptr(output_path) }.to_string_lossy();

    let result: Result<(), String> = (|| {
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
    })();

    match result {
        Ok(_) => std::ptr::null_mut(),
        Err(e) => CString::new(format!("Error: {}", e)).unwrap().into_raw(),
    }
}

#[no_mangle]
pub extern "C" fn CreateZip(paths: *const c_char, output_path: *const c_char) -> *mut c_char {
    let paths_str = unsafe { CStr::from_ptr(paths) }.to_string_lossy();
    let paths_vec: Vec<&str> = paths_str.split(';').collect();
    let output_path_str = unsafe { CStr::from_ptr(output_path) }.to_string_lossy();

    let result: Result<(), String> = (|| {
        let file = File::create(&*output_path_str).map_err(|e| e.to_string())?;
        let mut zip = zip::ZipWriter::new(file);
        let options = zip::write::SimpleFileOptions::default()
            .compression_method(zip::CompressionMethod::Deflated);

        for path in paths_vec {
            let p = Path::new(path);
            let name = p.file_name().ok_or("Invalid filename")?.to_string_lossy();
            
            zip.start_file(name, options).map_err(|e| e.to_string())?;
            let mut f = File::open(path).map_err(|e| e.to_string())?;
            std::io::copy(&mut f, &mut zip).map_err(|e| e.to_string())?;
        }

        zip.finish().map_err(|e| e.to_string())?;
        Ok(())
    })();

    match result {
        Ok(_) => std::ptr::null_mut(),
        Err(e) => CString::new(format!("Error: {}", e)).unwrap().into_raw(),
    }
}

#[no_mangle]
pub extern "C" fn CreateMp3Zip(paths: *const c_char, output_path: *const c_char) -> *mut c_char {
    CreateZip(paths, output_path)
}
