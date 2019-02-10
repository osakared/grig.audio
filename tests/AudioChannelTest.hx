package;
  
import grig.audio.AudioChannel;
import tink.unit.Assert.*;

@:asserts
class AudioChannelTest {

    public function new()
    {
    }

    public function testAdd()
    {
        var length = 100;
        var channel1Data = new AudioChannelData(length);
        var channel1 = new AudioChannel(channel1Data);
        var channel2Data = new AudioChannelData(length);
        var channel2 = new AudioChannel(channel2Data);
        // Fill both with destructively interfering 
        for (i in 0...channel1.length) {
            channel1[i] = Math.sin(i);
            channel2[i] = Math.sin(i + Math.PI);
        }
        channel1.addInto(channel2, 0, length);
        return assert(channel2.isSilent() && !channel1.isSilent());
    }

}