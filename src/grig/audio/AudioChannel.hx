package grig.audio;

@:forward
abstract AudioChannel(AudioChannelImpl)
{
    public var length(get, never):Int;

    private inline function get_length():Int
    {
        return this.getLength();
    }

    public inline function new(channel:AudioChannelImpl)
    {
        this = channel;
    }

    @:arrayAccess
    inline function get(index:Int):AudioSample
    {
        return this.getSample(index);
    }

    @:arrayAccess
    inline function set(index:Int, sample:AudioSample):AudioSample
    {
        return this.setSample(index, sample);
    }
}