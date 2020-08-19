# grig.audio

[![pipeline status](https://gitlab.com/haxe-grig/grig.audio/badges/main/pipeline.svg)](https://gitlab.com/haxe-grig/grig.audio/commits/main)
[![Build Status](https://travis-ci.org/osakared/grig.audio.svg?branch=main)](https://travis-ci.org/osakared/grig.audio)
[![Gitter](https://badges.gitter.im/haxe-grig/Lobby.svg)](https://gitter.im/haxe-grig/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

See the [haxe grig documentation](https://grig.tech/)

Audio I/O and Audio Primitives for haxe.

For c++ target, enable asio by specifying `enable_asio` AND giving the directory with `asio_path`:

```
haxe build.hxml -D enable_asio -D asio_path=C:/Users/username/Downloads/asio -cpp bin/Sine
```

For python target, pip packages `numpy`, `scipy` and `pyaudio` are needed.
