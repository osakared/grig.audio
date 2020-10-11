package;

import grig.audio.AudioInterface;
import haxe.Timer;
import tink.core.Future;

class Main
{

    private static var phase:Float = 0.0;

    private static function audioCallbackWithInput(input:grig.audio.AudioBuffer, output:grig.audio.AudioBuffer, sampleRate:Float, audioStreamInfo:grig.audio.AudioStreamInfo)
    {
        var channel = output[0];
        for (i in 0...channel.length) {
            phase += 0.1;
            channel[i] = Math.sin(phase) * 0.3 + input[0][i] * 0.3;
        }
    }

    private static function audioCallback(input:grig.audio.AudioBuffer, output:grig.audio.AudioBuffer, sampleRate:Float, audioStreamInfo:grig.audio.AudioStreamInfo)
    {
        var channel = output[0];
        for (i in 0...channel.length) {
            phase += 0.1;
            channel[i] = Math.sin(phase);
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

        // Uncomment to test closing in js
        // haxe.Timer.delay(function() {
        //     audioInterface.closePort();
        // }, 5000);
    }

    static function main()
    {
        trace(AudioInterface.getApis());
        var audioInterface = new AudioInterface();
        var ports = audioInterface.getPorts();
        trace(ports);
        var options:grig.audio.AudioInterfaceOptions = {};
        if (ports.length < 1) {
            trace('No ports found');
            return;
        }
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
        else audioInterface.setCallback(audioCallback);
        audioInterface.openPort(options).handle(function(audioOutcome) {
            switch audioOutcome {
                case Success(_):
                    trace(audioInterface.isOpen);
                    trace('Playing sine wave combined with input (if available)...');
                    mainLoop(audioInterface);
                case Failure(error):
                    trace(error);
            }
        });
    }

}
