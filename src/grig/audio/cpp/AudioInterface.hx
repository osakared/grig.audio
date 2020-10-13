package grig.audio.cpp; #if cpp

import cpp.vm.Gc;
import grig.audio.AudioBuffer;
import grig.audio.ChannelsAudioBuffer;
import grig.audio.InterleavedAudioBuffer;
import tink.core.Error;
import tink.core.Future;
import tink.core.Outcome;

typedef PAStream = cpp.RawPointer<cpp.Void>;

extern class PortAudio
{
    @:native("Pa_Initialize")
    static public function initialize():Int;
    @:native("Pa_Terminate")
    static public function terminate():Int;
    @:native("get_api_strings")
    static public function getApiStrings():Array<String>;
    @:native("get_port_infos")
    static public function getPortInfos(api:String):Array<PortInfo>;
    @:native("open_port")
    static public function openPort(audioInterface:AudioInterface, options:AudioInterfaceOptions, stream:cpp.RawPointer<PAStream>, errors:Array<String>):Void;
}

@:build(grig.audio.cpp.Build.xml())
@:cppInclude('./portaudio.cc')
class AudioInterface
{
    private var api:grig.audio.Api;
    public var isOpen(default, null):Bool;
    private var audioCallback:AudioCallback = null;
    private var stream:PAStream;
    
    // Variables to be used only in audio thread
    private var inputBuffer:AudioBuffer;
    private var outputBuffer:AudioBuffer;
    private var streamInfo = new grig.audio.AudioStreamInfo();

    private static function onDestruct(audioInterface:AudioInterface)
    {
        PortAudio.terminate();
    }

    public function callAudioCallback()
    {
        if (audioCallback == null) return;

        audioCallback(inputBuffer, outputBuffer, inputBuffer.sampleRate, streamInfo);
    }

    public function new(api:grig.audio.Api = grig.audio.Api.Unspecified)
    {
        this.api = api;
        PortAudio.initialize();
        Gc.setFinalizer(this, cpp.Function.fromStaticFunction(onDestruct));
    }

    public static function getApis():Array<grig.audio.Api>
    {
        var apis = new Array<grig.audio.Api>();
        for (str in PortAudio.getApiStrings()) {
            apis.push(grig.audio.PortAudioHelper.apiFromName(str));
        }
        return apis;
    }

    public function getPorts():Array<PortInfo>
    {
        var apiName = grig.audio.PortAudioHelper.nameFromApi(api);
        return PortAudio.getPortInfos(apiName);
    }

    private function processOptions(options:AudioInterfaceOptions)
    {
        if (options.inputNumChannels == null) options.inputNumChannels = 0;
        if (options.outputNumChannels == null) options.outputNumChannels = 2;
        if (options.sampleRate == null) options.sampleRate = 44100.0;
        if (options.bufferSize == null) options.bufferSize = 256;
        if (options.inputLatency == null) options.inputLatency = 0.01;
        if (options.outputLatency == null) options.outputLatency = 0.01;
        if (options.interleaved == null) options.interleaved = false;

        if (options.interleaved) {
            inputBuffer = InterleavedAudioBuffer.create(options.inputNumChannels, 0, options.sampleRate);
            outputBuffer = InterleavedAudioBuffer.create(options.outputNumChannels, 0, options.sampleRate);
        }
        else {
            inputBuffer = ChannelsAudioBuffer.create(options.inputNumChannels, 0, options.sampleRate);
            outputBuffer = ChannelsAudioBuffer.create(options.outputNumChannels, 0, options.sampleRate);
        }
    }

    public function openPort(options:AudioInterfaceOptions):Surprise<AudioInterface, tink.core.Error>
    {
        var errors = new Array<String>();
        processOptions(options);
        PortAudio.openPort(this, options, cpp.RawPointer.addressOf(stream), errors);
        if (errors.length > 0) {
            var errorString = errors.join('\n');
            return Future.sync(Failure(new Error(InternalError, 'Open port error: $errorString')));
        }
        return Future.sync(Success(this));
    }

    public function closePort():Void
    {
    }

    public function setCallback(audioCallback:AudioCallback):Void
    {
        this.audioCallback = audioCallback;
    }

    public function cancelCallback():Void
    {
        audioCallback = null;
    }
}

#end