package grig.audio.python; #if python

import grig.audio.python.numpy.Ndarray;
import python.Tuple;

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

    public static function create(numChannels:Int, numSamples:Int, sampleRate:Float):AudioBuffer
    {
        var outputData:Ndarray = grig.audio.python.numpy.Numpy.zeros(python.Tuple2.make(numChannels, numSamples));
        return new AudioBuffer(new AudioBufferData(outputData), sampleRate);
    }

    public function clear():Void
    {
        channels.clear();
    }

    public function resample(ratio:Float, repitch:Bool = false):AudioBuffer
    {
        if (ratio == 0) return create(0, 0, 44100.0);
        var numSamples = Math.ceil(length * ratio);
        var outputData:Ndarray = grig.audio.python.numpy.Numpy.zeros(python.Tuple2.make(channels.length, numSamples));
        var inputIndices = grig.audio.python.numpy.Numpy.zeros(python.Tuple2.make(1, numSamples));
        for (i in 0...numSamples) {
            var newValue = i / ratio;
            if (newValue > length - 1) newValue = length - 1;
            inputIndices.__getitem__(0).__setitem__(i, newValue);
        }
        for (c in 0...channels.length) {
            var channel = channels[c];
            var indices:Ndarray = python.Syntax.code('{0}.arange(0, {1}.shape[0])', grig.audio.python.numpy.Numpy, channel);
            var int = grig.audio.python.scipy.Interpolate.interp1d(indices, cast channel, 'linear');
            outputData.__setitem__(c, int(inputIndices));
        }
        return new AudioBuffer(new AudioBufferData(outputData), repitch ? sampleRate : sampleRate * ratio);
    }

    public function copyInto(other:AudioBuffer, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    {
        var minLength = (length - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (length - sourceStart);
        if (sourceStart < 0) sourceStart = 0;
        if (otherStart < 0) otherStart = 0;
        if (length == null || length > minLength) {
            length = minLength;
        }
        var numChannels = channels.length > other.channels.length ? other.channels.length : channels.length;
        for (c in 0...numChannels) {
            channels[c].copyInto(other.channels[c], sourceStart, length, otherStart);
        }
    }
}

#end