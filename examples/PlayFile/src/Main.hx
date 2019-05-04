package;

import grig.audio.AudioBuffer;
import grig.audio.AudioInterface;
import grig.audio.LinearInterpolator;
import haxe.Timer;
import tink.core.Future;

class Main
{
    private static var location:Int = 0;
    private static var buffer:AudioBuffer;

    private static function audioCallback(input:AudioBuffer, output:AudioBuffer, sampleRate:Float, audioStreamInfo:grig.audio.AudioStreamInfo)
    {
        output.clear();
        if (location >= buffer.length) return;
        var numChannels = buffer.channels.length > output.channels.length ? output.channels.length : buffer.channels.length;
        var samplesRemaining = buffer.length - location;
        var numSamples = samplesRemaining > output.length ? output.length : samplesRemaining;
        for (c in 0...numChannels) {
            buffer.channels[c].copyInto(output.channels[c], location, numSamples);
        }
        location += numSamples;
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
        var musicBytes = haxe.Resource.getBytes('DeepElmBlues.wav');
        var musicInput = new haxe.io.BytesInput(musicBytes);
        var musicLoader = new grig.audio.format.wav.Reader(musicInput);
        buffer = musicLoader.load();

        var audioInterface = new AudioInterface();
        var ports = audioInterface.getPorts();
        var options:grig.audio.AudioInterfaceOptions = {};
        for (port in ports) {
            if (port.isDefaultOutput) {
                options.outputNumChannels = port.maxOutputChannels;
                options.outputPort = port.portID;
                options.sampleRate = port.defaultSampleRate; // if input and output are different samplerates (would that happen?) then this code will fail
                options.outputLatency = port.defaultLowOutputLatency;
            }
        }
        if (buffer.sampleRate != options.sampleRate) {
            buffer = buffer.resample(options.sampleRate / buffer.sampleRate);
        }
        audioInterface.setCallback(audioCallback);
        audioInterface.openPort(options).handle(function(audioOutcome) {
            switch audioOutcome {
                case Success(_):
                    trace('Playing audio file...');
                    trace(options.sampleRate);
                    mainLoop(audioInterface);
                case Failure(error):
                    trace(error);
            }
        });
    }

}
