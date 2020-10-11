package grig.audio;

class AudioChannelTools
{
    static private var sumOfSquaresThreshold:Float = 0.1;

    /** Sum of squares of the data. A quick and dirty way to check energy level **/
    public static function sumOfSquares(channel:AudioChannel):Float
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
    public static function isSilent(channel:AudioChannel):Bool
    {
        return sumOfSquares(channel) < sumOfSquaresThreshold;
    }
}