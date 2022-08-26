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

    // public inline function copyFrom(other:AudioBuffer, length:Int, otherStart:Int = 0, start:Int = 0):Void {
    //     AudioBufferTools.copyFrom(this, other, length, otherStart, start);
    // }
}