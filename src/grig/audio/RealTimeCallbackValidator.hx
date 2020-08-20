package grig.audio;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using StringTools;
#end

/**
 * Functions to check for some potential issues with real-time code. Based on heuristics.
 * Since this is at the macro-level, it cannot know what actually happens in the target environment.
 * For something that applies more extensive restrictions and can do some lower-level optimizations, see grig.hxal
 */
class RealTimeCallbackValidator
{
    private static inline var MAX_RECURSION = 2;

    #if macro
    static private function shouldValidate(field:Field):Bool
    {
        if (field.meta == null) return false;

        for (meta in field.meta) {
            if (meta.name == 'validate') return true;
        }

        return false;
    }

    static private function validateIdentifier(identifier:String, noError:Bool):Void
    {
        var msg:Null<String> = null;
        if (identifier.startsWith('File')) {
            msg = 'File io not allowed';
        }
        else if (identifier.startsWith('Mutex')) {
            msg = 'Locks not allowed';
        }
        if (msg != null) {
            if (noError) Context.warning(msg, Context.currentPos());
            else Context.error(msg, Context.currentPos());
        }
    }

    static private function validate(expr:Expr, noError:Bool, loopRecursion:Int):Void
    {
        if (loopRecursion > MAX_RECURSION) {
            if (noError) Context.warning('Too many levels of recursion: $loopRecursion', Context.currentPos());
            else Context.error('Too many levels of recursion: $loopRecursion', Context.currentPos());
        }
        if (expr == null) return;
        switch expr.expr {
            case EConst(c):
                switch c {
                    case CIdent(s):
                        validateIdentifier(s, noError);
                    case CRegexp(r, opt):
                        Context.warning('Regexen may not be performant', Context.currentPos());
                    default:
                        return;
                }
            case EArray(e1, e2):
                validate(e1, noError, loopRecursion);
                validate(e2, noError, loopRecursion);
            case EBinop(op, e1, e2):
                validate(e1, noError, loopRecursion);
                validate(e2, noError, loopRecursion);
            case EField(e, field):
                validateIdentifier(field, noError);
                validate(e, noError, loopRecursion);
            case EParenthesis(e):
                validate(e, noError, loopRecursion);
            case EObjectDecl(fields):
                Context.warning('Declaring object structures discouraged', Context.currentPos());
                return;
            case EArrayDecl(values):
                Context.warning('Declaring arrays discouraged', Context.currentPos());
            case ECall(e, params):
                validate(e, noError, loopRecursion);
                for (param in params) {
                    validate(param, noError, loopRecursion);
                }
            case ENew(t, params):
                if (noError) Context.warning('Allocating memory not allowed', Context.currentPos());
                else Context.error('Allocating memory not allowed', Context.currentPos());
            case EFunction(kind, f):
                validate(f.expr, noError, loopRecursion);
            case EBlock(exprs):
                for (expr in exprs) {
                    validate(expr, noError, loopRecursion);
                }
            case EVars(vars):
                for (v in vars) {
                    validate(v.expr, noError, loopRecursion);
                }
            case EMeta(s, e):
                if (s.name == 'ignore') {
                    return;
                }
                validate(e, noError, loopRecursion);
            case EFor(it, expr):
                validate(expr, noError, loopRecursion + 1);
            case EIf(econd, eif, eelse):
                validate(econd, noError, loopRecursion);
                validate(eif, noError, loopRecursion);
                validate(eelse, noError, loopRecursion);
            case EWhile(econd, e, normalWhile):
                validate(econd, noError, loopRecursion);
                validate(e, noError, loopRecursion + 1);
            case ESwitch(e, cases, edef):
                validate(edef, noError, loopRecursion);
                for (c in cases) {
                    validate(c.expr, noError, loopRecursion);
                }
            case ETry(e, catches):
                Context.warning('Exceptions are potentially not performant', Context.currentPos());
                validate(e, noError, loopRecursion);
                for (c in catches) {
                    validate(c.expr, noError, loopRecursion);
                }
            case EReturn(e):
                validate(e, noError, loopRecursion);
            case EThrow(e):
                Context.warning('Exceptions are potentially not performant', Context.currentPos());
            case ECast(e, t):
                validate(e, noError, loopRecursion);
            case ETernary(econd, eif, eelse):
                validate(econd, noError, loopRecursion);
                validate(eif, noError, loopRecursion);
                validate(eelse, noError, loopRecursion);
            case ECheckType(e, t):
                validate(e, noError, loopRecursion);
            default:
                return;
        }
    }

    /**
     * Use to validate your class. Add `@validate` to any function you want to validate. Add `@ignore` to any code therein you don't want to validate.
     * @return Array<haxe.macro.Field>
     */
    macro static public function build(noError:Bool = false):Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();

        for (field in fields) {
            var fn = switch field.kind {
                case FFun(f):
                    f;
                default:
                    continue;
            }
            if (!shouldValidate(field)) continue;
            validate(fn.expr, noError, 0);
        }

        return fields;
    }
    #end
}