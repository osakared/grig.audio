package grig.audio;

import tink.core.Future;

#if (heaps && !disable_heaps_audio_interface)
typedef AudioInterface = NativeChannelAudioInterface;
#elseif (js && !nodejs && !disable_webaudio_audio_interface)
typedef AudioInterface = grig.audio.js.webaudio.AudioInterface;
#elseif (cpp && !disable_pa_audio_interface)
typedef AudioInterface = grig.audio.cpp.PAAudioInterface;
#elseif (python && !disable_python_audio_interface)
typedef AudioInterface = grig.audio.python.AudioInterface;
#else

/**
 * Generic AudioInterface that abstracts over different apis depending on the target.
 * See [grig's website](https://grig.tech/audio-connection) for a tutorial on basic use.
 */
extern class AudioInterface
{
    public var isOpen(default, null):Bool;

    public function new(api:grig.audio.Api = grig.audio.Api.Unspecified);
    public static function getApis():Array<grig.audio.Api>;
    public function getPorts():Array<PortInfo>;
    public function openPort(options:AudioInterfaceOptions):Surprise<AudioInterface, tink.core.Error>;
    public function closePort():Void;
    public function setCallback(_audioCallback:AudioCallback):Void;
    public function cancelCallback():Void;
}

#end
