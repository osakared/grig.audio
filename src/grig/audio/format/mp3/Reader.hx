package grig.audio.format.mp3;

import format.mp3.Data;
import format.mp3.Reader;
import haxe.io.Input;
import grig.audio.AudioChannel;

#if (js && !nodejs)
typedef Reader = grig.audio.js.webaudio.Reader;
#elseif format

class Reader
{
    private var input:Input;

    public function new(_input:Input)
    {
        input = _input;
    }

    private function sampleRateEnumToSampleRate(sampleRateEnum:SamplingRate):Int
    {
        switch(sampleRateEnum) {
            case SR_8000: return 8000;
            case SR_11025: return 11025;
            case SR_12000: return 12000;
            case SR_22050: return 22050;
            case SR_24000: return 24000;
            case SR_32000: return 32000;
            case SR_44100: return 44100;
            case SR_48000: return 48000;
            case SR_Bad: throw ('Invalid sample rate');
        }
    }

    private function bitrateEnumToBitrate(bitrate:Bitrate):Int
    {
        return switch(bitrate) {
            case BR_8: 8;
            case BR_16: 16;
            case BR_24: 24;
            case BR_32: 32;
            case BR_40: 40;
            case BR_48: 48;
            case BR_56: 56;
            case BR_64: 64;
            case BR_80: 80;
            case BR_96: 96;
            case BR_112: 112;
            case BR_128: 128;
            case BR_144: 144;
            case BR_160: 160;
            case BR_176: 176;
            case BR_192: 192;
            case BR_224: 224;
            case BR_256: 256;
            case BR_288: 288;
            case BR_320: 320;
            case BR_352: 352;
            case BR_384: 384;
            case BR_416: 416;
            case BR_448: 448;
            case BR_Bad: 0;
            case BR_Free: 0;
        }
    }

    public function load():AudioBuffer
    {
        var reader = new Reader(input);
        var mp3 = reader.read();
        if (mp3.frames.length == 0) return new AudioBuffer([], 44100);
        var channels = new Array<AudioChannel>();
        channels.push(new AudioChannel(new AudioChannelData(mp3.sampleCount)));
        if (mp3.frames[0].header.channelMode != Mono) channels.push(new AudioChannel(new AudioChannelData(mp3.sampleCount)));
        var sampleRate:Int = 0;
        var bitrate:Int = 0;
        for (frame in mp3.frames) {
            sampleRate = sampleRateEnumToSampleRate(frame.header.samplingRate);
            bitrate = bitrateEnumToBitrate(frame.header.bitrate);
        }
        return new AudioBuffer(channels, sampleRateEnumToSampleRate(mp3.frames[0].header.samplingRate));
    }
}

#else
#error "MP3 requires format or js/html environment";
#end
