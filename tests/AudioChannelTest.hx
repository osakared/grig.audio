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
        var channel1 = new AudioChannel(length, 44100);
        var channel2 = new AudioChannel(length, 44100);
        // Fill both with destructively interfering 
        for (i in 0...length) {
            channel1.set(i, Math.sin(i));
            channel2.set(i, Math.sin(i + Math.PI));
        }
        channel1.addInto(channel2, 0, length);
        return assert(channel2.isSilent() && !channel1.isSilent());
    }

}