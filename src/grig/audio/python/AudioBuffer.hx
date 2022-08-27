package grig.audio.python; #if python

import grig.audio.python.numpy.Ndarray;
import python.Tuple;

@:forward
abstract AudioBuffer(AudioBufferData)
{
    public inline function new(numChannels:Int, numSamples:Int, sampleRate:Float) {
        this = new AudioBufferData(numChannels, numSamples, sampleRate);
    }

    @:arrayAccess
    public inline function get(i:Int):AudioChannel {
        return this.get(i);
    }
}

#end