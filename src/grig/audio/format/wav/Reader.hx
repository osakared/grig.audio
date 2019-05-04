package grig.audio.format.wav;

import format.wav.Data;
import haxe.io.Input;
import grig.audio.AudioChannel;

#if (!js && !format)
#error "Wav requires format or js/html environment";
#end

class Reader
{
    private var input:Input;

    public function new(_input:Input)
    {
        input = _input;
    }

    public function load():AudioBuffer
    {
        var reader = new format.wav.Reader(input);
        var wav = reader.read();
        var lengthPerChannel:Int = Math.ceil(wav.data.length / wav.header.channels / (wav.header.bitsPerSample / 8));
        var buffer = AudioBuffer.create(wav.header.channels, lengthPerChannel, wav.header.samplingRate);
        var bytesInput = new haxe.io.BytesInput(wav.data);
        for (i in 0...lengthPerChannel) {
            for (c in 0...buffer.channels.length) {
                // Assuming integer file format here
                buffer.channels[c][i] = if (wav.header.bitsPerSample == 8) {
                    bytesInput.readByte() / 255.0;
                } else if (wav.header.bitsPerSample == 16) {
                    bytesInput.readInt16() / 32767.0;
                } else if (wav.header.bitsPerSample == 24) {
                    bytesInput.readInt24() / 8388607.0;
                } else if (wav.header.bitsPerSample == 32) {
                    bytesInput.readInt32() / 2147483647.0;
                } else {
                    throw 'Unknown format: ${wav.header.bitsPerSample}';
                }
            }
        }
        return buffer;
    }
}