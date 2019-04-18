package grig.audio.js.webaudio; #if (js && !nodejs)

import grig.audio.AudioChannel;

@:forward(sampleRate)
abstract AudioBuffer(js.html.audio.AudioBuffer)
{
    public var channels(get, never):Array<AudioChannel>;

    inline public function new(i:js.html.audio.AudioBuffer)
    {
        this = i;
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
}

#end