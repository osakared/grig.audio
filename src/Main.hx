import haxe.io.*;
using Lambda;
using Math;

import format.wav.*;

using dsp.FFT;
using dsp.Signal;
import dsp.Complex;


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

		// helpers, @NOTE: spectrum indexes suppose non-negative frequencies
		final binSizeHz = fs / fftN;
		final indexToFreq = (k:Int) -> 1.0 * k * binSizeHz; // we need the `1.0` to avoid overflows
		final indexToTime = (n:Int) -> n / fs;
		final highestPeak = function(x:Array<Int>, y:Array<Float>) {
			return x.fold((p, m) -> y[p] > y[m] ? p : m, x[0]);
		};

		// "melodic" band-pass filter
		final minFreq = 32.70;
		final maxFreq = 4186.01;
		final melodicBandPass = function(k:Int, s:Complex) {
			final f = indexToFreq(k);
			return f > minFreq - binSizeHz && f < maxFreq + binSizeHz ? s : Complex.zero;
		};

		// logarithmic unit for pitches
		final hzToCents = (f:Float) -> 1200 * Math.log(f / minFreq) / Math.log(2);
		final hzToCentsBin = (f:Float) -> Math.floor(hzToCents(f) / 10 + 1);
		final centsBinToHz = (b:Int) -> minFreq * Math.pow(2, (b - 1.0) * 10 / 1200);

		// computes an STFT frame, starting at the given index within input samples
		final stft = function(c:Int) : Array<Complex> {
			return [                              // take a chunk (zero-pad if needed)
				for (n in 0...fftN) c + n < samples.length ? samples[c + n] : 0.0
			].mapi((n, x) -> x * window(n))       // apply the window function
			 .rfft()                              // and compute positive spectrum
			 .map(z -> z.scale(1 / fs))           // with sampling correction
			 .mapi(melodicBandPass);              // and BP filter
		};

		var previous;
		var current = stft(0);
		var c = 0;
		do {
			// move to next chunk, compute its STFT and update spectral buffer
			previous = current;
			c += hop;
			current = stft(c);
			// for (k => s in current.map(z -> z.magnitude)) {
			// 	final time = indexToTime(c);
			// 	final freq = indexToFreq(k);
			// 	final power = s * s;
			// 	haxe.Log.trace('${time};${freq};${power}', null);
			// }
			// haxe.Log.trace("", null);

			// extract spectral peaks and their instantaneous frequencies
			final mags = current.map(z -> z.magnitude);
			final peaks = mags.findPeaks(); // these are indexes
			final freqs = peaks.map(function(k:Int) : Float {
				final w = 2 * Math.PI * indexToFreq(k);
				final a = current[k].real;
				final b = current[k].imag;
				final da = a - previous[k].real;
				final db = b - previous[k].imag;
				final dt = indexToTime(hop);
				final iw = w + (a*db/dt - b*da/dt) / (a*a + b*b);
				return iw / (2 * Math.PI);
			});
			// for (i in 0...peaks.length) {
			// 	final time = indexToTime(c);
			// 	final freq = freqs[i];
			// 	final mag = mags[peaks[i]];
			// 	haxe.Log.trace('${time};${freq};${mag}', null);
			// }
			// haxe.Log.trace("", null);

			// construct salience function
			final magnitudeCompression = 1;
			final magnitudeThreshold = 40;
			final harmonicRange = 20;
			final harmonicWeighting = 0.8;
			final salienceFunction = function(b:Int) {
				var sum = 0.0;
				for (i in 0...peaks.length) {
					final fi = freqs[i];
					final ai = mags[peaks[i]];

					final e = 20.0 * Math.log(mags[highestPeak(peaks, mags)] / ai) / Math.log(10);
					if (e > magnitudeThreshold) continue;

					for (h in 1 ... harmonicRange + 1) {
						final d = Math.abs(hzToCentsBin(fi / h) - b) / 10;
						if (d > 1) continue;

						final g = Math.pow(Math.cos(d * Math.PI / 2), 2)
						        * Math.pow(harmonicWeighting, h - 1);
						sum += Math.pow(ai, magnitudeCompression) * g;
					}
				}
				return sum;
			};
			// for (i in 0...hzToCentsBin(maxFreq)) {
			// 	final b = i + 1;
			// 	final t = indexToTime(c);
			// 	final f = centsBinToHz(b);
			// 	final s = salienceFunction(b);
			// 	haxe.Log.trace('${t};${f};${s}', null);
			// }
			// haxe.Log.trace("", null);

			// select melody track candidates from salience peaks
			final saliences = [for (i in 0...hzToCentsBin(maxFreq)) salienceFunction(i + 1)];
			var candidates = saliences.findPeaks(); // these are indexes
			final saliencePeakThreshold = 0.9;
			candidates = candidates.filter(i ->
				saliences[highestPeak(candidates, saliences)] - saliences[i] < saliencePeakThreshold
			);
			final avgSalience = candidates.map(i -> saliences[i]).sum() / candidates.length; // @TODO: moving average?
			final stdSalience = candidates.map(i -> Math.pow(saliences[i] - avgSalience, 2) / candidates.length)
			                              .sum()
			                              .sqrt();
			final salienceOutlierFactor = 0.9;
			final minSalience = avgSalience - salienceOutlierFactor * stdSalience;
			candidates = candidates.filter(i -> saliences[i] >= minSalience);
			for (i in candidates) {
				final b = i + 1;
				final t = indexToTime(c);
				final f = centsBinToHz(b);
				final s = saliences[i];
				haxe.Log.trace('${t};${f};${s}', null);
			}
			haxe.Log.trace("", null);
		} while (c < samples.length);
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
