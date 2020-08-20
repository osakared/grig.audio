package;

@:build(grig.audio.RealTimeCallbackValidator.build())
class OkayAudioCallback
{
    @validate public function callback(buffer:Array<Array<Float>>):Void
    {
        @ignore
        var b = new Array<Int>();
        var c = [1, 2, 3];
        var x = 0;
        for (i in 0...10) {
            for (j in 0...10) {
                x++;
            }
        }
    }
}

class Succeed
{
    static function main()
    {
    }
}
