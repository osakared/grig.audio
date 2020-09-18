package grig.audio;

import grig.audio.AudioChannel.AudioChannelData;

class AudioBufferBase
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

    public static function create(numChannels:Int, numSamples:Int, sampleRate:Float):AudioBufferBase
    {
        var channels = new Array<AudioChannel>();
        for (c in 0...numChannels) {
            channels.push(new AudioChannel(numSamples));
        }
        return new AudioBufferBase(channels, sampleRate);
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
        if (ratio == 0) return new AudioBufferBase(newChannels, 44100.0);
        for (channel in channels) {
            newChannels.push(LinearInterpolator.resampleChannel(channel, ratio));
        }
        return new AudioBufferBase(newChannels, repitch ? sampleRate : sampleRate * ratio);
    }

    public function copyInto(other:AudioBufferBase, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    {
        var minLength = (length - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (length - sourceStart);
        if (sourceStart < 0 || sourceStart >= length) sourceStart = 0;
        if (otherStart < 0) otherStart = 0;
        if (length == null || length > minLength) {
            length = minLength;
        }
        var numChannels = channels.length > other.channels.length ? other.channels.length : channels.length;
        for (c in 0...numChannels) {
            trace(sourceStart);
            trace(length);
            channels[c].copyInto(other.channels[c], sourceStart, length, otherStart);
        }
    }
}
