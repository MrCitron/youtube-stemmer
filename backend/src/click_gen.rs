use std::path::Path;
use hound;

/// Regular beat click: high-pitched short transient (beats 2-4)
pub fn generate_click(path: &Path) -> Result<(), String> {
    generate_click_wav(path, 4500.0, 200.0, 1000.0, 40.0, 0.65, 0.35)
}

/// Downbeat click: lower-pitched, slightly longer (beat 1 of each measure)
pub fn generate_click_down(path: &Path) -> Result<(), String> {
    generate_click_wav(path, 2800.0, 140.0, 700.0, 28.0, 0.55, 0.45)
}

/// Generate a percussive click WAV.
/// Layered model: high-frequency "crack" + lower-frequency "body", both exponentially decayed.
///
/// - crack_freq / crack_decay: frequency (Hz) and decay rate for the transient attack
/// - body_freq / body_decay:   frequency (Hz) and decay rate for the resonant body
/// - crack_mix / body_mix:     mixing weights (should sum ≤ 1.0)
fn generate_click_wav(
    path: &Path,
    crack_freq: f64,
    crack_decay: f64,
    body_freq: f64,
    body_decay: f64,
    crack_mix: f32,
    body_mix: f32,
) -> Result<(), String> {
    let spec = hound::WavSpec {
        channels: 1,
        sample_rate: 44100,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };

    let mut writer = hound::WavWriter::create(path, spec).map_err(|e| e.to_string())?;

    // 30 ms of sound + 20 ms of silence = 50 ms total
    let sound_samples: usize = (44100 * 30) / 1000;
    let total_samples: usize = (44100 * 50) / 1000;

    use std::f64::consts::PI;
    let amplitude = i16::MAX as f64 * 0.92;

    for t in 0..total_samples {
        let sample = if t < sound_samples {
            let tf = t as f64;
            let crack = (tf * crack_freq * 2.0 * PI / 44100.0).sin()
                * (-crack_decay * tf / 44100.0).exp()
                * crack_mix as f64;
            let body = (tf * body_freq * 2.0 * PI / 44100.0).sin()
                * (-body_decay * tf / 44100.0).exp()
                * body_mix as f64;
            ((crack + body) * amplitude) as i16
        } else {
            0i16
        };
        writer.write_sample(sample).map_err(|e| e.to_string())?;
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
        assert!(generate_click(&path).is_ok());
    }

    #[test]
    fn test_generate_click_down() {
        let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        path.pop();
        path.push("frontend/assets/click_down.wav");
        let _ = std::fs::create_dir_all(path.parent().unwrap());
        assert!(generate_click_down(&path).is_ok());
    }
}
