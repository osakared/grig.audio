package grig.audio.cpp; #if cpp

import grig.audio.AudioCallback;
import tink.core.Error;
import tink.core.Future;
import tink.core.Outcome;

@:build(grig.audio.cpp.PABuild.xml())
@:include('./portaudio/portaudio/include/portaudio.h')

@:native('const PaHostApiInfo*')
extern class PaHostApiInfo
{
    // Just listing the fields we care about here
    public var structVersion:Int;
    public var name:cpp.StdStringRef;
}

extern class PortAudio
{
    @:native("Pa_Initialize")
    static public function initialize():Int;
    @:native("Pa_Terminate")
    static public function terminate():Int;
    @:native("Pa_GetHostApiCount")
    static public function getHostApiCount():Int;
    @:native("Pa_GetHostApiInfo")
    static public function getHostApiInfo(api:Int):PaHostApiInfo;
}

class PAAudioInterface
{
    public var audioCallback(default, null):AudioCallback;
    private static inline var structApiVersion:Int = 1;

    public static function initializeApi():Void
    {
        var err = PortAudio.initialize(); // Need to call terminate as soon as this object is GC'd.
        if (err != 0) {
            throw new Error(InternalError, 'Failed initialization of portaudio: $err');
        }
    }

    public static function terminateApi():Void // Be careful calling this as a client!! You probably don't need to
    {
        var err = PortAudio.initialize(); // Need to call terminate as soon as this object is GC'd.
        if (err != 0) {
            throw new Error(InternalError, 'Failed initialization of portaudio: $err');
        }
    }

    public function new(api:grig.audio.Api = grig.audio.Api.Unspecified)
    {
        initializeApi(); // Somehow call terminate on destruct
    }

    // This probably needs to be moved to some common place where all PA implementations can access
    private static function apiFromName(name:String):Api
    {
        switch (name) { // This seems... brittle, what if PA changes the spacing of the names?
            case 'ALSA':                      return Alsa;
            case 'ASIO':                      return WindowsASIO;
            case 'Core Audio':                return MacOSCore;
            case 'Windows DirectSound':       return WindowsDS;
            case 'JACK Audio Connection Kit': return Jack;
            case 'OSS':                       return Oss;
            case 'Windows WASAPI':            return WindowsWASAPI;
            case 'Windows WDM-KS':            return WindowsWDMKS;
            case 'MME':                       return WindowsMME;
            default: throw new Error(InternalError, 'Unknown api: $name');
        }
    }

    public static function getApis():Array<grig.audio.Api>
    {
        var apis = new Array<grig.audio.Api>();
        initializeApi();
        try {
            for (i in 0...PortAudio.getHostApiCount()) {
                var apiInfo = PortAudio.getHostApiInfo(i);
                if (apiInfo.structVersion != structApiVersion) {
                    throw new Error(InternalError, 'Incompatible PortAudio API Version: ${apiInfo.structVersion}');
                }
                var name = apiInfo.name;
                apis.push(apiFromName(name.toString()));
            }
        }
        catch(e:Dynamic) { // This would be a great case for finally being part of haxe proper
            terminateApi();
            throw e;
        }
        terminateApi();
        return apis;
    }

    private function fillMissingOptions(options:AudioInterfaceOptions)
    {
    }

    public function openPort(options:AudioInterfaceOptions):Surprise<AudioInterface, tink.core.Error>
    {
        return Future.async(function(_callback) {
            try {
                _callback(Success(this));
            }
            catch (error:Error) {
                _callback(Failure(new Error(InternalError, 'Failed to open port. ${error.message}')));
            }
        });
    }

    public function setCallback(_audioCallback:AudioCallback):Void
    {
        audioCallback = _audioCallback;
    }

    public function cancelCallback():Void
    {
        audioCallback = null;
    }
}

#end