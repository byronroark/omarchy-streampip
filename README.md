# Omarchy StreamPiP

An Omarchy bar widget and RTSP/RTSPS launcher for a low-latency mpv
picture-in-picture window.

## Screenshots

Saved streams, with quick launch, mute, and removal controls:

![Saved StreamPiP streams](images/saved-streams.png)

Add a named RTSP/RTSPS stream directly from the popup:

![Add a StreamPiP stream](images/add-stream.png)

## Controls

- `SUPER + SHIFT + ALT + L`: select a saved stream, choose **Add a new
  stream…** to save another RTSP/RTSPS URL, or choose **Delete a saved
  stream…** and confirm its removal.
- Choose **Audio for a saved stream…** to toggle whether that stream starts
  muted; the setting is remembered per stream.
- `SUPER + Right Mouse drag`: resize the stream window (native Omarchy behavior).
- `SUPER + Left Mouse drag`: move the window.
- `SUPER + W`: close the active Stream PiP window.
- `SUPER + SHIFT + ALT + W`: close any StreamPiP window, including one that
  failed to receive keyboard focus.

The PiP opens at 600×338 in the lower-right corner, remains visible while changing
workspaces, and preserves its aspect ratio. Saved stream names and URLs are stored
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
