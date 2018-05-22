package grig.audio;

import haxe.ds.Vector;

/**
    Represents a floating-point based signal
**/
class AudioChannel
{
    /** Internal representation of the signal **/
    private var samples:Vector<AudioSample>;
    /** Sample rate of the signal contained within **/
    public var sampleRate(default, null):Int;
    /** Length of the samples **/
    public var length(get, null):Int;
    
    private var sumOfSquaresThreshold:Float = 0.1;

    /** Creates a new silent buffer **/
    public function new(size:Int, _sampleRate:Int)
    {
        samples = new Vector<AudioSample>(size);
        sampleRate = _sampleRate;

        // Already set to 0.0 on static platforms
        #if !static
        clear();
        #end
    }

    private function get_length():Int
    {
        return samples.length;
    }

    // TODO should have an otherStart parameter and honor it
    /**
        Adds `length` values from calling `AudioChannel` starting at `sourceStart` into `other`, starting at `sourceStart`.
        Values are summed.
    **/
    public function addInto(other:AudioChannel, sourceStart:Int = 0, length:Null<Int> = null)
    {
        // Why doesn't haxe have max/min for ints?
        var minLength = samples.length > other.samples.length ? other.samples.length : samples.length;
        if (sourceStart < 0) sourceStart = 0;
        else if (sourceStart > minLength) sourceStart = minLength;
        if (length == null || sourceStart + length > minLength) {
            length = minLength - sourceStart;
        }
        // This is ripe for optimization.. but be careful about not breaking targets
        for (i in sourceStart...(sourceStart + length)) {
            other.samples[i] = other.samples[i] + samples[i];
        }
    }

    // TODO should have an otherStart parameter and honor it
    /**
        Copes `length` values from calling `AudioChannel` starting at `sourceStart` into `other`, starting at `sourceStart`.
        Values in other are replaced with values from calling `AudioChannel`.
    **/
    public function copyInto(other:AudioChannel, sourceStart:Int = 0, length:Null<Int> = null)
    {
        // Kinda violating DRY here
        var minLength = samples.length > other.samples.length ? other.samples.length : samples.length;
        if (sourceStart < 0) sourceStart = 0;
        else if (sourceStart > minLength) sourceStart = minLength;
        if (length == null || sourceStart + length > minLength) {
            length = minLength - sourceStart;
        }
        Vector.blit(samples, sourceStart, other.samples, sourceStart, length);
    }

    /** Multiply all values in the signal by gain **/
    public function applyGain(gain:AudioSample)
    {
        for (i in 0...samples.length) {
            samples[i] = samples[i] * gain;
        }
    }

    /** Create a new `AudioChannel` with the same parameters and data (deep copy) **/
    public function copy():AudioChannel
    {
        var newChannel = new AudioChannel(samples.length, sampleRate);
        copyInto(newChannel);
        return newChannel;
    }

    /** Set all values in the signal to `value` **/
    public function setAll(value:Float)
    {
        // If only I could use memset here..
        for (i in 0...samples.length) {
            samples[i] = value;
        }
    }

    /** Resets the buffer to silence (all `0.0`) **/
    public function clear()
    {
        #if cpp
        cpp.NativeArray.zero(cast samples, 0, samples.length);
        #else
        setAll(0.0);
        #end
    }

    /** Sum of squares of the data. A quick and dirty way to check energy level **/
    public function sumOfSquares():Float
    {
        var sum:Float = 0.0;
        for (i in 0...samples.length) {
            sum += samples[i];
        }
        var avg:Float = sum / samples.length;
        var squaresSum:Float = 0.0;
        for (i in 0...samples.length) {
            squaresSum += Math.pow(samples[i] - avg, 2.0);
        }
        return squaresSum;
    }

    /** Uses sum of squares to determine sufficiently low energy **/
    public function isSilent():Bool
    {
        return sumOfSquares() < sumOfSquaresThreshold;
    }

    // The lack of @arrayAccess on non-abstract is maddening
    /** Get the value of the sample pointed at by `index` **/
    public inline function get(index:Int):Float
    {
        return samples[index];
    }

    /** Set the value at `index` to `value` **/
    public inline function set(index:Int, value:Float):Float
    {
        samples[index] = value;
        return value;
    }
}