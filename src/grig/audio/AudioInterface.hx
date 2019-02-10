package grig.audio;

#if heaps
typedef AudioInterface = Int;
#elseif (js && !nodejs)
typedef AudioInterface = grig.audio.js.webaudio.AudioInterface;
#elseif cpp
#else

extern class AudioInterface
{
    public function new(api:grig.audio.Api = grig.audio.Api.Undefined);
    public static function getApis():Array<grig.audio.Api>;
}

#end