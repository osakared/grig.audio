package grig.audio;

#if (js && !nodejs)
typedef AudioBuffer = js.html.audio.AudioBuffer;
#else

class AudioBuffer
{
    public var sampleRate(default, null):Float;
}

#end