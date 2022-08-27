package grig.audio.python; #if python

import grig.audio.python.numpy.Ndarray;
import python.Tuple;

@:generic
class AudioBufferData
{
    public var sampleRate(default, null):Float;
    public var numSamples(get, never):Int;
    public var numChannels(get, never):Int;
    private var channels:Ndarray;

    private inline function get_numSamples():Int {
        return if (this.numChannels < 1) 0;
        else get(0).length;
    }

    private inline function get_numChannels():Int {
        return python.Syntax.code('len({0})', channels);
    }

    public function new(numChannels:Int, numSamples:Int, sampleRate:Float) {
        this.channels = grig.audio.python.numpy.Numpy.zeros(python.Tuple2.make(numChannels, numSamples));
        this.sampleRate = sampleRate;
    }

    public inline function get(key:Int):AudioChannel {
        return channels.__getitem__(key);
    }

    // public function clear():Void {
    //     this.fill(0.0);
    // }

    // public function applyGain(gain:Float) {
    //     python.Syntax.code('{0} *= {1}', this, gain);
    // }

    // public function resample(ratio:Float, repitch:Bool = false):AudioBuffer {
    //     if (ratio == 0) return create(0, 0, 44100.0);
    //     var numSamples = Math.ceil(length * ratio);
    //     var outputData:Ndarray = grig.audio.python.numpy.Numpy.zeros(python.Tuple2.make(channels.length, numSamples));
    //     var inputIndices = grig.audio.python.numpy.Numpy.zeros(python.Tuple2.make(1, numSamples));
    //     for (i in 0...numSamples) {
    //         var newValue = i / ratio;
    //         if (newValue > length - 1) newValue = length - 1;
    //         inputIndices.__getitem__(0).__setitem__(i, newValue);
    //     }
    //     for (c in 0...channels.length) {
    //         var channel = channels[c];
    //         var indices:Ndarray = python.Syntax.code('{0}.arange(0, {1}.shape[0])', grig.audio.python.numpy.Numpy, channel);
    //         var int = grig.audio.python.scipy.Interpolate.interp1d(indices, cast channel, 'linear');
    //         outputData.__setitem__(c, int(inputIndices));
    //     }
    //     return new AudioBuffer(new AudioBufferData(outputData), repitch ? sampleRate : sampleRate * ratio);
    // }

    // public function copyInto(other:AudioBuffer, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0) {
    //     var minLength = (length - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (length - sourceStart);
    //     if (sourceStart < 0) sourceStart = 0;
    //     if (otherStart < 0) otherStart = 0;
    //     if (length == null || length > minLength) {
    //         length = minLength;
    //     }
    //     var numChannels = channels.length > other.channels.length ? other.channels.length : channels.length;
    //     for (c in 0...numChannels) {
    //         channels[c].copyInto(other.channels[c], sourceStart, length, otherStart);
    //     }
    // }
}

#end