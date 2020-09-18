package grig.audio.js.webaudio; #if (js && !nodejs)

import grig.audio.AudioChannel;
import js.html.audio.AudioBuffer;
import js.html.audio.AudioBufferOptions;

@:forward(sampleRate, length)
abstract AudioBuffer(js.html.audio.AudioBuffer)
{
    inline public function new(len:Int)
    {
        this = new js.html.audio.AudioBuffer({length: len, numberOfChannels: 2, sampleRate: 44100.0});
    }

    inline public static function create(numChannels:Int, numSamples:Int, sampleRate:Float):AudioBuffer
    {
        return cast new js.html.audio.AudioBuffer({length: numSamples, numberOfChannels: numChannels, sampleRate: sampleRate});
    }

    @:arrayAccess
    inline function getChannel(index:Int)
    {
        return cast this.getChannelData(index);
    }

    inline public function clear():Void
    {
        for (i in 0...this.numberOfChannels) {
            this.getChannelData(i).fill(0.0);
        }
    }

    public function resample(ratio:Float, repitch:Bool = false)
    {
        if (ratio == 0) return create(0, 0, 44100.0);
        var newBuffer = create(this.numberOfChannels, Math.ceil(this.length * ratio), repitch ? this.sampleRate : this.sampleRate * ratio);
        for (c in 0...this.numberOfChannels) {
            LinearInterpolator.resampleIntoChannel(cast this.getChannelData(c), newBuffer[c], ratio);
        }
        return newBuffer;
    }
}

#end