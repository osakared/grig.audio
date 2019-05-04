package grig.audio;

import grig.audio.AudioChannel.AudioChannelData;
#if (js && !nodejs && !heaps)
typedef AudioBuffer = grig.audio.js.webaudio.AudioBuffer;
#elseif python
typedef AudioBuffer = grig.audio.python.AudioBuffer;
#else

class AudioBuffer
{
    /** Sample rate of the signal contained within **/
    public var sampleRate(default, null):Float;
    public var channels:Array<AudioChannel>;
    public var length(get, never):Int;

    private function get_length():Int
    {
        if (channels.length < 1) {
            return 0;
        }
        else {
            return channels[0].length;
        }
    }

    public function new(_channels:Array<AudioChannel>, _sampleRate:Float)
    {
        channels = _channels;
        sampleRate = _sampleRate;
    }

    public static function create(numChannels:Int, numSamples:Int, sampleRate:Float):AudioBuffer
    {
        var channels = new Array<AudioChannel>();
        for (c in 0...numChannels) {
            channels.push(new AudioChannel(new AudioChannelData(numSamples)));
        }
        return new AudioBuffer(channels, sampleRate);
    }

    public function clear():Void
    {
        for (channel in channels) {
            channel.clear();
        }
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
}

#end
