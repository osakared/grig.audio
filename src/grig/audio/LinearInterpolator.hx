package grig.audio;

import grig.audio.AudioChannel.AudioChannelData;

class LinearInterpolator
{
    /**
     * Returns a new input with ratio * input.length amount of samples
     * @param input input channel to be resampled
     * @param ratio ratio of output channel to input channel length
     * @return AudioChannel
     */
    public static function resampleChannel(input:AudioChannel, ratio:Float):AudioChannel
    {
        var newNumSamples = Math.ceil(input.length * ratio);
        var newAudioChannel = new AudioChannel(new AudioChannelData(newNumSamples));
        resampleIntoChannel(input, newAudioChannel, ratio);
        return newAudioChannel;
    }

    public static function resampleIntoChannel(input:AudioChannel, output:AudioChannel, ratio:Float):Void
    {
        var newNumSamples = Math.ceil(input.length * ratio);
        if (ratio == 0.0) return;

        newNumSamples = newNumSamples < output.length ? newNumSamples : output.length;
        for (i in 0...newNumSamples) {
            var idx = i / ratio;
            var leftIdx = Math.floor(idx);
            var rightIdx = Math.ceil(idx);
            if (leftIdx == rightIdx || rightIdx >= input.length) {
                output[i] = input[leftIdx];
                continue;
            }
            var leftVal = input[leftIdx];
            var rightVal = input[rightIdx];
            output[i] = (leftVal + (rightVal - leftVal) * (idx - leftIdx) / (rightIdx - leftIdx));
        }
    }
}