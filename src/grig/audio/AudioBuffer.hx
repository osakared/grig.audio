package grig.audio;

#if (js && !nodejs && !heaps)
typedef AudioBuffer = grig.audio.js.webaudio.AudioBuffer;
#elseif python
typedef AudioBuffer = grig.audio.python.AudioBuffer;
#else

@:forward(create, clear, resample, length)
abstract AudioBuffer(AudioBufferBase)
{
    public function new(_channels:Array<AudioChannel>, _sampleRate:Float)
    {
        this = new AudioBufferBase(_channels, _sampleRate);
    }

    @:arrayAccess
    inline function getChannel(index:Int)
    {
        return this.channels[index];
    }
}

#end
