package grig.audio.python; #if python

import grig.audio.python.numpy.Ndarray;

abstract AudioBufferData(Ndarray)
{
    public var length(get, never):Int;

    public function new(arry:Ndarray)
    {
        this = arry;
    }

    @:arrayAccess
    public inline function get(key:Int):AudioChannelData
    {
        return this.__getitem__(key);
    }

    @:arrayAccess
    public inline function set(key:Int, value:AudioChannelData):AudioChannelData {
        this.__setitem__(key, value);
        return value;
    }

    private inline function get_length():Int
    {
        return python.Syntax.code('len({0})', this);
    }

    public function clear():Void
    {
        this.fill(0.0);
    }

    public function applyGain(gain:Float)
    {
        python.Syntax.code('{0} *= {1}', this, gain);
    }
}

#end