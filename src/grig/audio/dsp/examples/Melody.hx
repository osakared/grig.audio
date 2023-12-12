import haxe.io.*;
using Lambda;
using Math;

import format.wav.*;

using dsp.FFT;
using dsp.Signal;
import dsp.Complex;


@:pure @:notNull
typedef Note = {
	final pitch : Float;
	final amplitude : Float;
}

class Melody {
	static function main() {
		// read samples from audio data
		final fileIn = "res/track.wav";
		final resource = haxe.Resource.getBytes(fileIn);
		if (resource == null) throw 'Failed to open resource: "${fileIn}"';
		final input = new BytesInput(resource);
		final audio = readWave(input);

		// estimate melody from time signal
		final samples = audio.samples;
		final fs = audio.rate; // sampling rate
		final melody = estimateMelody(samples, fs);

		// write out synthesized audio
		final synth = [
			for (n => note in melody.notes)
				for (t in n * melody.span ... (n + 1) * melody.span)
					note.amplitude * Math.cos(2 * Math.PI * note.pitch * t / fs)
		].slice(0, samples.length);
		final fileOut = sys.io.File.write("res/re.wav", true);
		writeWave(fileOut, synth, fs);
		fileOut.close();
	}

	static function estimateMelody(samples:Array<Float>, fs:Float) : {notes:Array<Note>, span:Int} {
		// Short-Time Fourier Transform (STFT) parameters
		final fftN = 4096;
		final overlap = 0.5;
		final hop = Std.int(fftN * (1 - overlap));

		// window function to compensate for overlapping
		final a0 = 0.50; // => Hann(ing) window
		final window = (n:Int) -> a0 - (1 - a0) * Math.cos(2 * Math.PI * n / fftN);

		// helpers
		final binSizeHz = fs / fftN;
		final indexToFreq = (k:Int) -> 1.0 * k * binSizeHz; // we need the `1.0` to avoid overflows
		final indexToTime = (n:Int) -> n / fs;

		// "melodic" band-pass filter
		final minFreq = 32.70;
		final maxFreq = 4186.01;
		final melodicBandPass = function(k:Int, s:Float) {
			final f = indexToFreq(k);
			return f > minFreq - binSizeHz && f < maxFreq + binSizeHz ? s : 0.0;
		};

		// computes an STFT frame, starting at the given index within input samples
		final stft = function(c:Int) {
			return [                              // take a chunk (zero-pad if needed)
				for (n in 0...fftN) c + n < samples.length ? samples[c + n] : 0.0
			].mapi((n, x) -> x * window(n))       // apply the window function
			 .rfft()                              // and compute positive spectrum
			 .map(z -> z.scale(1 / fs).magnitude) // with sampling correction
			 .mapi(melodicBandPass);              // and BP filter
		};

		// run through samples and estimate melody F0
		var melody = new Array<Note>();
		var c = 0;
		while (c < samples.length) {
			final freqs = stft(c);

			// when piped to a CSV file, this can be printed as a spectrogram
			for (k => s in freqs) {
				haxe.Log.trace('${indexToTime(c)};${indexToFreq(k)};${s}', null);
			}
			haxe.Log.trace('', null);

			final peaks = freqs.findPeaks();
			final pi = peaks[peaks.map(i -> freqs[i]).maxi()];

			melody.push({ pitch: indexToFreq(pi), amplitude: freqs[pi] });
			c += hop;
		}

		return { notes: melody, span: hop };
	}

	static function readWave(input:Input) : {samples:Array<Float>, rate:Float} {
		input.bigEndian = false;
		final reader = new format.wav.Reader(input);
		final audio = reader.read();

		// check if what we got is uncompressed mono-channel 16 bits/sample audio
		var fs : Float = audio.header.samplingRate;
		var bytes = switch (audio.header) {
			case { format: WF_PCM, channels: 1, bitsPerSample: 16 }: audio.data;
			case _: throw 'Invalid audio format: ${audio.header}';
		}

		// extract normalized samples from time signal
		final normalizeS16 = (x:Int) -> x / Math.pow(2,15) - 1.0;
		final samples = [
			for (i in 0...Std.int(bytes.length / 2))
				normalizeS16(bytes.getUInt16(2 * i))
		];

		return { samples: samples, rate: fs };
	}

	static function writeWave(output:Output, samples:Array<Float>, rate:Float) : Void {
		final bytes = Bytes.alloc(samples.length * 2);
		for (i in 0...samples.length)
			bytes.setUInt16(2 * i, Std.int(Math.pow(2,15) * (samples[i] + 1)));

		final samplingRate = Std.int(rate);

		output.bigEndian = false;
		final writer = new format.wav.Writer(output);
		writer.write({
			header: {
				format: WF_PCM,
				channels: 1,
				bitsPerSample: 16,
				blockAlign: 2,
				samplingRate: samplingRate,
				byteRate: samplingRate * 2,
			},
			data: bytes,
			cuePoints: null
		});
	}
}
