package grig.audio; #if heaps

import grig.audio.AudioChannel;
import hxd.snd.NativeChannel;
import hxd.snd.Manager;
import tink.core.Error;
import tink.core.Future;
import tink.core.Outcome;

class CallbackNativeChannel extends NativeChannel
{
    private var audioInterface:NativeChannelAudioInterface;

    override function onSample(buf:haxe.io.Float32Array)
    {
        audioInterface.audioCallback(new AudioBuffer([], audioInterface.sampleRate), new AudioBuffer([new AudioChannel(buf)], audioInterface.sampleRate));
    }

    public function new(bufferSize:Int, _audioInterface:NativeChannelAudioInterface)
    {
        audioInterface = _audioInterface;
        super(bufferSize);
    }
}

class NativeChannelAudioInterface
{
    public var audioCallback(default, null):AudioCallback;
    public var sampleRate(default, null):Float;

    public function new(api:grig.audio.Api = grig.audio.Api.Unspecified)
    {
        if (api != grig.audio.Api.Unspecified) {
            throw new Error(InternalError, 'In NativeChannel interface, specifying api not supported');
        }

        // Surely there's a better way to get the current sample rate than this...
        #if (!usesys && !hlopenal)
        sampleRate = hxd.snd.openal.Emulator.NATIVE_FREQ;
        #else
        sampleRate = hxd.snd.Data.samplingRate;
        #end
    }

    public static function getApis():Array<Api>
    {
        return [];
    }

    private function fillMissingOptions(options:AudioInterfaceOptions)
    {
        if (options.latencySamples == null) options.latencySamples = 256;
        if (options.inputNumChannels > 0) throw 'No input support in NativeChannelAudioInterface';
        if (options.outputNumChannels > 1) throw 'Only support for one channel in NativeChannelAudioInterface';
    }

    public function openPort(options:AudioInterfaceOptions):Surprise<AudioInterface, tink.core.Error>
    {
        return Future.async(function(_callback) {
            try {
                fillMissingOptions(options);
                var nativeChannel = new CallbackNativeChannel(options.latencySamples, this);
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