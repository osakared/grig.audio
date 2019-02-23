package grig.audio.js;

import grig.audio.AudioBuffer;
import grig.audio.AudioCallback;
import grig.audio.AudioChannel;
import haxe.extern.EitherType;
import haxe.io.Float32Array;
import js.node.buffer.Buffer;
import js.node.stream.Duplex;
import tink.core.Error;
import tink.core.Future;
import tink.core.Outcome;

typedef PortAudioPortInfo = {
    id:Int,
    name:String,
    maxInputChannels:Int,
    maxOutputChannels:Int,
    defaultSampleRate:Int,
    defaultLowInputLatency:Float,
    defaultLowOutputLatency:Float,
    defaultHighInputLatency:Float,
    defaultHighOutputLatency:Float,
    hostAPIName:String,
}

typedef HostAPIInfo = {
    defaultHostAPI:Int,
    HostAPIs:Array<PortAudioAPIInfo>
}

typedef PortAudioAPIInfo = {
    id:Int,
    name:String,
    type:String,
    deviceCount:Int,
    defaultInput:Int,
    defaultOutput:Int
}

@:jsRequire('naudiodon')
extern class PortAudio
{
    public static function getDevices():Array<PortAudioPortInfo>;
    public static function getHostAPIs():HostAPIInfo;
    public static var SampleFormat8Bit:Int;
    public static var SampleFormat16Bit:Int;
    public static var SampleFormat24Bit:Int;
    public static var SampleFormat32Bit:Int;
}

typedef AudioIOSubOptions = {
    channelCount:Int,
    sampleFormat:Int,
    sampleRate:Int,
    deviceId:Int
}

typedef AudioIOOptions = {
    @:optional var inOptions:AudioIOSubOptions;
    @:optional var outOptions:AudioIOSubOptions;
};

@:jsRequire('naudiodon', 'AudioIO')
extern class AudioIO extends Duplex<AudioIO>
{
    public function new(options:AudioIOOptions);
    public function start():Void;
    public function quit():Void;
}

class AudioInterface
{
    public var isOpen(default, null):Bool;
    public var audioCallback(default, null):AudioCallback;
    private var api:grig.audio.Api;
    private static var maxInt32:Int = 2147483647;
    private var audioInput:AudioIO;
    private var audioOutput:AudioIO;

    private var inputNumChannels:Int;
    private var outputNumChannels:Int;
    private var sampleRate:Float;
    private var inputPort:Null<Int>;
    private var outputPort:Null<Int>;

    private var inputBuffer:AudioBuffer;
    private var outputBuffer:AudioBuffer;

    public function new(_api:grig.audio.Api = grig.audio.Api.Unspecified)
    {
        api = _api;
        if (api == grig.audio.Api.Unspecified) {
            var hostAPIInfo = PortAudio.getHostAPIs();
            var apiInfo = hostAPIInfo.HostAPIs[hostAPIInfo.defaultHostAPI];
            api = grig.audio.PortAudioHelper.apiFromName(apiInfo.name);
        }
    }

    public static function getApis():Array<grig.audio.Api>
    {
        var apis = new Array<grig.audio.Api>();
        var apiInfos = PortAudio.getHostAPIs().HostAPIs;
        for (apiInfo in apiInfos) {
            var api = grig.audio.PortAudioHelper.apiFromName(apiInfo.name);
            apis.push(api);
        }
        return apis;
    }

    public function getPorts():Array<PortInfo>
    {
        var ports = new Array<PortInfo>();
        var devices = PortAudio.getDevices();
        var apiName = grig.audio.PortAudioHelper.nameFromApi(api);
        var apiInfos = PortAudio.getHostAPIs().HostAPIs;
        var defaultInput = 0;
        var defaultOutput = 0;
        for (apiInfo in apiInfos) {
            if (apiInfo.name == apiName) {
                defaultInput = apiInfo.defaultInput;
                defaultOutput = apiInfo.defaultOutput;
                break;
            }
        }
        for (device in devices) {
            if (device.hostAPIName != apiName) continue;
            var portInfo:PortInfo = {
                portID: device.id,
                portName: device.name,
                maxInputChannels: device.maxInputChannels,
                maxOutputChannels: device.maxOutputChannels,
                defaultSampleRate: device.defaultSampleRate,
                isDefaultInput: device.id == defaultInput,
                isDefaultOutput: device.id == defaultOutput,
                defaultLowInputLatency: device.defaultLowInputLatency,
                defaultLowOutputLatency: device.defaultLowOutputLatency,
                defaultHighInputLatency: device.defaultHighInputLatency,
                defaultHighOutputLatency: device.defaultHighOutputLatency,
                sampleRates: [device.defaultSampleRate],
            };
            ports.push(portInfo);
        }
        return ports;
    }

    private function respondToInput(chunk:Buffer)
    {
        var arrayLength = Std.int(chunk.length / 4);
        if (inputNumChannels > 0) {
            var channelLength = Std.int(arrayLength / inputNumChannels);
            if (inputBuffer == null) {
                var inputChannels = new Array<AudioChannel>();
                for (i in 0...inputNumChannels) {
                    inputChannels.push(new AudioChannel(new Float32Array(channelLength)));
                }
                inputBuffer = new AudioBuffer(inputChannels, sampleRate);
            }
            else {
                for (i in 0...inputNumChannels) {
                    if (inputBuffer.channels[i].length != channelLength) {
                        inputBuffer.channels[i] = new AudioChannel(new Float32Array(channelLength));
                    }
                }
            }
            for (i in 0...arrayLength) {
                inputBuffer.channels[i % inputNumChannels][Std.int(i / inputNumChannels)] = chunk.readInt32LE(i * 4) / maxInt32;
            }
        }
        else if (inputBuffer == null) {
            inputBuffer = new AudioBuffer(new Array<AudioChannel>(), sampleRate);
        }

        // if (outputNumChannels > 0) {
        //     var channelLength = arrayLength > 0 ? arrayLength : 
        // }
        trace(arrayLength);

        audioOutput.write(chunk);
    }

    private function processOptions(options:AudioInterfaceOptions)
    {
        if (options.inputNumChannels != null) inputNumChannels = options.inputNumChannels;
        else inputNumChannels = 0;
        if (options.outputNumChannels != null) outputNumChannels = options.outputNumChannels;
        else outputNumChannels = 2;
        if (options.sampleRate != null) sampleRate = options.sampleRate;
        else sampleRate = 44100.0;
        inputPort = options.inputPort;
        outputPort = options.outputPort;
    }

    public function openPort(options:AudioInterfaceOptions):Surprise<AudioInterface, tink.core.Error>
    {
        return Future.async(function(_callback) {
            try {
                if (isOpen) throw 'Already opened port';
                processOptions(options);
                var audioIOOptions:AudioIOOptions = {};
                if (inputPort != null) {
                    audioInput = new AudioIO({inOptions: {
                        channelCount: 2,//inputNumChannels,
                        sampleFormat: PortAudio.SampleFormat32Bit,
                        sampleRate: Std.int(sampleRate),
                        deviceId: 0//inputPort
                    }});
                }
                if (outputPort != null) {
                    audioOutput = new AudioIO({outOptions: {
                        channelCount: 2,//outputNumChannels,
                        sampleFormat: PortAudio.SampleFormat32Bit,
                        sampleRate: Std.int(sampleRate),
                        deviceId: 0//outputPort
                    }});
                }

                // var transform = new AudioTransformStream();
                // audioInput.pipe(transform).pipe(audioOutput);
                audioInput.once('data', function() { audioOutput.start(); });
                audioInput.start();
                // audioIO.pipe(transform).pipe(audioIO);
                // transform.pipe(audioIO).pipe(transform);
                // audioIO.pipe(audioIO);

                // var emptyChunk = new Buffer(8192);
                // audioIO.write(emptyChunk);
                // audioIO.write(emptyChunk);

                audioInput.on('data', respondToInput);
                // audioIO.start();

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
        audioInput.quit();
        audioOutput.quit();
        isOpen = false;
        inputBuffer = null;
        audioInput = audioOutput = null;
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