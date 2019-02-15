package grig.audio;

typedef PortInfo =
{
    // var isDefault:Bool;
	var portID:Int;
    var portName:String;
    var isDefaultInput:Bool;
    var isDefaultOutput:Bool;
    var maxInputChannels:Int;
    var maxOutputChannels:Int;
    var defaultSampleRate:Float;
    // It would be great to have all supported sample rates too...
    // var defaultLatency:Float;
}