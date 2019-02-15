package grig.audio.cpp; #if cpp

import cpp.vm.Gc;
import grig.audio.AudioBuffer;
import grig.audio.AudioCallback;
import grig.audio.AudioChannel;
import grig.audio.PortInfo;
import haxe.ds.Vector;
import tink.core.Error;
import tink.core.Future;
import tink.core.Outcome;

using cpp.NativeArray;

@:build(grig.audio.cpp.PABuild.xml())
@:include('./portaudio/portaudio/include/portaudio.h')

@:native('const PaHostApiInfo*')
extern class PaHostApiInfo
{
    // Just listing the fields we care about here
    public var structVersion:Int;
    public var name:cpp.StdStringRef;
    public var deviceCount:Int;
    public var defaultInputDevice:Int;
    public var defaultOutputDevice:Int;
}

class HostApiInfo // Feels a bit redundant, but difficult to coax externs to behave like haxe classes
{
    public var name:String;
    public var deviceCount:Int;
    public var defaultInputDevice:Int;
    public var defaultOutputDevice:Int;
    public var hostApiIndex:Int;

    public function new()
    {
    }
}

@:native('PaStreamParameters*')
extern class PaStreamParameters
{
    public var device:Int;
    public var channelCount:Int;
    public var sampleFormat:cpp.SizeT;
    public var suggestedLatency:cpp.Float64;
}

typedef PaStream = cpp.RawPointer<cpp.Void>;

@:native('const PaStreamCallbackTimeInfo*')
extern class PaStreamCallbackTimeInfo
{
    public var inputBufferAdcTime:cpp.Float64;
    public var currentTime:cpp.Float64;
    public var outputBufferDacTime:cpp.Float64;
}

@:native('const PaDeviceInfo*')
extern class PaDeviceInfo
{
    public var structVersion:Int;
    public var name:cpp.StdStringRef;
    public var maxInputChannels:Int;
    public var maxOutputChannels:Int;
    public var defaultLowInputLatency:cpp.Float64;
    public var defaultLowOutputLatency:cpp.Float64;
    public var defaultHighInputLatency:cpp.Float64;
    public var defaultHighOutputLatency:cpp.Float64;
    public var defaultSampleRate:cpp.Float64;
}

typedef PACallback = cpp.Callable<(input:cpp.RawConstPointer<cpp.Void>, output:cpp.RawPointer<cpp.Void>, frameCount:cpp.SizeT,
                                   timeInfo:PaStreamCallbackTimeInfo, statusFlags:cpp.SizeT, userData:cpp.RawPointer<cpp.Void>)->Int>;

extern class PortAudio
{
    @:native("Pa_Initialize")
    static public function initialize():Int;
    @:native("Pa_Terminate")
    static public function terminate():Int;
    @:native("Pa_GetErrorText")
    static public function getErrorText(errorCode:Int):cpp.StdStringRef;
    @:native("Pa_GetHostApiCount")
    static public function getHostApiCount():Int;
    @:native("Pa_GetHostApiInfo")
    static public function getHostApiInfo(api:Int):PaHostApiInfo;
    @:native("Pa_OpenDefaultStream")
    static public function openDefaultStream(stream:cpp.RawPointer<PaStream>, numInputChannels:Int, numOutputChannels:Int,
                                             sampleFormat:cpp.SizeT, sampleRate:cpp.Float64, framesPerBuffer:cpp.SizeT,
                                             callback:PACallback, userData:Dynamic):Int;
    @:native("Pa_OpenStream")
    static public function openStream(stream:cpp.RawPointer<PaStream>, inputParams:PaStreamParameters, outputParams:PaStreamParameters,
                                      sampleRate:cpp.Float64, framesPerBuffer:cpp.SizeT, streamFlags:cpp.SizeT,
                                      callback:PACallback, userData:Dynamic):Int;
    @:native("Pa_CloseStream")
    static public function closeStream(stream:PaStream):Int;
    @:native("Pa_HostApiDeviceIndexToDeviceIndex")
    static public function hostApiDeviceIndexToDeviceIndex(hostApi:Int, hostApiDeviceIndex:Int):Int;
    @:native("Pa_GetDeviceInfo")
    static public function getDeviceInfo(device:Int):PaDeviceInfo;
    @:native("Pa_StartStream")
    static public function startStream(stream:PaStream):Int;
}

@:headerCode('struct PaStreamCallbackTimeInfo;')

class PAAudioInterface
{
    public var audioCallback(default, null):AudioCallback;
    private static inline var structApiVersion:Int = 1;
    private var stream:PaStream;
    private var api:grig.audio.Api;
    public var isOpen(default, null):Bool = false;
    
    private var inputNumChannels:Int;
    private var outputNumChannels:Int;
    private var sampleRate:Float;
    private var latencySamples:Int;
    private var inputPort:Null<Int>;
    private var outputPort:Null<Int>;

    // Can't seem to reliably pass around a pointer to a PAAudioInterface_obj, so index into here it is!
    static private var audioInterfaces:Array<PAAudioInterface> = new Array<PAAudioInterface>();
    private var audioInterfaceIndex:cpp.UInt64;

    private static function handleAudioEvent(input:cpp.RawConstPointer<cpp.Void>, output:cpp.RawPointer<cpp.Void>, frameCount:cpp.SizeT,
                                             timeInfo:PaStreamCallbackTimeInfo, statusFlags:cpp.SizeT, userData:cpp.RawPointer<cpp.Void>):Int
    {
        var i:cpp.UInt64 = untyped __cpp__('(unsigned long)userData');
        var audioInterface = audioInterfaces[i];
        if (audioInterface.audioCallback == null) return 0;

        // God I hope I'm not creating too much overhead here
        var inputChannels = new Array<AudioChannel>();
        var inputConstFloat:cpp.RawConstPointer<cpp.RawPointer<cpp.Float32>> = untyped __cpp__('(const float**)input');
        for (i in 0...audioInterface.inputNumChannels) {
            var inputArray = cpp.NativeArray.create(0);
            var inputConstPointer:cpp.ConstPointer<cpp.Float32> = untyped __cpp__('::cpp::Pointer_obj::fromRaw(inputConstFloat[{0}])', i); //cpp.ConstPointer.fromRaw(inputConstFloat);
            inputArray.setUnmanagedData(inputConstPointer, frameCount);
            var inputVector = Vector.fromData(inputArray);
            inputChannels.push(new AudioChannel(inputVector));
        }
        var inputBuffer = new AudioBuffer(inputChannels, audioInterface.sampleRate);

        var outputChannels = new Array<AudioChannel>();
        var outputFloat:cpp.RawPointer<cpp.RawPointer<cpp.Float32>> = untyped __cpp__('(float**)output');
        for (i in 0...2) {
            var outputArray = cpp.NativeArray.create(0);
            var outputPointer:cpp.Pointer<cpp.Float32> = untyped __cpp__('::cpp::Pointer_obj::fromRaw(outputFloat[{0}])', i);
            outputArray.setUnmanagedData(outputPointer, frameCount);
            var outputVector = Vector.fromData(outputArray);
            outputChannels.push(new AudioChannel(outputVector));
        }
        var outputBuffer = new AudioBuffer(outputChannels, audioInterface.sampleRate);

        audioInterface.audioCallback(inputBuffer, outputBuffer);
        
        return 0;
    }

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

    private static function onDestruct(audioInterface:PAAudioInterface)
    {
        terminateApi();
    }

    public function new(_api:grig.audio.Api = grig.audio.Api.Unspecified)
    {
        initializeApi();
        Gc.setFinalizer(this, cpp.Function.fromStaticFunction(onDestruct));
        api = _api;
        audioInterfaceIndex = audioInterfaces.length;
        audioInterfaces.push(this);
    }

    private static var nameApiMapping = [
        'ALSA'                      => grig.audio.Api.Alsa,
        'ASIO'                      => grig.audio.Api.WindowsASIO,
        'Core Audio'                => grig.audio.Api.MacOSCore,
        'Windows DirectSound'       => grig.audio.Api.WindowsDS,
        'JACK Audio Connection Kit' => grig.audio.Api.Jack,
        'OSS'                       => grig.audio.Api.Oss,
        'Windows WASAPI'            => grig.audio.Api.WindowsWASAPI,
        'Windows WDM-KS'            => grig.audio.Api.WindowsWDMKS,
        'MME'                       => grig.audio.Api.WindowsMME,
        'Unspecified'               => grig.audio.Api.Unspecified,
    ];

    // This probably needs to be moved to some common place where all PA implementations can access
    private static function apiFromName(name:String):Api
    {
        if (nameApiMapping.exists(name)) return nameApiMapping[name];
        throw new Error(InternalError, 'Unknown api: $name');
    }

    private static function nameFromApi(api:Api):String
    {
        for (name in nameApiMapping.keys()) {
            if (nameApiMapping[name] == api) return name;
        }
        throw new Error(InternalError, 'Unknown api: $api');
    }

    private static function checkError(ret:Int):Void
    {
        if (ret != 0) {
            var errorString = PortAudio.getErrorText(ret);
            throw new Error(InternalError, 'PortAudio error code: ${errorString.toString()}');
        }
    }

    public static function getApiInfos():Array<HostApiInfo>
    {
        var apiInfos = new Array<HostApiInfo>();
        initializeApi();
        try {
            for (i in 0...PortAudio.getHostApiCount()) {
                var apiInfo = PortAudio.getHostApiInfo(i);
                if (apiInfo.structVersion != structApiVersion) {
                    throw new Error(InternalError, 'Incompatible PortAudio API Version: ${apiInfo.structVersion}');
                }
                var hostApiInfo = new HostApiInfo();
                var nameRef:cpp.StdStringRef = apiInfo.name;
                hostApiInfo.name = nameRef.toString();
                hostApiInfo.deviceCount = apiInfo.deviceCount;
                hostApiInfo.defaultInputDevice = apiInfo.defaultInputDevice;
                hostApiInfo.defaultOutputDevice = apiInfo.defaultOutputDevice;
                hostApiInfo.hostApiIndex = i;
                apiInfos.push(hostApiInfo);
            }
        }
        catch(e:Dynamic) { // This would be a great case for finally being part of haxe proper
            terminateApi();
            throw e;
        }
        terminateApi();
        return apiInfos;
    }

    public static function getApis():Array<grig.audio.Api>
    {
        var apis = new Array<grig.audio.Api>();
        var apiInfos = getApiInfos();
        for (apiInfo in apiInfos) {
            apis.push(apiFromName(apiInfo.name));
        }
        return apis;
    }

    public function getPorts():Array<PortInfo>
    {
        var portInfos = new Array<PortInfo>();
        var apiInfos = getApiInfos();
        var apiName = nameFromApi(api);
        for (apiInfo in apiInfos) {
            if (apiInfo.name == apiName || api == grig.audio.Api.Unspecified) {
                for (i in 0...apiInfo.deviceCount) {
                    var deviceIndex = PortAudio.hostApiDeviceIndexToDeviceIndex(apiInfo.hostApiIndex, i);
                    var deviceInfo = PortAudio.getDeviceInfo(deviceIndex);
                    var name = deviceInfo.name;
                    var portInfo:PortInfo = {
                        portID: deviceIndex,
                        portName: name.toString(),
                        maxInputChannels: deviceInfo.maxInputChannels,
                        maxOutputChannels: deviceInfo.maxOutputChannels,
                        defaultSampleRate: deviceInfo.defaultSampleRate,
                        isDefaultInput: deviceIndex == apiInfo.defaultInputDevice,
                        isDefaultOutput: deviceIndex == apiInfo.defaultOutputDevice,
                    };
                    portInfos.push(portInfo);
                }
                break;
            }
        }
        return portInfos;
    }

    private function processOptions(options:AudioInterfaceOptions)
    {
        if (options.inputNumChannels != null) inputNumChannels = options.inputNumChannels;
        else inputNumChannels = 0;
        if (options.outputNumChannels != null) outputNumChannels = options.outputNumChannels;
        else outputNumChannels = 2;
        if (options.sampleRate != null) sampleRate = options.sampleRate;
        else sampleRate = 44100.0;
        if (options.latencySamples != null) latencySamples = options.latencySamples;
        else latencySamples = 256;
        inputPort = options.inputPort;
        outputPort = options.outputPort;
    }

    public function openPort(options:AudioInterfaceOptions):Surprise<AudioInterface, tink.core.Error>
    {
        return Future.async(function(_callback) {
            try {
                if (isOpen) throw 'Already opened port';
                processOptions(options);
                var ret = PortAudio.openDefaultStream(cpp.RawPointer.addressOf(stream), inputNumChannels, outputNumChannels,
                                            untyped __cpp__('paFloat32 | paNonInterleaved'), sampleRate, latencySamples,
                                            cpp.Function.fromStaticFunction(handleAudioEvent), untyped __cpp__('(void*){0}', audioInterfaceIndex));
                checkError(ret);
                ret = PortAudio.startStream(stream);
                checkError(ret);
                isOpen = true;
                _callback(Success(this));
            }
            catch (error:Error) {
                _callback(Failure(new Error(InternalError, 'Failed to open port. ${error.message}')));
            }
        });
    }

    public function closePort():Void
    {
        if (!isOpen) return;
        checkError(PortAudio.closeStream(stream));
        isOpen = false;
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