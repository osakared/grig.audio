package grig.audio;

@:forward
@:generic
abstract AudioBuffer<T:Float>(AudioBufferData<T>) from AudioBufferData<T> to AudioBufferData<T>
{
    public inline function new(numChannels:Int, numSamples:Int, sampleRate:Float) {
        this = new AudioBufferData(numChannels, numSamples, sampleRate);
    }

    @:arrayAccess
    public inline function get(i:Int):AudioChannel<T> {
        return this.get(i);
    }
}