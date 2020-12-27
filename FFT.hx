import MathUtils;
using OffsetArrays;
using Lambda;

class FFT {
	/**
		Computes the Discrete Fourier Transform (DFT) of a finite sequence.

		If the input has N data points (N should be a power of 2 or padding will
		be added) from a signal sampled at intervals of 1/Fs, the result will be
		a sequence of N samples from the Discrete-Time Fourier Transform (DTFT)
		(which is Fs-periodic) with a spacing of Fs/N Hz between them and a
		scaling factor of Fs.
	**/
	public static function fft(input:Array<Complex>) : Array<Complex> {
		return do_fft(input, false);
	}

	/**
		Computes the Inverse DFT of a periodic input sequence.

		If the input contains N (a power of 2) DTFT samples, each spaced Fs/N Hz
		from each other, the result will consist of N data points as sampled
		from a time signal at intervals of 1/Fs with a scaling factor of 1/Fs.
	**/
	public static function ifft(input:Array<Complex>) : Array<Complex> {
		return do_fft(input, true);
	}

	// Handles padding and scaling for forwards and inverse FFTs.
	private static function do_fft(input:Array<Complex>, inverse:Bool) : Array<Complex> {
		final n = MathUtils.nextPow2(input.length);
		var ts = [for (i in 0...n) if (i < input.length) input[i] else new Complex(0,0)];
		var fs = [for (_ in 0...n) new Complex(0,0)];
		ditfft2(ts, 0, fs, 0, n, 1, inverse);
		return inverse ? fs.map(z -> z.scale(1 / n)) : fs;
		return fs;
	}

	// Radix-2 Decimation-In-Time variant of Cooley–Tukey's FFT, recursive.
	private static function ditfft2(
		time:Array<Complex>, t:Int,
		freq:Array<Complex>, f:Int,
		n:Int, step:Int, inverse: Bool
	) : Void {
		if (n == 1) {
			freq[f] = time[t].copy();
		} else {
			final halfLen = Std.int(n / 2);
			ditfft2(time, t,        freq, f,           halfLen, step * 2, inverse);
			ditfft2(time, t + step, freq, f + halfLen, halfLen, step * 2, inverse);
			for (k in 0...halfLen) {
				final twiddle = Complex.exp((inverse ? 1 : -1) * 2 * Math.PI * k / n);
				final even = freq[f + k].copy();
				final odd = freq[f + k + halfLen].copy();
				freq[f + k]           = even + twiddle * odd;
				freq[f + k + halfLen] = even - twiddle * odd;
			}
		}
	}

	// Naive O(n^2) DFT, used for testing purposes.
	private static function dft(ts:Array<Complex>, ?inverse:Bool) : Array<Complex> {
		if (inverse == null) inverse = false;
		final n = ts.length;
		var fs = new Array<Complex>();
		fs.resize(n);
		for (f in 0...n) {
			var sum = new Complex(0, 0);
			for (t in 0...n) {
				sum += ts[t] * Complex.exp((inverse ? 1 : -1) * 2 * Math.PI * f * t / n);
			}
			fs[f] = inverse ? sum.scale(1 / n) : sum;
		}
		return fs;
	}

	public static function main() {
		// sampling and buffer parameters
		final Fs = 44100;
		final N = 256;
		final halfN = Std.int(N / 2);

		// time signal
		final rs = [for (n in 0...N) Math.sin(2 * Math.PI * 5919.911e-0 * n / Fs)];
		// final ts = [for (n in 0...N) n < 50 ? 1 : 0];
		final ts = rs.map(Complex.fromReal);

		// find spectrum and double-check with naive DFT for errors
		final fs_fft = new OffsetArray(fft(ts).circShift(halfN), -halfN);
		final fs_dft = new OffsetArray(dft(ts).circShift(halfN), -halfN);
		final fs_err = [for (k in -halfN...halfN) fs_fft[k] - fs_dft[k]];
		final max_fs_err = fs_err.map(z -> z.magnitude).fold(Math.max, 0);
		if (max_fs_err > 1e-6) haxe.Log.trace('FT Error: ${max_fs_err}', null);
		// else for (k => s in fs_fft) haxe.Log.trace('${k * Fs / N};${s.scale(1 / Fs).magnitude}', null);

		// recover time signal from frequency domain
		final ts_ifft = ifft(fs_fft.array.circShift(-halfN).map(z -> z.scale(1 / Fs)));
		final ts_err = [for (n in 0...N) ts_ifft[n].scale(Fs).real - ts[n].real];
		final max_ts_err = ts_err.map(Math.abs).fold(Math.max, 0);
		if (max_ts_err > 1e-6) haxe.Log.trace('IFT Error: ${max_ts_err}', null);
		// else for (n in 0...ts_ifft.length) haxe.Log.trace('${n / Fs};${ts_ifft[n].scale(Fs).real}', null);
	}
}
