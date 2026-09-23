# Omarchy StreamPiP

An Omarchy bar widget and RTSP/RTSPS launcher for a low-latency mpv
picture-in-picture window.

## Screenshots

Saved streams, with quick launch, mute, and removal controls:

![Saved StreamPiP streams](images/saved-streams.png)

Add a named RTSP/RTSPS stream directly from the popup:

![Add a StreamPiP stream](images/add-stream.png)

## Controls

- `SUPER + SHIFT + ALT + L`: open the saved-stream popup beneath the focused
  StreamPiP bar icon. Select a stream to launch it, then use **+ Add** to save
  another RTSP/RTSPS URL or **Remove** to delete the selected stream.
- With a stream selected, **Mute** turns its audio off; **Audio** restores it.
  The setting is remembered per stream.
- `SUPER + Right Mouse drag`: resize the stream window (native Omarchy behavior).
- `SUPER + Left Mouse drag`: move the window.
- `SUPER + W`: close the active Stream PiP window.
- `SUPER + SHIFT + ALT + W`: close any StreamPiP window, including one that
  failed to receive keyboard focus.
- `SUPER + T`: use Omarchy's normal floating/tiled toggle on the focused PiP.
- `SUPER + SHIFT + ALT + T`: arrange every active StreamPiP to match the
  focused PiP. Floating PiPs reflow into a 16:9 grid on that monitor; tiled
  PiPs move into the persistent `special:streampip` Dwindle overlay.

The first PiP opens at 600×338 in the lower-right corner. Active floating PiPs
automatically reflow after a stream opens or closes, preserve their aspect ratio,
and stay pinned across workspaces. The tiled layout keeps all active streams in
the StreamPiP special-workspace overlay while changing normal workspaces. Saved
stream names and URLs are stored
with owner-only permissions at `~/.config/omarchy/live-stream-pip/streams.tsv`.
This is intentional so the hotkey can reuse streams, but URLs may contain RTSP
credentials.

When a stream launches, its URL is provided to mpv through a temporary
owner-only playlist file, not the process command line.

## Install from a repository

```bash
omarchy plugin add https://github.com/byronroark/omarchy-streampip.git --enable
```

The bar icon opens a compact, Omarchy-themed picker directly beneath the icon.
It requires `mpv`, which is part of the standard Omarchy environment.

After running the installer, search for **StreamPiP** in Omarchy Apps to launch
it from the dome-camera icon.

## Optional PiP hotkey and window rule

Run the included installer after adding the plugin to enable a dedicated
`SUPER + SHIFT + ALT + L` hotkey and the pinned lower-right PiP window rule:

```bash
./install.sh
```

This uses only user-owned files under `~/.local/bin` and `~/.config/hypr`.

## Remove

```bash
./uninstall.sh
```

To remove the bar widget and its installed source:

```bash
omarchy plugin remove byronroark.streampip
```
