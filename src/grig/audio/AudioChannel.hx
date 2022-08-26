package grig.audio;

import haxe.ds.Vector;

// typedef AudioChannel<T:Float> = Vector<T>;

@:forward
abstract AudioChannel<T:Float>(Vector<T>) from Vector<T> to Vector<T>
{
    public inline function new(length:Int) {
        this = new Vector<T>(length);
    }

    @:arrayAccess
    inline function get(index:Int):T {
        #if cpp
        return cpp.NativeArray.unsafeGet(cast this, index);
        #else
        return this[index];
        #end
    }

    @:arrayAccess
    inline function set(index:Int, sample:T):T {
        #if cpp
        return cpp.NativeArray.unsafeSet(cast this, index, sample);
        #else
        return this[index] = sample;
        #end
    }
}