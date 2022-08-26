package grig.audio;

// #if (js && !nodejs && !heaps)
// typedef AudioBuffer = grig.audio.js.webaudio.AudioBuffer;
// #elseif python
// typedef AudioBuffer = grig.audio.python.AudioBuffer;
// #else

@:forward
@:generic
abstract InterleavedAudioBuffer<T:Float>(InterleavedAudioBufferData<T>)
{
    public inline function new(numChannels:Int, numSamples:Int, sampleRate:Float) {
        this = new InterleavedAudioBufferData<T>(numChannels, numSamples, sampleRate);
    }

    @:arrayAccess
    public inline function get(i:Int):InterleavedAudioChannelView<T> {
        return this.get(i);
    }
}
