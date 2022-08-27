package;

import grig.audio.AudioInterface;
import grig.audio.LinearInterpolator;
import haxe.Timer;
import tink.core.Future;

using grig.audio.NumericTypes;
using grig.audio.AudioBufferTools;
using grig.audio.AudioChannelTools;

class Main
{
    private static function audioCallbackWithInput(input:grig.audio.AudioBuffer<Float32>, output:grig.audio.AudioBuffer<Float32>, sampleRate:Float, audioStreamInfo:grig.audio.AudioStreamInfo)
    {
        var ratio = 0.25;
        if (input.numChannels < 1) return;
        var interpolator = new LinearInterpolator<Float32>();
        interpolator.resampleIntoChannel(input[0], output[0], ratio);
        var length = Math.floor(output.numSamples * ratio);
        for (i in 1...Std.int(output.numSamples / length)) {
            output[0].copyFrom(output[0], length, 0, length * i);
        }
        for (c in 1...output.numChannels) {
            output[c].copyFrom(output[0], output.numSamples);
        }
    }

    private static function mainLoop(audioInterface:AudioInterface)
    {
        #if (sys && !nodejs)
        var stdout = Sys.stdout();
        var stdin = Sys.stdin();
        // Using Sys.getChar() unfortunately fucks up the output
        stdout.writeString('quit[enter] to quit\n');
        while (true) {
            var command = stdin.readLine();
            if (command.toLowerCase() == 'quit') {
                audioInterface.closePort();
                return;
            }
        }
        #end
    }

    static function main()
    {
        trace(AudioInterface.getApis());
        var audioInterface = new AudioInterface();
        var ports = audioInterface.getPorts();
        trace(ports);
        var options:grig.audio.AudioInterfaceOptions = {};
        for (port in ports) {
            if (port.isDefaultInput) {
                options.inputNumChannels = port.maxInputChannels;
                options.inputPort = port.portID;
                options.sampleRate = port.defaultSampleRate;
                options.inputLatency = port.defaultLowInputLatency;
            }
            if (port.isDefaultOutput) {
                options.outputNumChannels = port.maxOutputChannels;
                options.outputPort = port.portID;
                options.sampleRate = port.defaultSampleRate; // if input and output are different samplerates (would that happen?) then this code will fail
                options.outputLatency = port.defaultLowOutputLatency;
            }
        }
        if (options.inputPort != null) audioInterface.setCallback(audioCallbackWithInput);
        else throw "Audio input not available";
        audioInterface.openPort(options).handle(function(audioOutcome) {
            switch audioOutcome {
                case Success(_):
                    trace('Playing input through an effect...');
                    mainLoop(audioInterface);
                case Failure(error):
                    trace(error);
            }
        });
    }

}
