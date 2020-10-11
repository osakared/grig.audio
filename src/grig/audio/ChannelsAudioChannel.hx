package grig.audio;

#if cpp
import haxe.ds.Vector;
#end

/**
    Represents a floating-point based signal
**/
class ChannelsAudioChannel implements AudioChannelImpl
{
    private var channel:AudioChannelData;

    public function new(channel:AudioChannelData)
    {
        this.channel = channel;
    }

    public inline function getLength():Int
    {
        return channel.length;
    }

    public inline function getSample(index:Int)
    {
        #if cpp
        return cpp.NativeArray.unsafeGet(cast channel, index);
        #else
        return channel[index];
        #end
    }

    public inline function setSample(index:Int, sample:AudioSample):AudioSample
    {
        #if cpp
        return cpp.NativeArray.unsafeSet(cast channel, index, sample);
        #else
        return channel[index] = sample;
        #end
    }

    /**
        Adds `length` values from calling `AudioChannel` starting at `sourceStart` into `other`, starting at `sourceStart`.
        Values are summed.
    **/
    public inline function addInto(other:AudioChannel, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    {
        var minLength = (channel.length - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (channel.length - sourceStart);
        if (sourceStart < 0) sourceStart = 0;
        if (sourceStart >= channel.length) return;
        if (otherStart < 0) otherStart = 0;
        if (length == null || length > minLength) {
            length = minLength;
        }
        for (i in 0...length) {
            other[otherStart + i] += channel[sourceStart + i];
        }
    }

    /**
        Copes `length` values from calling `AudioChannel` starting at `sourceStart` into `other`, starting at `sourceStart`.
        Values in other are replaced with values from calling `AudioChannel`.
    **/
    public function copyInto(other:AudioChannel, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    {
        var minLength = (channel.length - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (channel.length - sourceStart);
        if (sourceStart < 0) sourceStart = 0;
        if (sourceStart >= channel.length) return;
        if (otherStart < 0) otherStart = 0;
        if (length == null || length > minLength) {
            length = minLength;
        }
        #if cpp
        Vector.blit(channel, sourceStart, cast other, otherStart, length);
        #else
        for (i in 0...length) {
            other[otherStart + i] = channel[sourceStart + i];
        }
        #end
    }

    /** Multiply all values in the signal by gain **/
    public function applyGain(gain:Float)
    {
        // This is ripe for optimization...
        for (i in 0...channel.length) {
            channel[i] *= gain;
        }
    }

    /** Create a new `AudioChannel` with the same parameters and data (deep copy) **/
    public function copy():ChannelsAudioChannel
    {
        var newChannel = new ChannelsAudioChannel(new AudioChannelData(channel.length));
        copyInto(new AudioChannel(newChannel));
        return newChannel;
    }

    /** Set all values in the signal to `value` **/
    public function setAll(value:Float)
    {
        // If only I could use memset here..
        for (i in 0...channel.length) {
            channel[i] = value;
        }
    }

    /** Resets the buffer to silence (all `0.0`) **/
    public function clear()
    {
        #if cpp
        cpp.NativeArray.zero(cast channel, 0, channel.length);
        #else
        setAll(0.0);
        #end
    }
}