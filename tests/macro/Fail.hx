package;

@:build(grig.audio.RealTimeCallbackValidator.build())
class BadAudioCallback
{
    @validate public function callback(buffer:Array<Array<Float>>):Void
    {
        @ignore
        sys.io.File.read('/tst');

        var x = 0;
        for (i in 0...10) {
            for (j in 0...10) {
                for (k in 0...10) {
                    x++;
                }
            }
        }

        var c = new Array<Int>();
    }
}

class Fail
{
    static function main()
    {
    }
}
