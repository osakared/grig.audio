package grig.audio.hxal.environment;

import grig.audio.hxal.HVar;

class CppEnvironment implements grig.audio.hxal.Environment
{
    #if macro

    public function new() {
    }

    public function buildOutput(descriptor:ClassDescriptor):Void {
        var helper = new EnvironmentHelper('cpp/main.cc.mtt');
        trace(helper.print({
            className: descriptor.className,
            vars: [for (hvar in descriptor.vars) {name: hvar.name, type: cppTypeFromVarType(hvar.type)}]
        }));
    }

    private static function cppTypeFromVarType(varType:VarType):String {
        return switch varType {
            case TFloat: 'float';
            case TInvalid: 'NaN';
        }
    }

    #end
}