package grig.audio;

interface AudioBufferImpl
{
    /** Sample rate of the signal contained within **/
    public function getSampleRate():Float;
    /** Number of channels **/
    public function getNumChannels():Int;
    /** Samples per channel **/
    public function getNumSamples():Int;

    public function clear():Void;
    public function getChannel(i:Int):AudioChannelImpl;
}