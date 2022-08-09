package grig.audio.hxal;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class Macro
{
    // Disable this stuff in Windows probably
    // and put in a separate class...
    private static inline var bold = '\033[1m';
    private static inline var cyan = '\033[36m';
    private static inline var red = '\033[31m';
    private static inline var brown = '\033[33m';
    private static inline var reset = '\033[0m';

    public static inline var marquee = 'hxal:';

    #if macro
    public static function info(message:String, position:Position):Void
    {
        Context.info('${cyan}${bold}${marquee}${reset} ${cyan}${message}${reset}', position);
    }

    public static function error(message:String, position:Position):Void
    {
        Context.error('${cyan}${bold}${marquee}${reset} ${red}${message}${reset}', position);
    }

    public static function warning(message:String, position:Position):Void
    {
        Context.warning('${cyan}${bold}${marquee}${reset} ${brown}${message}${reset}', position);
    }
 
    private static function init():ClassType
    {
        var localClassRef:Null<Ref<ClassType>> = Context.getLocalClass();
        if (localClassRef == null) {
            Context.error("Missing local class", Context.currentPos());
        }

        var localClass = localClassRef.get();

        // var descriptor = NodeDescriptor.fromClassType(localClass.get());
        info('🧚‍♂️ Initializing hxal compiler for class ${localClass.name}...', localClass.pos);

        return localClass;
    }

    public static function buildProcessor():Array<haxe.macro.Field>
    {
        var localClass = init();
        var descriptor = new ClassDescriptor(localClass);

        return [];
    }
    #end
}