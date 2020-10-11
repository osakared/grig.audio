package grig.audio;

abstract AudioSample(AudioSampleData) from AudioSampleData to AudioSampleData
{
    public static inline var MIN:Float = -1.0;
    public static inline var MAX:Float = 1.0;

    public inline function new(val:AudioSampleData = 0.0)
    {
        if (val > MAX) val = Math.min(val, MAX);
        else if (val < MIN) val = MIN;
        this = val;
    }

    @:op(A*B)
    public inline function multiply(val:AudioSampleData):AudioSample
    {
        return new AudioSample(this * val);
    }

    @:op(A+B)
    public inline function add(val:AudioSampleData):AudioSample
    {
        return new AudioSample(this + val);
    }

    @:op(A-B)
    public inline function subtract(val:AudioSampleData):AudioSample
    {
        return new AudioSample(this - val);
    }
}
