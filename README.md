# grig.audio

[![pipeline status](https://gitlab.com/haxe-grig/grig.audio/badges/master/pipeline.svg)](https://gitlab.com/haxe-grig/grig.audio/commits/master)
[![Build Status](https://travis-ci.org/osakared/grig.audio.svg?branch=master)](https://travis-ci.org/osakared/grig.audio)
[![Gitter](https://badges.gitter.im/haxe-grig/Lobby.svg)](https://gitter.im/haxe-grig/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

See the [haxe grig documentation](https://haxe-grig.gitlab.io/grig/)

Audio I/O and Audio Primitives for haxe.

## Targets

### C++

enable asio by specifying `enable_asio` AND giving the directory with `asio_path`:

```bash
haxe build.hxml -D enable_asio -D asio_path=C:/Users/username/Downloads/asio -cpp bin/Sine
```

enable jack with `enable_jack`

### js

Audio i/o on nodejs requires `naudiodon`:

```bash
npm install naudiodon
```

This is not required for webaudio-based audio in the browser. Just for standalone/nodejs applications talking to the soundcard.