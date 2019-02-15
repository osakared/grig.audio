package;

import grig.audio.AudioInterface;

import haxe.Timer;

import tink.core.Future;

class Main
{

    private static var phase:Float;

    private static function audioCallbackWithInput(input:grig.audio.AudioBuffer, output:grig.audio.AudioBuffer)
    {
        var channel = output.channels[0];
        for (i in 0...channel.length) {
            phase += 0.01;
            channel[i] = Math.sin(phase) * 0.3 + input.channels[0][i] * 0.3;
        }
    }

    private static function audioCallback(input:grig.audio.AudioBuffer, output:grig.audio.AudioBuffer)
    {
        var channel = output.channels[0];
        for (i in 0...channel.length) {
            phase += 0.01;
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
    }

    static function main()
    {
        phase = 0.0;
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
            }
            if (port.isDefaultOutput) {
                options.outputNumChannels = port.maxOutputChannels;
                options.outputPort = port.portID;
                options.sampleRate = port.defaultSampleRate;
            }
        }
        if (options.inputPort != null) audioInterface.setCallback(audioCallbackWithInput);
        else audioInterface.setCallback(audioCallback);
        audioInterface.openPort(options).handle(function(audioOutcome) {
            switch audioOutcome {
                case Success(_):
                    trace('Playing sine wave combined with input...');
                    mainLoop(audioInterface);
                case Failure(error):
                    trace(error);
            }
        });
    }

}
