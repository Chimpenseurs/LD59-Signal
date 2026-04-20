import sys
import librosa
import soundfile as sf

print(sf.available_formats())

target_tempo = 120  # change this

path = sys.argv[1]
y, sr = librosa.load(path, mono=True, res_type='kaiser_fast')
tempo = librosa.beat.beat_track(y=y, sr=sr)[0]

# tempo, _ = librosa.beat.beat_track(y=librosa.to_mono(y), sr=sr)
tempo = float(librosa.beat.beat_track(y=y, sr=sr)[0].item())
ratio = target_tempo / float(tempo)
# ratio = target_tempo / tempo

ratio = float(target_tempo / tempo)

if y.ndim == 1:
    y_stretched = librosa.effects.time_stretch(y, rate=ratio)
else:
    y_stretched = librosa.effects.time_stretch(y, rate=ratio)

sf.write("out_" + path, y_stretched.T if y_stretched.ndim > 1 else y_stretched, sr)
print(f"Tempo: {tempo:.1f} -> {target_tempo}, ratio: {ratio:.3f}")

