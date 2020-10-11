package grig.audio;

#if (js && !nodejs && !heaps)
typedef AudioChannelData = js.lib.Float32Array;
#elseif cpp
import haxe.ds.Vector;
typedef AudioChannelData = haxe.ds.Vector<cpp.Float32>;
#else
typedef AudioChannelData = haxe.io.Float32Array;
#end