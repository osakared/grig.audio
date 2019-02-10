package grig.audio;

// Ordered to match RtAudio to allow easy conversion
enum Api {
    Unspecified;
    Alsa;
    Pulse;
    Oss;
    MacOSCore;
    WindowsWASAPI;
    WindowsASIO;
    WindowsDS;
    Dummy;
    Browser;
}