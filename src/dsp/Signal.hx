package dsp;

using Lambda;


/**
	Signal processing miscellaneous utilities.
**/
class Signal {
	/**
		Finds indexes of peaks in the order they appear in the input sequence.

		@param threshold Minimal peak height wrt. its neighbours, defaults to 0.
		@param minHeight Minimal peak height wrt. the whole input, defaults to global minimum.
	**/
	public static function findPeaks(
		y:Array<Float>,
		?threshold:Float,
		?minHeight:Float
	) : Array<Int> {
		threshold = threshold == null ? 0.0 : Math.abs(threshold);
		minHeight = minHeight == null ? Signal.min(y) : minHeight;

		var peaks = new Array<Int>();

		final dy = [for (i in 1...y.length) y[i] - y[i-1]];
		for (i in 1...dy.length) {
			// peak: function growth positive to its left and negative to its right
			if (
				dy[i-1] > threshold && dy[i] < -threshold &&
				y[i] > minHeight
			) {
				peaks.push(i);
			}
		}

		return peaks;
	}

	/**
		Returns the sum of all the elements of a given array.

		This function tries to minimize floating-point precision errors.
	**/
	public static function sum(array:Array<Float>) : Float {
		// Neumaier's "improved Kahan-Babuska algorithm":

		var sum = 0.0;
		var c = 0.0; // running compensation for lost precision

		for (v in array) {
			var t = sum + v;
			c += Math.abs(sum) >= Math.abs(v)
			     ? (sum - t) + v  // sum is bigger => low-order digits of v are lost
			     : (v - t) + sum; // v is bigger => low-order digits of sum are lost
			sum = t;
		}

		return sum + c; // correction only applied at the very end
	}

	public static function max(array:Array<Float>) : Float
		return array.fold(Math.max, array[0]);

	public static function min(array:Array<Float>) : Float
		return array.fold(Math.min, array[0]);
}
