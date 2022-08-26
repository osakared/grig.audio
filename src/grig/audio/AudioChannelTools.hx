package grig.audio;

class AudioChannelTools
{
    static private var sumOfSquaresThreshold:Float = 0.1;

    /** Sum of squares of the data. A quick and dirty way to check energy level **/
    @:generic
    public static function sumOfSquares<T:Float>(channel:AudioChannel<T>):Float
    {
        var sum:Float = 0.0;
        for (i in 0...channel.length) {
            sum += channel[i];
        }
        var avg:Float = sum / channel.length;
        var squaresSum:Float = 0.0;
        for (i in 0...channel.length) {
            squaresSum += Math.pow(channel[i] - avg, 2.0);
        }
        return squaresSum;
    }

    /** Uses sum of squares to determine sufficiently low energy **/
    @:generic
    public static function isSilent<T:Float>(input:AudioChannel<T>):Bool
    {
        return sumOfSquares(input) < sumOfSquaresThreshold;
    }

    @:generic
    public static function copyFrom<T:Float>(self:AudioChannel<T>, other:AudioChannel<T>, length:Int,
                                             otherStart:Int = 0, start:Int = 0):Void
    {
        #if cpp
        cpp.NativeArray.blit(cast self, start,
                             cast other, otherStart, length);
        #end
        for (i in 0...length) {
            self[start + i] = other[otherStart + i];
        }
    }

    @:generic
    public static function addFrom<T:Float>(self:AudioChannel<T>, other:AudioChannel<T>, length:Int,
                                             otherStart:Int = 0, start:Int = 0):Void
    {
        // Definitely gotta optimize this in C++
        for (i in 0...length) {
            self[start + i] += other[otherStart + i];
        }
    }

    /** Returns a resampled version of the channel **/
    @:generic
    public function resample<T:Float>(input:AudioChannel<T>, ratio:Float):AudioChannel<T> {
        var newNumSamples = Math.ceil(input.length * ratio);
        var newAudioChannel = new AudioChannel<T>(newNumSamples);
        var interpolator = new LinearInterpolator<T>();
        interpolator.resampleIntoChannel(input, newAudioChannel, ratio);
        return newAudioChannel;
    }

    // /**
    //     Adds `length` values from calling `AudioChannel` starting at `sourceStart` into `other`, starting at `sourceStart`.
    //     Values are summed.
    // **/
    // public inline function addInto(other:AudioChannel, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    // {
    //     var minLength = (channel.length - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (channel.length - sourceStart);
    //     if (sourceStart < 0) sourceStart = 0;
    //     if (sourceStart >= channel.length) return;
    //     if (otherStart < 0) otherStart = 0;
    //     if (length == null || length > minLength) {
    //         length = minLength;
    //     }
    //     for (i in 0...length) {
    //         other[otherStart + i] += channel[sourceStart + i];
    //     }
    // }

    // /**
    //     Copes `length` values from calling `AudioChannel` starting at `sourceStart` into `other`, starting at `sourceStart`.
    //     Values in other are replaced with values from calling `AudioChannel`.
    // **/
    // public function copyInto(other:AudioChannel, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    // {
    //     var minLength = (channel.length - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (channel.length - sourceStart);
    //     if (sourceStart < 0) sourceStart = 0;
    //     if (sourceStart >= channel.length) return;
    //     if (otherStart < 0) otherStart = 0;
    //     if (length == null || length > minLength) {
    //         length = minLength;
    //     }
    //     #if cpp
    //     Vector.blit(channel, sourceStart, cast other, otherStart, length);
    //     #else
    //     for (i in 0...length) {
    //         other[otherStart + i] = channel[sourceStart + i];
    //     }
    //     #end
    // }
}