hxdsp
======

![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/baioc/hxdsp)

A simple FFT library implemented in Haxe for cross-platform signal processing.<br/>
For more information, check out the [current API docs](https://baioc.github.io/hxdsp/).


Example
------

A modest attempt at a [melody extraction program](examples/Melody.hx) is provided in this repository.
On unix systems having `ffmpeg` and `gnuplot` installed, you only need to add an audio file of your own to the path `res/track.mp3` and run

```sh
$ haxe examples/example.hxml
```

| Sample spectrogram data displayed with the help of `gnuplot` |
|---|
| ![spectrogram](https://user-images.githubusercontent.com/27034173/137220034-0d8361d0-7401-45d1-87ad-87dba4f7bd7f.png) |


TODO:
------

* Make it a haxelib package
* Set up proper testing

Contributions are more than welcome!
