package grig.audio;

interface AudioChannelImpl
{
    public function getSample(index:Int):AudioSample;
    public function setSample(index:Int, sample:AudioSample):AudioSample;
    public function getLength():Int;

    /** Multiply all values in the signal by gain **/
    public function applyGain(gain:Float):Void;

    /** Create a new `AudioChannel` with the same parameters and data (deep copy) **/
    // public function copy():AudioChannelImpl;

    /** Set all values in the signal to `value` **/
    public function setAll(value:Float):Void;

    /** Resets the buffer to silence (all `0.0`) **/
    public function clear():Void;
}