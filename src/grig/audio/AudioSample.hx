package grig.audio;

#if cpp
typedef AudioSample = cpp.Float32;
#else
typedef AudioSample = Float;
#end