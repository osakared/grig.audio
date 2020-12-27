class MathUtils {
	/**
		Finds the power of 2 that is equal to or greater than given natural.
	**/
	public static function nextPow2(x:Int) : Int {
		if (x < 2) return 1;
		else if ((x & (x-1)) == 0) return x;
		var pow = 2;
		x--;
		while ((x >>= 1) != 0) pow <<= 1;
		return pow;
	}
}

@:forward(real, imag) @:notNull @:pure
abstract Complex({
	final real : Float;
	final imag : Float;
}) {
	public inline function new(real:Float, imag: Float) {
		this = { real: real, imag: imag };
	}

	public var magnitude(get,never) : Float;
	public inline function get_magnitude() {
		return Math.sqrt(this.real*this.real + this.imag*this.imag);
	}

	public var angle(get,never) : Float;
	public inline function get_angle() {
		return Math.atan2(this.imag, this.real);
	}

	@:op(A + B)
	public inline function add(rhs:Complex) : Complex {
		return new Complex(this.real + rhs.real, this.imag + rhs.imag);
	}

	@:op(A - B)
	public inline function sub(rhs:Complex) : Complex {
		return new Complex(this.real - rhs.real, this.imag - rhs.imag);
	}

	@:op(A * B)
	public inline function mult(rhs:Complex) : Complex {
		return new Complex(this.real*rhs.real - this.imag*rhs.imag,
		                   this.real*rhs.imag + this.imag*rhs.real);
	}

	public inline function conj() : Complex {
		return new Complex(this.real, -this.imag);
	}

	/**
		Multiplication by a real factor, does not modify this Complex object.
	**/
	public inline function scale(k:Float) : Complex {
		return new Complex(this.real * k, this.imag * k);
	}

	public inline function copy() : Complex {
		return new Complex(this.real, this.imag);
	}

	/**
		The imaginary unit.
	**/
	public static final im = new Complex(0, 1);

	public static inline function fromReal(r:Float) {
		return new Complex(r, 0);
	}

	/**
		Complex exponential.
	**/
	public static inline function exp(w:Float) {
		return new Complex(Math.cos(w), Math.sin(w));
	}
}
