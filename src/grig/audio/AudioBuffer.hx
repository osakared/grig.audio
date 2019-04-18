package grig.audio;

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

    public function clear():Void
    {
        for (channel in channels) {
            channel.clear();
        }
    }
}

#end
