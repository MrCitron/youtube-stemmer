use std::path::Path;
use hound;

#[allow(dead_code)]
pub fn generate_click(path: &Path) -> Result<(), String> {
    let spec = hound::WavSpec {
        channels: 1,
        sample_rate: 44100,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };

    let mut writer = hound::WavWriter::create(path, spec).map_err(|e| e.to_string())?;
    
    // 100ms click + 400ms silence = 500ms total
    let click_duration_ms = 100;
    let total_duration_ms = 500;
    
    let click_samples = (44100 * click_duration_ms) / 1000;
    let total_samples = (44100 * total_duration_ms) / 1000;
    
    let frequency = 2000.0;

    for t in 0..total_samples {
        if t < click_samples {
            let sample = (t as f32 * frequency * 2.0 * std::f32::consts::PI / 44100.0).sin();
            let amplitude = (i16::MAX as f32) * 0.9;
            
            let envelope = if t < 50 {
                t as f32 / 50.0
            } else if t > click_samples - 500 {
                ((click_samples - t) as f32 / 500.0).powf(2.0)
            } else {
                1.0
            };
            writer.write_sample((sample * amplitude * envelope) as i16).map_err(|e| e.to_string())?;
        } else {
            // Silence
            writer.write_sample(0i16).map_err(|e| e.to_string())?;
        }
    }
    writer.finalize().map_err(|e| e.to_string())?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn test_generate_click() {
        let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        path.pop();
        path.push("frontend/assets/click.wav");
        let _ = std::fs::create_dir_all(path.parent().unwrap());
        let result = generate_click(&path);
        assert!(result.is_ok());
    }
}
