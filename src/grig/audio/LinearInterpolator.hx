package grig.audio;

import thx.Ints;

class LinearInterpolator
{
    /**
     * Returns a new input with ratio * input.length amount of samples
     * @param input input channel to be resampled
     * @param ratio ratio of output channel to input channel length
     * @return AudioChannel
     */
    // public static function resampleChannel(input:AudioChannel, ratio:Float):AudioChannel
    // {
    //     var newNumSamples = Math.ceil(input.length * ratio);
    //     var newAudioChannel = new AudioChannel(new AudioChannelData(newNumSamples));
    //     resampleIntoChannel(input, newAudioChannel, ratio);
    //     return newAudioChannel;
    // }

    // public static function resampleBuffer(input:AudioBuffer, ratio:Float, repitch:Bool = false):AudioBuffer
    // {
    //     var newNumSamples = Math.ceil(input.numSamples * ratio);
    //     var sampleRate = repitch ? input.sampleRate : input.sampleRate * ratio;
    //     var newBuffer = AudioBuffer.create(input.numChannels, newNumSamples, sampleRate);

    //     for (c in 0...input.numChannels) {
    //         resampleIntoChannel(input.channels[c], newBuffer.channels[c], ratio);
    //     }

    //     return newBuffer;
    // }

    public static function resampleIntoChannel(input:AudioChannel, output:AudioChannel, ratio:Float):Void
    {
        if (ratio == 0.0) return;
        var newNumSamples = Math.ceil(input.length * ratio);

        newNumSamples = Ints.min(newNumSamples, output.length);
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