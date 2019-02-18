package grig.audio.python;

class AudioBuffer
{
    /** Sample rate of the signal contained within **/
    public var sampleRate(default, null):Float;
    public var channels:AudioBufferData;

    public function new(_channels:AudioBufferData, _sampleRate:Float)
    {
        channels = _channels;
        sampleRate = _sampleRate;
    }
}