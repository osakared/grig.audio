package grig.audio.python; #if python

class AudioBuffer
{
    /** Sample rate of the signal contained within **/
    public var sampleRate(default, null):Float;
    public var channels:AudioBufferData;
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

    public function new(_channels:AudioBufferData, _sampleRate:Float)
    {
        channels = _channels;
        sampleRate = _sampleRate;
    }

    public function clear():Void
    {
        channels.clear();
    }
}

#end