# Chromium video acceleration on SM8250

Chromium reads per-user command-line options from:

```text
~/.config/chromium-flags.conf
```

Choose one of the following configurations. Do not combine the GLES and
Vulkan options.

## Native Wayland with Mesa EGL/OpenGLES

```text
--ozone-platform=wayland
--use-gl=egl
--use-cmd-decoder=validating
--enable-features=AcceleratedVideoDecoder,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL
--disable-features=Vulkan,DefaultANGLEVulkan,VulkanFromANGLE
--ignore-gpu-blocklist
```

This package builds Chromium with `enable_validating_command_decoder=true`.
The validating decoder is required because Chromium's passthrough command
decoder only permits ANGLE; using passthrough with native Mesa EGL terminates
the GPU process.

If Chromium is started outside the desktop session, provide the Wayland
environment explicitly:

```sh
XDG_RUNTIME_DIR=/run/user/$(id -u) \
WAYLAND_DISPLAY=wayland-0 \
EGL_PLATFORM=wayland \
chromium
```

## X11/XWayland with Vulkan

```text
--ozone-platform=x11
--use-angle=vulkan
--use-vulkan=native
--enable-features=Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,AcceleratedVideoDecoder
--ignore-gpu-blocklist
```

Chromium 150 does not implement native Wayland Vulkan presentation. Use
X11/XWayland for Vulkan; combining `--ozone-platform=wayland` with the Vulkan
options results in GPU-process failures or a window that repeatedly reloads.

## Main10 test sample

- Test page: <https://lf-tk-sg.ibytedtos.com/obj/tcs-client-sg/resources/video_demo_hevc.html#main10-bt709-sample-6>
- Direct video: <https://lf-tk-sg.ibytedtos.com/obj/tcs-client-sg/resources/hevc_2k24P_main10.mp4>

During successful HEVC Main10 playback, the Chromium GPU process opens the
Venus decoder and dequeues P010 capture buffers. On SM8250 this can be checked
with:

```sh
sudo fuser -v /dev/video14
```

The exact video node can vary; use `v4l2-ctl --list-devices` to find
`qcom-venus-decoder` when `/dev/video14` is different.
