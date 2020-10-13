package grig.audio;

/**
    Represents a floating-point based signal
**/
class InterleavedAudioChannel implements AudioChannelImpl
{
    private var channelData:AudioChannelData;
    private var numChannels:Int;
    private var channel:Int;

    public function new(channelData:AudioChannelData, numChannels:Int, channel:Int)
    {
        this.channelData = channelData;
        this.numChannels = numChannels;
        this.channel = channel;
    }

    public inline function getLength():Int
    {
        return if (numChannels < 1) 0;
        else Std.int(channelData.length / numChannels);
    }

    private inline function getInterleavedIndex(index:Int):Int
    {
        return index * numChannels + channel;
    }

    public inline function getSample(index:Int):AudioSample
    {
        #if cpp
        return cpp.NativeArray.unsafeGet(cast channelData, getInterleavedIndex(index));
        #else
        return channelData[getInterleavedIndex(index)];
        #end
    }

    public inline function setSample(index:Int, sample:AudioSample):AudioSample
    {
        #if cpp
        return cpp.NativeArray.unsafeSet(cast channelData, getInterleavedIndex(index), sample);
        #else
        return channelData[getInterleavedIndex(index)] = sample;
        #end
    }

    /** Multiply all values in the signal by gain **/
    public function applyGain(gain:Float)
    {
        // This is ripe for optimization...
        for (i in 0...channelData.length) {
            channelData[i] *= gain;
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
        var len = getLength();
        for (i in 0...len) {
            channelData[getInterleavedIndex(i)] = value;
        }
    }

    /** Resets the buffer to silence (all `0.0`) **/
    public function clear()
    {
        setAll(0.0);
    }
}