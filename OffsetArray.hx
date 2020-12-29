/**
	A type that behaves like an Array with an indexing offset.
**/
@:forward(array, offset)
abstract OffsetArray<T>(OffsetArrayStruct<T>) {
	/**
		Make an OffsetArray view into an `array`, where indexes start at the given `offset`.
	**/
	public inline function new(array:Array<T>, offset:Int) {
		this = { array: array, offset: offset };
	}

	@:from
	public static inline function fromArray<T>(array:Array<T>) {
		return new OffsetArray(array, 0);
	}

	@:to
	public inline function toArray() {
		return this.array;
	}

	public var length(get,never) : Int;
	public inline function get_length() {
		return this.array.length;
	}

	@:arrayAccess
	public inline function get(index:Int) : T {
		return this.array[index - this.offset];
	}

	@:arrayAccess
	public inline function set(index:Int, value:T) : Void {
		this.array[index - this.offset] = value;
	}

	public inline function keyValueIterator() : KeyValueIterator<Int,T> {
		return new OffsetArrayIterator(this);
	}

	/**
		Makes a shifted version of the given `array`, where elements are in the
		same order but shifted by `n` positions (to the right if positive and to
		the left if negative) in circular fashion (no elements discarded).
	**/
	public static function circShift<T>(array:Array<T>, n:Int) : Array<T> {
		if (n < 0) return circShift(array, array.length + n);

		var shifted = new Array<T>();

		n = n % array.length;
		for (i in array.length - n ... array.length) shifted.push(array[i]);
		for (i in 0...n) shifted.push(array[i]);

		return shifted;
	}
}

private typedef OffsetArrayStruct<T> = {
	final array : Array<T>;
	final offset : Int;
}

@:allow(OffsetArray)
private class OffsetArrayIterator<T> {
	private final oa : OffsetArrayStruct<T>;
	private var enumeration : Int;

	public inline function new(oa:OffsetArrayStruct<T>) {
		this.oa = oa;
		this.enumeration = 0;
	}

	public inline function next() : {key:Int, value:T} {
		final i = this.enumeration++;
		return { key: i + this.oa.offset, value: this.oa.array[i] };
	}

	public inline function hasNext() : Bool {
		return this.enumeration < this.oa.array.length;
	}
}
