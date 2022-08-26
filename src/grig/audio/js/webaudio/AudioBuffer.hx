package grig.audio.js.webaudio; #if (js && !nodejs)

import grig.audio.AudioChannel;

@:forward(sampleRate)
abstract AudioBuffer(js.html.audio.AudioBuffer)
{
    public var numChannels(get, never):Int;
    public var numSamples(get, never):Int;

    private inline function get_numChannels():Int {
        return this.numberOfChannels;
    }

    private inline function get_numSamples():Int {
        return this.length;
    }

    inline public function new(numChannels:Int, numSamples:Int, sampleRate:Float)
    {
        this = new js.html.audio.AudioBuffer({
            sampleRate: sampleRate,
            numberOfChannels: numChannels,
            length: numSamples
        });
    }

    @:arrayAccess
    public inline function get(i:Int):js.lib.Float32Array {
        return return this.getChannelData(i);
    }

    inline public function clear():Void
    {
        for (i in 0...this.numberOfChannels) {
            this.getChannelData(i).fill(0.0);
        }
    }

    // public function resample(ratio:Float, repitch:Bool = false)
    // {
    //     if (ratio == 0) return create(0, 0, 44100.0);
    //     var newBuffer = create(channels.length, Math.ceil(this.length * ratio), repitch ? this.sampleRate : this.sampleRate * ratio);
    //     for (c in 0...newBuffer.channels.length) {
    //         LinearInterpolator.resampleIntoChannel(channels[c], newBuffer.channels[c], ratio);
    //     }
    //     return newBuffer;
    // }
}

#end