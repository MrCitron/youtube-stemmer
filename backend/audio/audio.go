package audio

import (
	"io"
	"os"

	"github.com/braheezy/shine-mp3/pkg/mp3"
	"github.com/go-audio/wav"
)

// EncodeWavToMp3 reads a WAV file and encodes it to an MP3 writer.
func EncodeWavToMp3(wavPath string, mp3Writer io.Writer) error {
	f, err := os.Open(wavPath)
	if err != nil {
		return err
	}
	defer f.Close()

	decoder := wav.NewDecoder(f)
	if !decoder.IsValidFile() {
		return os.ErrInvalid
	}

	buf, err := decoder.FullPCMBuffer()
	if err != nil {
		return err
	}

	// Convert to int16
	int16Data := make([]int16, len(buf.Data))
	for i, val := range buf.Data {
		int16Data[i] = int16(val)
	}

	enc := mp3.NewEncoder(int(buf.Format.SampleRate), buf.Format.NumChannels)
	
	// Set bitrate to 192 kbps (default is 128)
	enc.Mpeg.Bitrate = 192
	enc.Mpeg.BitrateIndex = 11 // Index for 192kbps in MPEG-I
	
	// Recalculate dependent fields
	avgSlotsPerFrame := (float64(enc.Mpeg.GranulesPerFrame) * 576 / (float64(enc.Wave.SampleRate))) * (float64(enc.Mpeg.Bitrate) * 1000 / float64(enc.Mpeg.BitsPerSlot))
	enc.Mpeg.WholeSlotsPerFrame = int64(avgSlotsPerFrame)
	enc.Mpeg.FracSlotsPerFrame = avgSlotsPerFrame - float64(enc.Mpeg.WholeSlotsPerFrame)
	enc.Mpeg.Slot_lag = -enc.Mpeg.FracSlotsPerFrame

	return enc.Write(mp3Writer, int16Data)
}
