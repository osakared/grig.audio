package grig.audio.hxal;

import haxe.macro.Expr;
import grig.audio.hxal.HVar;

enum FunctionContext
{
    RealTime;
    Relaxed;
}

class FunctionDescriptor
{
    public var functionName:String;
    // Function local vars
    public var vars = new Array<HVar>();
    public var args = new Array<HVar>();
    public var retType:VarType;

    public function new(functionName:String, fn:Function, position:Position) {
        this.functionName = functionName;

        if (fn.params.length != 0) {
            grig.audio.hxal.Macro.error('Function parameters not supported in hxal', position);
        }

        // hxal isn't clever like haxe... for now, anyway
        if (fn.ret == null) {
            grig.audio.hxal.Macro.error('Inferred return type not supported in hxal', position);
        }

        for (i in fn.args) {
            args.push(ClassDescriptor.getHVar(i, i.type, i.value, position));
        }
        trace(fn.args);
        trace(fn.ret);
    }
}