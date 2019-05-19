package;

import grig.audio.AudioInterface;
import grig.audio.LinearInterpolator;
import haxe.Timer;
import tink.core.Future;

class Main
{
    private static function audioCallbackWithInput(input:grig.audio.AudioBuffer, output:grig.audio.AudioBuffer, sampleRate:Float, audioStreamInfo:grig.audio.AudioStreamInfo)
    {
        var ratio = 0.25;
        if (input.channels.length < 1) return;
        LinearInterpolator.resampleIntoChannel(input.channels[0], output.channels[0], ratio);
        var length = Math.floor(output.length * ratio);
        for (i in 1...Std.int(output.length / length)) {
            output.channels[0].copyInto(output.channels[0], 0, length, length * i);
        }
        for (c in 1...output.channels.length) {
            output.channels[0].copyInto(output.channels[c], 0, output.length);
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
