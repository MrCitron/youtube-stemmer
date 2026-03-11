use std::path::Path;
use std::fs::File;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::probe::Hint;
use symphonia::core::formats::FormatOptions;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::audio::Signal;

pub fn estimate_bpm(path: &Path) -> Result<f64, String> {
    let src = File::open(path).map_err(|e| e.to_string())?;
    let mss = MediaSourceStream::new(Box::new(src), Default::default());
    
    let mut hint = Hint::new();
    if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
        hint.with_extension(ext);
    }

    let probed = symphonia::default::get_probe()
        .format(&hint, mss, &FormatOptions::default(), &MetadataOptions::default())
        .map_err(|e| e.to_string())?;

    let mut format = probed.format;
    let track = format.tracks().iter()
        .find(|t| t.codec_params.codec != symphonia::core::codecs::CODEC_TYPE_NULL)
        .ok_or("No supported audio track found")?;

    let track_id = track.id;
    let mut decoder = symphonia::default::get_codecs()
        .make(&track.codec_params, &symphonia::core::codecs::DecoderOptions::default())
        .map_err(|e| e.to_string())?;

    let sample_rate = track.codec_params.sample_rate.ok_or("Unknown sample rate")? as f64;
    
    // Target ~10 seconds of audio
    let max_samples = (sample_rate * 10.0) as usize;
    let mut all_samples: Vec<f32> = Vec::with_capacity(max_samples);

    while all_samples.len() < max_samples {
        let packet = match format.next_packet() {
            Ok(p) => p,
            Err(_) => break,
        };

        if packet.track_id() != track_id {
            continue;
        }

        let decoded = decoder.decode(&packet).map_err(|e| e.to_string())?;
        let mut audio_buf = decoded.make_equivalent::<f32>();
        decoded.convert(&mut audio_buf);

        let planes = audio_buf.planes();
        let num_planes = planes.planes().len();
        let num_frames = audio_buf.frames();

        for i in 0..num_frames {
            let mut sum = 0.0;
            for p in 0..num_planes {
                sum += planes.planes()[p][i];
            }
            all_samples.push(sum / num_planes as f32);
            if all_samples.len() >= max_samples {
                break;
            }
        }
    }

    if all_samples.is_empty() {
        return Err("No samples decoded".to_string());
    }

    // 1. Simple Energy Envelope
    // Downsample to ~100Hz for envelope analysis
    let window_size = (sample_rate / 100.0) as usize;
    if window_size == 0 { return Err("Sample rate too low".to_string()); }
    
    let mut envelope: Vec<f32> = Vec::new();
    for chunk in all_samples.chunks(window_size) {
        let energy: f32 = chunk.iter().map(|&s| s * s).sum::<f32>() / chunk.len() as f32;
        envelope.push(energy);
    }

    // 2. Differentiate to get onsets
    let mut onsets: Vec<f32> = Vec::new();
    for i in 1..envelope.len() {
        let diff = (envelope[i] - envelope[i-1]).max(0.0);
        onsets.push(diff);
    }

    // 3. Autocorrelation
    let mut max_corr = 0.0;
    let mut best_lag = 0;

    // Range for 60 to 200 BPM
    // 60 BPM = 1 beat per second = 100 samples at 100Hz
    // 200 BPM = 3.33 beats per second = 30 samples at 100Hz
    let min_lag = (100.0 * 60.0 / 200.0) as usize; // ~30
    let max_lag = (100.0 * 60.0 / 60.0) as usize;  // ~100

    for lag in min_lag..=max_lag {
        if onsets.len() <= lag { continue; }
        let mut corr = 0.0;
        let mut count = 0;
        for i in 0..(onsets.len() - lag) {
            corr += onsets[i] * onsets[i+lag];
            count += 1;
        }
        if count > 0 {
            corr /= count as f32;
            if corr > max_corr {
                max_corr = corr;
                best_lag = lag;
            }
        }
    }

    if best_lag == 0 {
        return Ok(120.0); // Fallback
    }

    let bpm = (60.0 * 100.0) / best_lag as f64;
    Ok(bpm)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn test_estimate_bpm() {
        let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        path.pop(); // Go to project root
        path.push("backend_go_legacy/test_input.wav");
        
        let result = estimate_bpm(&path);
        assert!(result.is_ok(), "BPM estimation should return Ok, but got {:?}", result);
        let bpm = result.unwrap();
        println!("Estimated BPM: {}", bpm);
        assert!(bpm > 40.0 && bpm < 250.0, "BPM should be in reasonable range, got {}", bpm);
    }
}
