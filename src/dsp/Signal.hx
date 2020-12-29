package dsp;

/**
	Signal processing miscellaneous utilities.
**/
class Signal {
	/**
		Finds indexes of peaks in the order they appear in the input sequence.

		@param threshold Minimal peak height (distance from neighbours), defaults to 0.
	**/
	public static function findPeaks(y:Array<Float>, ?threshold:Float) : Array<Int> {
		threshold = threshold == null ? 0.0 : Math.abs(threshold);

		var peaks = new Array<Int>();

		final dy = [for (i in 1...y.length) y[i] - y[i-1]];
		for (i in 1...dy.length) {
			// peak: function growth positive to its left and negative to its right
			if (dy[i-1] > threshold && dy[i] < -threshold) peaks.push(i);
		}

		return peaks;
	}
}
