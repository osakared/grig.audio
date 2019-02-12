package grig.audio.js.webaudio; #if (js && !nodejs)

import grig.audio.AudioCallback;
import js.html.audio.AudioContext;
import js.html.audio.AudioNode;
import js.html.audio.AudioProcessingEvent;
import js.html.audio.MediaStreamAudioSourceNode;
import js.html.audio.ScriptProcessorNode;
import tink.core.Error;
import tink.core.Future;
import tink.core.Outcome;

typedef WorkletPorts = Array<Array<js.html.Float32Array>>;

// class CallbackProcessor extends js.html.audio.AudioWorkletProcessor // Will this fail at runtime upon declaration or instantiation if worklet interface is missing?
// {
//     private var audioInterface:AudioInterface;

//     public function process(input:WorkletPorts, output:WorkletPorts, params:Dynamic):Bool
//     {
//         trace('a');
//         return true;
//     }

//     public function new(_audioInterface:AudioInterface)
//     {
//         audioInterface = _audioInterface;
//         super();
//     }
// }

class AudioInterface
{
    private var audioCallback:AudioCallback;
    public var audioContext(default, null):AudioContext;

    private function handleAudioEvent(event:AudioProcessingEvent)
    {
        if (audioCallback != null) {
            audioCallback(new AudioBuffer(event.inputBuffer), new AudioBuffer(event.outputBuffer));
        }
    }

    public function new(api:grig.audio.Api = grig.audio.Api.Unspecified)
    {
        if (api != grig.audio.Api.Unspecified && api != grig.audio.Api.Browser) {
            throw new Error(InternalError, 'In webaudio, only "Browser" api supported');
        }

        audioContext = new AudioContext();
    }

    public static function getApis():Array<Api>
    {
        return [Api.Browser];
    }

    private function requestAudioAccess(options:AudioInterfaceOptions):js.Promise<Null<MediaStreamAudioSourceNode>>
    {
        if (options.inputNumChannels == 0) {
            return js.Promise.resolve(null);
        }
        var promise:js.Promise<js.html.MediaStream> = js.Syntax.code('navigator.mediaDevices.getUserMedia({audio:true})');
        return promise.then(function(mediaStream:js.html.MediaStream) {
            return js.Promise.resolve(audioContext.createMediaStreamSource(mediaStream));
        }).catchError(function(e:js.Error) {
            return js.Promise.reject(e);
        });
    }

    private function fillMissingOptions(options:AudioInterfaceOptions)
    {
        if (options.inputNumChannels == null) options.inputNumChannels = 0; // default to not asking for mic access
        if (options.outputNumChannels == null) options.outputNumChannels = audioContext.destination.channelCount;
        if (options.latencySamples == null) options.latencySamples = 0; // 0 signifies let browser choose for me
    }

    public function openPort(options:AudioInterfaceOptions):Surprise<AudioInterface, tink.core.Error>
    {
        return Future.async(function(_callback) {
            try {
                fillMissingOptions(options);
                if (options.outputNumChannels > audioContext.destination.channelCount) {
                    _callback(Failure(new Error(InternalError, 'Unsupported number of output channels: ${options.outputNumChannels}')));
                }
                requestAudioAccess(options).then(function(inputNode:Null<MediaStreamAudioSourceNode>) {
                    if (inputNode != null) {
                        if (options.inputNumChannels > inputNode.channelCount) {
                            _callback(Failure(new Error(InternalError, 'Unsupported number of input channels: ${options.inputNumChannels}')));
                        }
                    }
                    // Try to create AudioWorklet, fall back to ScriptProcessor on DOMError
                    var node = audioContext.createScriptProcessor(options.latencySamples, options.inputNumChannels, options.outputNumChannels);
                    node.connect(audioContext.destination);
                    node.onaudioprocess = handleAudioEvent;
                    if (inputNode != null) inputNode.connect(node);

                    _callback(Success(this));
                }).catchError(function(e:js.Error) {
                    _callback(Failure(new Error(InternalError, e.message)));
                });
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