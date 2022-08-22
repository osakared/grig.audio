package grig.audio.hxal.environment;

import ftk.format.template.Parser;
import ftk.format.template.Template;
import haxe.macro.Context;
import sys.io.File;

class EnvironmentHelper
{
    private var templateData:String;

    public function new(relativePath:String) {
        var absolutePath = Context.resolvePath('grig/audio/hxal/environment/' + relativePath);
        templateData = File.getContent(absolutePath);
    }

    public function print(vars: {}):String {
        var template = new Template();
        return template.execute(new Parser().parse(templateData), vars);
    }
}