package grig.audio;

typedef AudioCallback = (input:AudioBuffer, output:AudioBuffer, sampleRate:Float, audioStreamInfo:AudioStreamInfo)->Void;
