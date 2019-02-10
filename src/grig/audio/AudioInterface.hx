package grig.audio;

#if heaps // we need to override if making a plugin or if the user forces override
typedef AudioInterface = NativeChannelAudioInterface;
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