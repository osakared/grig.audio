package;

import grig.audio.AudioBuffer;
import grig.audio.AudioChannel;
import grig.audio.InterleavedAudioBuffer;
import grig.audio.LinearInterpolator;
import grig.audio.NumericTypes;
import tink.unit.Assert.*;

using grig.audio.AudioBufferTools;
using grig.audio.AudioChannelTools;

@:asserts
class AudioChannelTest {

    public function new()
    {
    }

    public function testAdd()
    {
        var length = 100;
        var channel1 = new AudioChannel(length);
        var channel2 = new AudioChannel(length);
        // Fill both with destructively interfering signals
        for (i in 0...length) {
            channel1[i] = Math.sin(i);
            channel2[i] = Math.sin(i + Math.PI);
        }
        channel2.addFrom(channel1, length);
        return assert(channel2.isSilent() && !channel1.isSilent());
    }

    public function testResample()
    {
        var length = 10;
        var buffer = new AudioBuffer<Float32>(1, length, 44100.0);
        for (i in 0...buffer.numSamples) {
            buffer[0][i] = i;
        }
        var resampledBuffer1 = buffer.resample(2.0);
        var resampledBuffer2 = buffer.resample(0.5);

        return assert(resampledBuffer1[0][1] == 0.5 && resampledBuffer2[0][1] == 2);
    }

    #if (!js && !python)
    public function testInterleaved()
    {
        var buffer = new InterleavedAudioBuffer<Float64>(2, 10, 48000.0);
        for (i in 0...buffer.numSamples) {
            buffer[0][i] = 0;
            buffer[1][i] = i;
        }

        return assert(buffer[0][5] == 0.0);
    }
    #end

}