package grig.audio;

// #if (js && !nodejs && !heaps)
// typedef AudioBuffer = grig.audio.js.webaudio.AudioBuffer;
// #elseif python
// typedef AudioBuffer = grig.audio.python.AudioBuffer;
// #else

class ChannelsAudioBuffer implements AudioBufferImpl
{
    /** Sample rate of the signal contained within **/
    private var sampleRate:Float;
    private var channels:Array<ChannelsAudioChannel>;

    public inline function getNumChannels():Int
    {
        return channels.length;
    }

    public inline function getNumSamples():Int
    {
        if (channels.length < 1) {
            return 0;
        }
        else {
            return getChannel(0).getLength();
        }
    }

    public inline function getSampleRate():Float
    {
        return sampleRate;
    }

    public function new(channels:Array<ChannelsAudioChannel>, sampleRate:Float)
    {
        this.channels = channels;
        this.sampleRate = sampleRate;
    }

    public static function create(numChannels:Int, numSamples:Int, sampleRate:Float):AudioBuffer
    {
        var channels = new Array<ChannelsAudioChannel>();
        for (c in 0...numChannels) {
            channels.push(new ChannelsAudioChannel(new AudioChannelData(numSamples)));
        }
        return new AudioBuffer(new ChannelsAudioBuffer(channels, sampleRate));
    }

    public function clear():Void
    {
        for (channel in channels) {
            channel.clear();
        }
    }

    public function getChannel(channel:Int):ChannelsAudioChannel
    {
        #if cpp
        return cpp.NativeArray.unsafeGet(channels, channel);
        #else
        return channels[channel];
        #end
    }

    public function resample(ratio:Float, repitch:Bool = false)
    {
        var newChannels = new Array<AudioChannel>();
        if (ratio == 0) return new AudioBuffer(newChannels, 44100.0);
        for (channel in channels) {
            newChannels.push(LinearInterpolator.resampleChannel(channel, ratio));
        }
        return new AudioBuffer(newChannels, repitch ? sampleRate : sampleRate * ratio);
    }

    // public function copyInto(other:AudioBuffer, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    // {
    //     var minLength = (length - sourceStart) > (other.numSamples - otherStart) ? (other.numSamples - otherStart) : (length - sourceStart);
    //     if (sourceStart < 0 || sourceStart >= length) sourceStart = 0;
    //     if (otherStart < 0) otherStart = 0;
    //     if (length == null || length > minLength) {
    //         length = minLength;
    //     }
    //     var numChannels = channels.length > other.channels.length ? other.channels.length : channels.length;
    //     for (c in 0...numChannels) {
    //         trace(sourceStart);
    //         trace(length);
    //         channels[c].copyInto(other.channels[c], sourceStart, length, otherStart);
    //     }
    // }
}
