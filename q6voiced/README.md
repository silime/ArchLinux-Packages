# Before build 
you need built and install `tinyalsa-git` from https://aur.archlinux.org/tinyalsa-git.git
# q6voiced
q6voiced is a userspace daemon for the QDSP6 voice call audio driver.
Voice call audio is directly routed from the modem to the input/output audio
devices, but something needs to start the audio streams for that to happen.

q6voiced listens on dbus for signals from oFono, and opens/closes the
PCM device when a call is initiated/ended in oFono. This essentially
makes voice call audio work out of the box (provided that the audio
routing, e.g. Earpiece and a microphone is set up appropriately).

The q6voiced patches can be currently found in the [msm8916-mainline/linux]
repository (look for `ASoC: qdsp6:`) commits). It may also work for downstream
since the currently implemented approach is very similar.

## Note
It is expected that this daemon will be obsolete eventually.
Different approaches exists for activating such audio streams that are not
processed directly by Linux. (See [Hostless PCM streams]) At the moment the
kernel driver implements the "Hostless FE" approach (as on downstream), but
eventually this should be replaced by a Codec <-> Codec link.

In that case the audio streams would be activated by setting some ALSA mixers
(e.g. through ALSA UCM) and this daemon could be removed. However, there is
quite some work involved to make that work properly. Until then, this daemon
allows voice call audio to work without activating audio manually.

[msm8916-mainline/linux]: https://github.com/msm8916-mainline/linux
[Hostless PCM streams]: https://www.kernel.org/doc/html/latest/sound/soc/dpcm.html#hostless-pcm-streams

## Configuration

The q6voiced daemon expects a configuration file in `/etc/conf.d/q6voiced`.
The file looks like this:

```
q6voice_card=$CARD
q6voice_device=$DEVICE
```

You can find the values for `$CARD` and `$DEVICE` using `alsactl info` from the `alsa-utils` package.
You are looking for the modem audio device (example: `VoiceMMode1`) which is defined in your dts:

**dts**
```
voicemmode1-dai-link {
    link-name = "VoiceMMode1";
    cpu {
        sound-dai = <&q6voicedai VOICEMMODE1>;
    };
};
```

**alsactl info output**
```
- card: 0
  id: SHIFT6mq
  name: SHIFT6mq
  longname: SHIFT6mq
  mixer_name: 
  components: 
  controls_count: 1268
  pcm:
    - stream: PLAYBACK
      devices:
        ...
        - device: 12
          id: VoiceMMode1 (*)
          name: 
          subdevices:
            - subdevice: 0
              name: subdevice #0

```

In this case, the values are `$CARD=0` and `$DEVICE=12`.