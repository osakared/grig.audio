import haxe.io.*;
using Lambda;

import format.wav.*;

import dsp.FFT;


class Main {
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

	static function extractMelody(samples:Array<Float>, fs:Float) {
		// Short-Time Fourier Transform (STFT) parameters
		final fftN = 2048;
		final halfN = Std.int(fftN / 2);
		final overlap = 0.5;
		final hop = Std.int(fftN * (1 - overlap));

		// window function to compensate for overlapping
		final a0 = 0.50; // => Hann(ing) window
		final window = (n:Int) -> a0 - (1 - a0) * Math.cos(2 * Math.PI * n / fftN);

		// helpers, note that spectrum indexes suppose non-negative frequencies
		final binSize = fs / fftN;
		final indexToFreq = (k:Int) -> 1.0 * k * binSize; // we need the `1.0` to avoid overflows

		// "melodic" band-pass filter
		final minFreq = 32.70;
		final maxFreq = 4186.01;
		final melodicBandPass = function(k:Int, s:Float) {
			final freq = indexToFreq(k);
			final filter = freq > minFreq - binSize && freq < maxFreq + binSize ? 1 : 0;
			return s * filter;
		};

		var c = 0; // index where each chunk begins
		while (c < samples.length) {
			// take a chunk (zero-padded if needed) and apply the window
			final chunk = [
				for (n in 0...fftN)
					(c + n < samples.length ? samples[c + n] : 0.0) * window(n)
			];

			// compute positive spectrum with sampling correction and BP filter
			final freqs = FFT.rfft(chunk)
			                 .map(z -> z.scale(1 / fs).magnitude)
			                 .mapi(melodicBandPass);

			// find spectral peaks and their instantaneous frequencies
			for (k => s in freqs) {
				final time = c / fs;
				final freq = indexToFreq(k);
				final power = s * s;
				haxe.Log.trace('${time};${freq};${power}', null);
			}
			haxe.Log.trace("", null);

			// move to next (overlapping) chunk
			c += hop;
		}
	}

	static function main() {
		// read samples from audio data
		final fileIn = "res/track.wav";
		final resource = haxe.Resource.getBytes(fileIn);
		if (resource == null) throw 'Failed to open resource: "${fileIn}"';
		final input = new BytesInput(resource);
		final audio = readWave(input);

		// process time signal
		final samples = audio.samples;
		final fs = audio.rate; // sampling rate
		extractMelody(samples, fs);

		// write processed audio
		final fileOut = sys.io.File.write("res/re.wav", true);
		writeWave(fileOut, samples, fs);
		fileOut.close();
	}
}
