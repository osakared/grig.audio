#!/bin/sh
rm -f library.zip
zip -r library.zip src *.md *.json *.hxml .haxerc
haxelib submit library.zip $HAXELIB_PWD --always
rm library.zip
