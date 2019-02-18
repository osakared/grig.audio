package grig.audio.python.numpy; #if python

import python.Tuple;

@:pythonImport("numpy")
extern class Numpy
{
    static public function frombuffer(buffer:python.Bytes, kwargs:python.KwArgs<Dynamic>):Ndarray;
    static public function zeros(shape:python.Tuple2<Int, Int>):Ndarray;
    static public function dstack(tup:Dynamic):Ndarray;
    static public var float32:Int;
}

#end