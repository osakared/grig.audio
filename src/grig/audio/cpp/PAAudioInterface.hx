package grig.audio.cpp; #if cpp

import cpp.vm.Gc;
import grig.audio.AudioBuffer;
import grig.audio.AudioCallback;
import grig.audio.AudioChannel;
import grig.audio.AudioTime;
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
    public var hostApiSpecificStreamInfo:cpp.RawPointer<cpp.Void>;
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

// We need exactly this and not an approximation
@:native('unsigned long')
extern class ULong {}

typedef PACallback = cpp.Callable<(input:cpp.RawConstPointer<cpp.Void>, output:cpp.RawPointer<cpp.Void>, frameCount:ULong,
                                   timeInfo:PaStreamCallbackTimeInfo, statusFlags:ULong, userData:cpp.RawPointer<cpp.Void>)->Int>;

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
    @:native("Pa_IsFormatSupported")
    static public function isFormatSupported(inputParams:PaStreamParameters, outputParams:PaStreamParameters,
                                             sampleRate:cpp.Float64):Int;
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
    private var bufferSize:Int;
    private var inputPort:Null<Int>;
    private var outputPort:Null<Int>;
    private var inputLatency:Float;
    private var outputLatency:Float;

    // Can't seem to reliably pass around a pointer to a PAAudioInterface_obj, so index into here it is!
    static private var audioInterfaces:Array<PAAudioInterface> = new Array<PAAudioInterface>();
    private var audioInterfaceIndex:cpp.UInt64;

    private static var inputUnderflowFlag:Int = untyped __cpp__('paInputUnderflow');
    private static var inputOverflowFlag:Int = untyped __cpp__('paInputOverflow');
    private static var outputUnderflowFlag:Int = untyped __cpp__('paOutputUnderflow');
    private static var outputOverflowFlag:Int = untyped __cpp__('paOutputOverflow');
    private static var primingOutputFlag:Int = untyped __cpp__('paPrimingOutput');

    private var m = new sys.thread.Mutex();
    private var outputBuffer:AudioBuffer;
    private var inputBuffer:AudioBuffer;
    private var streamInfo = new grig.audio.AudioStreamInfo();

    private static function handleAudioEvent(input:cpp.RawConstPointer<cpp.Void>, output:cpp.RawPointer<cpp.Void>, frameCountLong:ULong,
                                             timeInfo:PaStreamCallbackTimeInfo, statusFlagsLong:ULong, userData:cpp.RawPointer<cpp.Void>):Int
    {
        var frameCount:cpp.UInt64 = untyped __cpp__('{0}', frameCountLong);
        var interfaceIndex:cpp.UInt64 = untyped __cpp__('(unsigned long)userData');
        var audioInterface = audioInterfaces[interfaceIndex];
        if (audioInterface.audioCallback == null) return 0;
        if (!audioInterface.m.tryAcquire()) return 0;

        if (audioInterface.inputBuffer == null) {
            var inputChannels = new Array<AudioChannel>();
            for (i in 0...audioInterface.inputNumChannels) {
                inputChannels.push(new AudioChannel(new AudioChannelData(frameCount)));
            }
            audioInterface.inputBuffer = new AudioBuffer(inputChannels, audioInterface.sampleRate);
        }
        // TODO use memcpy instead to make faster
        untyped __cpp__('float **inputChannels = (float**)input');
        for (c in 0...audioInterface.inputNumChannels) {
            for (i in 0...frameCount) {
                audioInterface.inputBuffer.channels[c][i] = untyped __cpp__('inputChannels[{0}][{1}]', c, i);
            }
        }

        if (audioInterface.outputBuffer == null) {
            var outputChannels = new Array<AudioChannel>();
            for (i in 0...audioInterface.outputNumChannels) {
                outputChannels.push(new AudioChannel(new AudioChannelData(frameCount)));
            }
            audioInterface.outputBuffer = new AudioBuffer(outputChannels, audioInterface.sampleRate);
        }
        for (i in 0...audioInterface.outputNumChannels) {
            if (audioInterface.outputBuffer.channels[i].length != frameCount) {
                audioInterface.outputBuffer.channels[i] = new AudioChannel(new AudioChannelData(frameCount));
            }
            else break; // Assuming they're all the same length
        }
        audioInterface.outputBuffer.clear();

        var statusFlags:cpp.UInt64 = untyped __cpp__('{0}', statusFlagsLong);
        audioInterface.streamInfo.inputUnderflow = statusFlags & inputUnderflowFlag != 0;
        audioInterface.streamInfo.inputOverflow = statusFlags & inputOverflowFlag != 0;
        audioInterface.streamInfo.outputUnderflow = statusFlags & outputUnderflowFlag != 0;
        audioInterface.streamInfo.outputOverflow = statusFlags & outputOverflowFlag != 0;
        audioInterface.streamInfo.primingOutput = statusFlags & primingOutputFlag != 0;
        audioInterface.streamInfo.inputTime = new AudioTime(timeInfo.inputBufferAdcTime);
        audioInterface.streamInfo.outputTime = new AudioTime(timeInfo.outputBufferDacTime);
        audioInterface.streamInfo.callbackTime = new AudioTime(timeInfo.currentTime);

        audioInterface.audioCallback(audioInterface.inputBuffer, audioInterface.outputBuffer, audioInterface.sampleRate, audioInterface.streamInfo);

        untyped __cpp__('float **outputChannels = (float**)output');
        // TODO use memcpy instead to make faster
        var channel;
        var val;
        for (c in 0...audioInterface.outputNumChannels) {
            channel = audioInterface.outputBuffer.channels[c];
            for (i in 0...frameCount) {
                val = channel[i];
                untyped __cpp__('outputChannels[{0}][{1}] = {2}', c, i, val);
            }
        }
        
        audioInterface.m.release();
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
            apis.push(grig.audio.PortAudioHelper.apiFromName(apiInfo.name));
        }
        return apis;
    }

    private function addSampleRatesToPortInfo(portInfo:PortInfo):Void
    {
        var inputParameters:PaStreamParameters = untyped __cpp__('nullptr');
        var outputParameters:PaStreamParameters = untyped __cpp__('nullptr');

        var sampleFormat:cpp.SizeT = untyped __cpp__('paFloat32 | paNonInterleaved');
        // Base our estimate on full duplex (if available), all channels
        if (portInfo.maxInputChannels > 0) {
            inputParameters = untyped __cpp__('new PaStreamParameters');
            inputParameters.device = portInfo.portID;
            inputParameters.channelCount = portInfo.maxInputChannels;
            inputParameters.sampleFormat = sampleFormat;
            inputParameters.suggestedLatency = portInfo.defaultLowInputLatency;
            inputParameters.hostApiSpecificStreamInfo = untyped __cpp__('nullptr');
        }
        if (portInfo.maxOutputChannels > 0) {
            outputParameters = untyped __cpp__('new PaStreamParameters');
            outputParameters.device = portInfo.portID;
            outputParameters.channelCount = portInfo.maxOutputChannels;
            outputParameters.sampleFormat = sampleFormat;
            outputParameters.suggestedLatency = portInfo.defaultLowOutputLatency;
            outputParameters.hostApiSpecificStreamInfo = untyped __cpp__('nullptr');
        }

        // This is kind of brain dead because I'd rather not assume just because a given sampleRate
        // is higher than the default but not supported, that yet higher sampleRates aren't (for example)
        // This also doesn't know what's native vs. what's just being resampled by the driver or sth
        for (sampleRate in grig.audio.SampleRate.commonSampleRates) {
            var ret = PortAudio.isFormatSupported(inputParameters, outputParameters, sampleRate);
            if (ret == 0) portInfo.sampleRates.push(sampleRate);
        }

        untyped __cpp__('delete {0}; delete {1};', inputParameters, outputParameters);
    }

    public function getPorts():Array<PortInfo>
    {
        var portInfos = new Array<PortInfo>();
        var apiInfos = getApiInfos();
        var apiName = grig.audio.PortAudioHelper.nameFromApi(api);
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
                        defaultLowInputLatency: deviceInfo.defaultLowInputLatency,
                        defaultLowOutputLatency: deviceInfo.defaultLowOutputLatency,
                        defaultHighInputLatency: deviceInfo.defaultHighInputLatency,
                        defaultHighOutputLatency: deviceInfo.defaultHighOutputLatency,
                        sampleRates: new Array<Float>(),
                    };
                    addSampleRatesToPortInfo(portInfo);
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
        if (options.bufferSize != null) bufferSize = options.bufferSize;
        else bufferSize = 256;
        if (options.inputLatency != null) inputLatency = options.inputLatency;
        else inputLatency = 0.01;
        if (options.outputLatency != null) outputLatency = options.outputLatency;
        else outputLatency = 0.01;
        inputPort = options.inputPort;
        outputPort = options.outputPort;
    }

    public function openPort(options:AudioInterfaceOptions):Surprise<AudioInterface, tink.core.Error>
    {
        return Future.async(function(_callback) {
            var inputParameters:PaStreamParameters = untyped __cpp__('nullptr');
            var outputParameters:PaStreamParameters = untyped __cpp__('nullptr');
            // I can't just make this a static because the haxe compiler does something whacky that tries to pass this through a Dynamic, which fails to compile in C++
            var sampleFormat:cpp.SizeT = untyped __cpp__('paFloat32 | paNonInterleaved');
            try {
                if (isOpen) throw 'Already opened port';
                processOptions(options);
                if (inputPort != null) {
                    inputParameters = untyped __cpp__('new PaStreamParameters');
                    inputParameters.device = inputPort;
                    inputParameters.channelCount = inputNumChannels;
                    inputParameters.sampleFormat = sampleFormat;
                    inputParameters.suggestedLatency = inputLatency;
                    inputParameters.hostApiSpecificStreamInfo = untyped __cpp__('nullptr');
                }
                if (outputPort != null) {
                    outputParameters = untyped __cpp__('new PaStreamParameters');
                    outputParameters.device = outputPort;
                    outputParameters.channelCount = outputNumChannels;
                    outputParameters.sampleFormat = sampleFormat;
                    outputParameters.suggestedLatency = outputLatency;
                    outputParameters.hostApiSpecificStreamInfo = untyped __cpp__('nullptr');
                }
                var ret = PortAudio.openStream(cpp.RawPointer.addressOf(stream), inputParameters, outputParameters,
                                               sampleRate, bufferSize, 0,
                                               cpp.Function.fromStaticFunction(handleAudioEvent), untyped __cpp__('(void*){0}', audioInterfaceIndex));
                checkError(ret);
                ret = PortAudio.startStream(stream);
                checkError(ret);
                isOpen = true;
                untyped __cpp__('delete {0}; delete {1};', inputParameters, outputParameters);
                _callback(Success(this));
            }
            catch (error:Error) {
                untyped __cpp__('delete {0}; delete {1};', inputParameters, outputParameters);
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