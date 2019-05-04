package grig.audio.js.webaudio; #if (js && !nodejs)

import grig.audio.AudioChannel;

@:forward(sampleRate, length)
abstract AudioBuffer(js.html.audio.AudioBuffer)
{
    public var channels(get, never):Array<AudioChannel>;

    inline public function new(i:js.html.audio.AudioBuffer)
    {
        this = i;
    }

    inline public static function create(numChannels:Int, numSamples:Int, sampleRate:Float):AudioBuffer
    {
        return new AudioBuffer(new js.html.audio.AudioBuffer({length: numSamples, numberOfChannels: numChannels, sampleRate: sampleRate}));
    }

    inline private function get_channels():Array<AudioChannel>
    {
        return [for (i in 0...this.numberOfChannels) new AudioChannel(this.getChannelData(i))]; // I hope there's a better way to do this..
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
        var newBuffer = create(channels.length, Math.ceil(this.length * ratio), repitch ? this.sampleRate : this.sampleRate * ratio);
        for (c in 0...newBuffer.channels.length) {
            LinearInterpolator.resampleIntoChannel(channels[c], newBuffer.channels[c], ratio);
        }
        return newBuffer;
    }
}

#end