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

    private static var environment = "haxe";

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
 
    private static function init(classType:ClassType):Void
    {
        info('🧚‍♂️ Initializing hxal compiler for class ${classType.name} and environment ${environment}...',
            classType.pos);
    }

    public static function buildProcessor(classType:ClassType):Array<haxe.macro.Field>
    {
        init(classType);
        var descriptor = new ClassDescriptor(classType);

        return [];
    }

    public static function autoBuildProcessor():Array<haxe.macro.Field>
    {
        var localClassRef:Null<Ref<ClassType>> = Context.getLocalClass();
        if (localClassRef == null) {
            Context.error("Missing local class", Context.currentPos());
        }

        var localClass = localClassRef.get();
        var fields = buildProcessor(localClass);

        // Add a static main field so we can use the --run trick to force macro to run
        fields.push({
            name: 'main',
            access: [AStatic, APublic],
            kind: FFun({
                args: [],
                expr: macro {}
            }),
            pos: localClass.pos
        });

        return fields;
    }

    public static function setEnvironment(environmentName:String):Void
    {
        environment = environmentName;
    }
    #end
}