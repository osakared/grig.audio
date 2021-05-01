package grig.audio;

// #if (js && !nodejs && !heaps)
// typedef AudioBuffer = grig.audio.js.webaudio.AudioBuffer;
// #elseif python
// typedef AudioBuffer = grig.audio.python.AudioBuffer;
// #else

@:allow(grig.audio.AudioBufferTools)
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

    public function resample(ratio:Float, repitch:Bool = false):AudioBuffer
    {
        
    }
}
