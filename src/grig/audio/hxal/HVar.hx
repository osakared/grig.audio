package grig.audio.hxal;

import haxe.macro.Expr;

enum VarType
{
    TFloat;
    Invalid;
}

enum DefinedLocation
{
    BuiltIn;
    Defined(position:Position);
}

class HVar
{
    public var name:String;
    public var type:VarType;
    public var definedLocation:DefinedLocation;

    public function new()
    {
    }
}