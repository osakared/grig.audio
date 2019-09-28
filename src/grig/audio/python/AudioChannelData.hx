package grig.audio.python; #if python

import grig.audio.python.numpy.Ndarray;

abstract AudioChannelData(Ndarray)
{
    public var length(get, never):Int;

    static private var sumOfSquaresThreshold:Float = 0.1;

    public function new(arry:Ndarray)
    {
        this = arry;
    }

    @:arrayAccess
    public inline function get(key:Int):Float
    {
        return this.__getitem__(key);
    }

    @:arrayAccess
    public inline function set(key:Int, value:Float):Float {
        this.__setitem__(key, value);
        return value;
    }

    private inline function get_length():Int
    {
        return python.Syntax.code('len({0})', this);
    }

    public function copyInto(other:AudioChannelData, sourceStart:Int = 0, length:Null<Int> = null, otherStart:Int = 0)
    {
        var minLength = (get_length() - sourceStart) > (other.length - otherStart) ? (other.length - otherStart) : (get_length() - sourceStart);
        if (sourceStart < 0) sourceStart = 0;
        if (otherStart < 0) otherStart = 0;
        if (length == null || length > minLength) {
            length = minLength;
        }
        for (i in 0...length) {
            other[otherStart + i] = get(sourceStart + i);
        }
    }

    public function applyGain(gain:Float)
    {
        python.Syntax.code('{0} *= {1}', this, gain);
    }

    /** Sum of squares of the data. A quick and dirty way to check energy level **/
    public function sumOfSquares():Float
    {
        var sum:Float = 0.0;
        for (i in 0...get_length()) {
            sum += get(i);
        }
        var avg:Float = sum / get_length();
        var squaresSum:Float = 0.0;
        for (i in 0...get_length()) {
            squaresSum += Math.pow(get(i) - avg, 2.0);
        }
        return squaresSum;
    }

    /** Uses sum of squares to determine sufficiently low energy **/
    public function isSilent():Bool
    {
        return sumOfSquares() < sumOfSquaresThreshold;
    }
}

#end