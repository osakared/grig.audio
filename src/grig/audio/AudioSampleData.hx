package grig.audio;

#if cpp
typedef AudioSampleData = cpp.Float32;
#else
typedef AudioSampleData = Float;
#end