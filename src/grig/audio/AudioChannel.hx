package grig.audio;

import haxe.ds.Vector;

#if (js && !nodejs && !heaps)
typedef AudioChannelData = js.lib.Float32Array;
#elseif cpp
typedef AudioChannelData = haxe.ds.Vector<cpp.Float32>;
#else
typedef AudioChannelData = haxe.io.Float32Array;
#end

/**
    Represents a floating-point based signal
**/
@:forward(length)
abstract AudioChannel(AudioChannelData)
{    
    static private var sumOfSquaresThreshold:Float = 0.1;

    /** Creates a new silent buffer **/
    public function new(i:AudioChannelData)
    {
        this = i;
    }

    @:arrayAccess
    inline function getSample(index:Int)
        return this[index];

    @:arrayAccess
    inline function setSample(index:Null<Int>, sample:Float):Float {
        return this[index] = sample;

    }

    // TODO should have an otherStart parameter and honor it
    /**
        Adds `length` values from calling `AudioChannel` starting at `sourceStart` into `other`, starting at `sourceStart`.
        Values are summed.
    **/
    public inline function addInto(other:AudioChannel, sourceStart:Int = 0, length:Null<Int> = null)
    {
        // Why doesn't haxe have max/min for ints?
        var minLength = this.length > other.length ? other.length : this.length;
        if (sourceStart < 0) sourceStart = 0;
        if (length == null || length > minLength) {
            length = minLength;
        }
        // This is ripe for optimization.. but be careful about not breaking targets
        for (i in 0...length) {
            other[i] = other[i] + this[sourceStart + i];
        }
    }

    // TODO should have an otherStart parameter and honor it
    /**
        Copes `length` values from calling `AudioChannel` starting at `sourceStart` into `other`, starting at `sourceStart`.
        Values in other are replaced with values from calling `AudioChannel`.
    **/
    public function copyInto(other:AudioChannel, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    {
        var minLength = (this.length - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (this.length - sourceStart);
        if (sourceStart < 0) sourceStart = 0;
        if (sourceStart >= this.length) return;
        if (otherStart < 0) otherStart = 0;
        if (length == null || length > minLength) {
            length = minLength;
        }
        #if cpp
        Vector.blit(this, sourceStart, cast other, otherStart, length);
        #else
        for (i in 0...length) {
            other[otherStart + i] = this[sourceStart + i];
        }
        #end
    }

    /** Multiply all values in the signal by gain **/
    public function applyGain(gain:Float)
    {
        // This is ripe for optimization...
        for (i in 0...this.length) {
            this[i] *= gain;
        }
    }

    /** Create a new `AudioChannel` with the same parameters and data (deep copy) **/
    public function copy():AudioChannel
    {
        var newChannel = new AudioChannel(new AudioChannelData(this.length));
        copyInto(newChannel);
        return newChannel;
    }

    /** Set all values in the signal to `value` **/
    public function setAll(value:Float)
    {
        // If only I could use memset here..
        for (i in 0...this.length) {
            this[i] = value;
        }
    }

    /** Resets the buffer to silence (all `0.0`) **/
    public function clear()
    {
        #if cpp
        cpp.NativeArray.zero(cast this, 0, this.length);
        #else
        setAll(0.0);
        #end
    }

    /** Sum of squares of the data. A quick and dirty way to check energy level **/
    public function sumOfSquares():Float
    {
        var sum:Float = 0.0;
        for (i in 0...this.length) {
            sum += this[i];
        }
        var avg:Float = sum / this.length;
        var squaresSum:Float = 0.0;
        for (i in 0...this.length) {
            squaresSum += Math.pow(this[i] - avg, 2.0);
        }
        return squaresSum;
    }

    /** Uses sum of squares to determine sufficiently low energy **/
    public function isSilent():Bool
    {
        return sumOfSquares() < sumOfSquaresThreshold;
    }
}