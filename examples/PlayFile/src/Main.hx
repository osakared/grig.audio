package;

import grig.audio.AudioBuffer;
import grig.audio.AudioInterface;
import grig.audio.Ints;
import grig.audio.NumericTypes;
import grig.audio.LinearInterpolator;
import haxe.Timer;
import tink.core.Future;

using grig.audio.AudioBufferTools;

class Main
{
    private static var location:Int = 0;
    private static var buffer:AudioBuffer<Float32>;

    private static function audioCallback(input:AudioBuffer<Float32>, output:AudioBuffer<Float32>, sampleRate:Float, audioStreamInfo:grig.audio.AudioStreamInfo)
    {
        output.clear();
        if (buffer == null) return;
        if (location >= buffer.numSamples) return;
        var length = Ints.min(buffer.numSamples - location, output.numSamples);
        output.copyFrom(buffer, length, location, 0);
        location += length;
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
        var options:grig.audio.AudioInterfaceOptions = {};
        for (port in ports) {
            if (port.isDefaultOutput) {
                options.outputNumChannels = port.maxOutputChannels;
                options.outputPort = port.portID;
                options.sampleRate = port.defaultSampleRate; // if input and output are different samplerates (would that happen?) then this code will fail
                options.outputLatency = port.defaultLowOutputLatency;
            }
        }
        audioInterface.setCallback(audioCallback);
        
        var musicBytes = haxe.Resource.getBytes('DeepElmBlues.wav');
        var musicInput = new haxe.io.BytesInput(musicBytes);
        var musicLoader = new grig.audio.format.wav.Reader(musicInput);
        musicLoader.load().handle(function(bufferOutcome) {
            switch bufferOutcome {
                case Success(_buffer):
                    buffer = _buffer;
                    if (buffer.sampleRate != options.sampleRate) {
                        buffer = buffer.resample(options.sampleRate / buffer.sampleRate);
                    }
                case Failure(error):
                    throw error;
            }
        });

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
