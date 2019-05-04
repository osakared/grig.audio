package grig.audio.python; #if python

import grig.audio.python.numpy.Ndarray;

abstract AudioChannelData(Ndarray)
{
    public var length(get, never):Int;

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

    public function copyInto(other:AudioChannelData, sourceStart:Int = 0, length:Null<Int> = null)
    {
        // This can probably be replaced by a more efficient numpy function
        var minLength = (get_length() - sourceStart) > other.length ? other.length : (get_length() - sourceStart);
        if (sourceStart < 0) sourceStart = 0;
        if (length == null || length > minLength) {
            length = minLength;
        }
        for (i in 0...length) {
            other[i] = get(sourceStart + i);
        }
    }
}

#end