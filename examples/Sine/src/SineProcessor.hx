package;

class SineProcessor implements grig.audio.Processor
{
    private var phase:Float;
    private var pitch:AtomicFloat;

    private function onBuffer(inputBuffer:Buffer<Sample>, outputBuffer:Buffer<Sample>,
                              streamInfo:StreamInfo):Void {
        outputBuffer.eachFrame((frame) => {
            phase += 0.1;
            frame = Math.sin(phase);
        });
    }
    
    // @hxal.midi.note 
    // private var gate:Bool;
}
