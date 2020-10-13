package grig.audio;

// #if (js && !nodejs && !heaps)
// typedef AudioBuffer = grig.audio.js.webaudio.AudioBuffer;
// #elseif python
// typedef AudioBuffer = grig.audio.python.AudioBuffer;
// #else

class InterleavedAudioBuffer implements AudioBufferImpl
{
    /** Sample rate of the signal contained within **/
    private var sampleRate:Float;
    private var channels:AudioChannelData;
    private var numChannels:Int;

    public inline function getNumChannels():Int
    {
        return numChannels;
    }

    public inline function getNumSamples():Int
    {
        return if (numChannels < 1) 0;
        else return Std.int(channels.length / numChannels);
    }

    public inline function getSampleRate():Float
    {
        return sampleRate;
    }

    public function new(channels:AudioChannelData, sampleRate:Float, numChannels:Int)
    {
        this.channels = channels;
        this.sampleRate = sampleRate;
        this.numChannels = numChannels;
    }

    public static function create(numChannels:Int, numSamples:Int, sampleRate:Float):AudioBuffer
    {
        var channels = new AudioChannelData(numChannels * numSamples);
        return new AudioBuffer(new InterleavedAudioBuffer(channels, sampleRate, numChannels));
    }

    public function clear():Void
    {
        #if cpp
        cpp.NativeArray.zero(cast channels, 0, channels.length);
        #else
        for (i in 0...channels.length) {
            channels[i] = 0.0;
        }
        #end
    }

    public function getChannel(channel:Int):InterleavedAudioChannel
    {
        return new InterleavedAudioChannel(channels, numChannels, channel);
    }

    // public function resample(ratio:Float, repitch:Bool = false)
    // {
    //     var newChannels = new Array<AudioChannel>();
    //     if (ratio == 0) return new AudioBuffer(newChannels, 44100.0);
    //     for (channel in channels) {
    //         newChannels.push(LinearInterpolator.resampleChannel(channel, ratio));
    //     }
    //     return new AudioBuffer(newChannels, repitch ? sampleRate : sampleRate * ratio);
    // }

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
