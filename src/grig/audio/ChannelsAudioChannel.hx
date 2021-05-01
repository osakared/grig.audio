package grig.audio;

/**
    Represents a floating-point based signal
**/
@:allow(grig.audio.AudioChannelTools)
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

    public inline function getSample(index:Int):AudioSample
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

    /** Multiply all values in the signal by gain **/
    public function applyGain(gain:Float)
    {
        // This is ripe for optimization...
        for (i in 0...channel.length) {
            channel[i] *= gain;
        }
    }

    // /** Create a new `AudioChannel` with the same parameters and data (deep copy) **/
    // public function copy():ChannelsAudioChannel
    // {
    //     var newChannel = new ChannelsAudioChannel(new AudioChannelData(channel.length));
    //     copyInto(new AudioChannel(newChannel));
    //     return newChannel;
    // }

    /** Set all values in the signal to `value` **/
    public function setAll(value:Float)
    {
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

    public function resample(ratio:Float, repitch:Bool = false):AudioChannel
    {
        var newNumSamples = Math.ceil(getLength() * ratio);
        var newAudioChannel = new ChannelsAudioChannel(new AudioChannelData(newNumSamples));
        LinearInterpolator.resampleIntoChannel(this, newAudioChannel, ratio);
        return newAudioChannel;
    }
}