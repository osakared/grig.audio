package grig.audio;

class AudioBufferTools
{
    public static function copyFrom(self:AudioBuffer, other:AudioBuffer, length:Int, otherStart:Int = 0, start:Int = 0):Void
    {
        #if cpp
        if (Std.isOfType(self, InterleavedAudioBuffer) && Std.isOfType(other, InterleavedAudioBuffer) && self.numChannels == other.numChannels) {
            var otherInterleaved:InterleavedAudioBuffer = cast other;
            cpp.NativeArray.blit(cast otherInterleaved.channels, start * self.numChannels, cast otherInterleaved.channels,
                                 otherStart * self.numChannels, length * self.numChannels);
            return;
        }
        #end
        var channelsToCopy = Algorithm.min(self.numChannels, other.numChannels);
        for (c in 0...channelsToCopy) {
            AudioChannelTools.copyFrom(self[c], other[c], length, otherStart, start);
        }
    }
}