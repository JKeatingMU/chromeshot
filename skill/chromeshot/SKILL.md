---
name: chromeshot
description: Capture a full-page screenshot of a web page (local file:// or live URL) as a PNG/JPEG/PDF, so its rendered layout can be seen and verified — not just inferred from the DOM. Use when asked to screenshot a page, render HTML to an image, visually check or verify a page's layout, or produce fixed-size images such as infographics or social cards. Requires the `capture` CLI (chromeshot) on PATH.
---

# chromeshot

`chromeshot` renders a web page in headless Chrome and writes a **full-page** screenshot — it
auto-detects the page's scroll height, so tall pages are captured whole, not truncated. The
command is `capture`.

## Prerequisite

Requires the `capture` CLI on PATH:

```sh
brew install JKeatingMU/tap/chromeshot
```

(Or clone https://github.com/JKeatingMU/chromeshot and put the single `capture` script on your
PATH. Needs Python 3.11+ and Chrome, Chromium, or Edge.)

## Core usage

```sh
capture --url "https://example.com" -n example --out-dir /tmp
capture --url "file:///abs/path/page.html" -n page --out-dir /tmp
```

Each run prints the output path and pixel dimensions, and exits non-zero on failure.

## Verify visually — the point of this skill

After capturing, **open the PNG and look at it** to confirm the page actually rendered
correctly. The rendered pixels are ground truth that logs and the DOM don't give you — use them
to catch overlap, clipping, truncation, contrast, and "does this actually look right". The loop
is: **capture → view the image → decide → repeat.** When editing HTML/CSS or building a page,
prefer this over assuming the change worked.

## Options

- `--width N` — viewport width in CSS px (default 1440)
- `--full-page` / `--no-full-page` — full-page auto-height is the default
- `--height N` — pin an explicit height (use with `--no-full-page`)
- `--scale N` — device scale factor (2 = retina, the default)
- `--format png|jpeg|pdf`
- `--wait load|networkidle|delay:800|selector:#ready` — hold capture until content is ready
- `-c capture.toml` — batch several named pages from a config file

## Gotcha: 100vh / viewport-unit pages

Auto-height measures scroll height, so it only works for content that *flows*. A page laid out
in viewport units (e.g. `height: 100vh`) is designed to be one screen tall and collapses to
whatever viewport it's given. For those, pin an explicit height:

```sh
capture --url "file:///abs/path/display.html" -n display --no-full-page --height 1800
```

## Fixed-size images / infographics

Design the artwork as HTML at a fixed canvas size, then capture pinned dimensions at 2× scale:

```sh
capture --url "file:///abs/path/ig.html" -n square --width 1080 --no-full-page --height 1080 --scale 2   # 1080×1080
capture --url "file:///abs/path/ig.html" -n story  --width 1080 --no-full-page --height 1920 --scale 2   # 1080×1920
```

Use `--format pdf` for print-ready output. Because it's HTML, templates can generate a whole
series of images from data.
