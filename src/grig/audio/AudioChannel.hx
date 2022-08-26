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

    /** Set all values in the signal to `value` **/
    public function setAll(value:T) {
        for (i in 0...this.length) {
            this[i] = value;
        }
    }

    /** Resets the buffer to silence (all `0.0`) **/
    public function clear() {
        #if cpp
        cpp.NativeArray.zero(cast this, 0, this.length);
        #else
        this.setAll(0);
        #end
    }
}