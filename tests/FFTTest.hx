package;

import grig.audio.dsp.Complex;
import grig.audio.dsp.FFT;

using grig.audio.dsp.OffsetArray;
using grig.audio.dsp.Signal;

@:asserts
class FFTTest {

    public function new()
    {
    }

    public function testAdd()
    {
        // sampling and buffer parameters
		final Fs = 44100.0;
		final N = 512;
		final halfN = Std.int(N / 2);

		// build a time signal as a sum of sinusoids
		final freqs = [5919.911];
		final ts = [for (n in 0...N) freqs.map(f -> Math.sin(2 * Math.PI * f * n / Fs)).sum()];

		// get positive spectrum and use its symmetry to reconstruct negative domain
		final fs_pos = FFT.rfft(ts);
		final fs_fft = new OffsetArray(
			[for (k in -(halfN - 1) ... 0) fs_pos[-k].conj()].concat(fs_pos),
			-(halfN - 1)
		);

		// double-check with naive DFT
		final fs_dft = new OffsetArray(
            @:privateAccess
			FFT.dft(ts.map(Complex.fromReal)).circShift(halfN - 1),
			-(halfN - 1)
		);
		final fs_err = [for (k in -(halfN - 1) ... halfN) fs_fft[k] - fs_dft[k]];
		final max_fs_err = fs_err.map(z -> z.magnitude).max();
        asserts.assert(max_fs_err <= 1e-6);

		// find spectral peaks to detect signal frequencies
		final freqis = fs_fft.array.map(z -> z.magnitude)
		                           .findPeaks()
		                           .map(k -> (k - (halfN - 1)) * Fs / N)
		                           .filter(f -> f >= 0);
		if (freqis.length != freqs.length) {
			trace('Found frequencies: ${freqis}');
		} else {
			final freqs_err = [for (i in 0...freqs.length) freqis[i] - freqs[i]];
			final max_freqs_err = freqs_err.map(Math.abs).max();
            asserts.assert(max_freqs_err <= Fs / N);
		}

		// recover time signal from the frequency domain
		final ts_ifft = FFT.ifft(fs_fft.array.circShift(-(halfN - 1)).map(z -> z.scale(1 / Fs)));
		final ts_err = [for (n in 0...N) ts_ifft[n].scale(Fs).real - ts[n]];
		final max_ts_err = ts_err.map(Math.abs).max();
        asserts.assert(max_ts_err <= 1e-6);

        return asserts.done();
    }

}