package grig.audio.hxal;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class Macro
{
    // Disable this stuff in Windows probably
    private static inline var bold = '\033[1m';
    private static inline var cyan = '\033[36m';
    private static inline var reset = '\033[0m';

    public static inline var marquee = 'hxal:';

    #if macro
    private static function info(message:String):Void
    {
        Context.info('${cyan}${bold}${marquee}${reset} ${cyan}${message}${reset}', Context.currentPos());
    }
 
    private static function init():ClassType
    {
        var localClassRef:Null<Ref<ClassType>> = Context.getLocalClass();
        if (localClassRef == null) {
            Context.error("Missing local class", Context.currentPos());
        }

        var localClass = localClassRef.get();

        // var descriptor = NodeDescriptor.fromClassType(localClass.get());
        info('🧚‍♂️ Initializing hxal compiler for class ${localClass.name}...');

        return localClass;
    }

    public static function buildProcessor():Array<haxe.macro.Field>
    {
        var localClass = init();

        

        return [];
    }
    #end
}