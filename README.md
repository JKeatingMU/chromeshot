# chromeshot

A tiny, dependency-free CLI that turns local or remote web pages into
**full-page** screenshots using headless Chrome. It measures each page and
captures the entire scroll height automatically — no guessing at a
`--window-size` and no truncated tall pages.

![chromeshot in action](docs/demo.gif)

```
capture                    # screenshot every page in ./capture.toml
capture display learn      # only the named pages
capture --list             # show configured pages, capture nothing
capture --url https://example.com -n example   # one-off, no config file
```

```
evidence_pack   1440x3265  ->  /tmp/mask_atlas_evidence_pack_1440x3265.png  (1583 KB)
```

## Why

- **True full-page capture** via the DevTools Protocol
  (`Page.captureScreenshot { captureBeyondViewport: true }`) — height is
  detected from the page, not supplied by hand.
- **Retina-sharp** output through `deviceScaleFactor` (default 2×).
- **Batch** rendering: one Chrome launch handles every page in a config.
- **No dependencies.** Pure Python standard library — no Puppeteer, no Node,
  no `pip install`. One file you can drop on your `PATH`.

## Screenshots

Below is a single capture of [`docs/sample-page.html`](docs/sample-page.html) —
a page taller than a browser viewport. A fixed-height screenshot would cut it
off; chromeshot detects the scroll height and renders the whole thing in one
pass, at a 2× device scale:

```sh
capture --url file://$PWD/docs/sample-page.html -n sample --width 720
```

<p align="center">
  <img src="docs/sample-fullpage_720x1365.png" width="360"
       alt="Full-page screenshot of the sample page, captured top to bottom">
</p>

<p align="center"><em>720×1365 CSS px, captured in full — hero, four sections and footer.</em></p>

## Requirements

- Python **3.11+** (uses the standard-library `tomllib`).
- Google Chrome, Chromium, or Microsoft Edge. `chromeshot` auto-detects a
  binary on macOS, Linux and Windows; override with the `CHROME_BIN`
  environment variable if needed.

## Install

`chromeshot` is a single Python script and runs anywhere Python 3.11+ and a
Chromium-based browser are available — macOS, Linux and Windows.

### Homebrew — macOS & Linux (recommended)

[Homebrew](https://brew.sh) runs on both macOS and Linux:

```sh
brew install JKeatingMU/tap/chromeshot
```

It pulls in a suitable Python automatically. Upgrade later with
`brew upgrade chromeshot`.

### Manual — macOS & Linux

```sh
git clone https://github.com/JKeatingMU/chromeshot.git
install -m 755 chromeshot/capture ~/.local/bin/capture   # or anywhere on your PATH
```

Or just copy the single `capture` script wherever you like and make it
executable (`chmod +x capture`). Manual installs use your own `python3`
(3.11+).

### Windows

The shebang line doesn't apply on Windows, so run the script through Python:

```powershell
git clone https://github.com/JKeatingMU/chromeshot.git
python chromeshot\capture --url https://example.com -n example
```

For a plain `capture` command, drop a one-line `capture.cmd` on your `PATH`:

```bat
@echo off
python "C:\path\to\chromeshot\capture" %*
```

`chromeshot` auto-detects Chrome / Edge in the usual `Program Files` locations;
set `CHROME_BIN` if yours lives elsewhere.

## Usage

```
capture [names...]          capture all pages, or only the named ones
  -c, --config PATH         config file (default: ./capture.toml)
      --url URL             ad-hoc page, no config file needed
  -n, --name NAME           name for the ad-hoc page
      --width N             viewport width in CSS px
      --height N            pin height (implies --no-full-page for --url)
      --full-page / --no-full-page
      --scale N             device scale factor (2 = retina)
      --wait SPEC           load | networkidle | delay:800 | selector:#ready
      --out-dir PATH        output directory
      --format FMT          png | jpeg | pdf
      --list                list configured pages and exit
      --open                open each result after writing it
      --version             print version and exit
```

Each capture is verified (file exists, non-zero) and the process exits
non-zero if any page fails, so it drops cleanly into a pre-commit hook or CI
step.

## Config: `capture.toml`

Keep one `capture.toml` per project. A `[defaults]` table sets shared options;
each `[[page]]` names a page and may override any default.

```toml
[defaults]
width         = 1440
full_page     = true                 # auto-detect height
out_dir       = "/tmp"
device_scale  = 2                     # retina-sharp
format        = "png"                 # png | jpeg | pdf
wait          = "load"                # load | networkidle | delay:800 | selector:#ready
name_template = "{name}_{width}x{height}"

[[page]]
name = "home"
url  = "https://example.com"

[[page]]
name       = "dashboard"
url         = "file:///path/to/dashboard.html"
full_page  = false                   # pin a fixed height (see note below)
height     = 1800
```

**Precedence** for any option: command-line flag > per-page value >
`[defaults]` > built-in default.

### When to pin height instead of auto-detecting

Auto-detect measures a page's scroll height, so it only works for content that
**flows**. A page laid out in viewport units (e.g. `height: 100vh`) is designed
to be exactly one screen tall and will collapse to whatever viewport height it
is given — a misleading measurement. For those pages set `full_page = false`
and pin an explicit `height`.

## Using chromeshot with an AI agent

A coding agent reasoning over HTML/DOM is working from the *symbolic* version of
a page. But layout bugs — overlap, clipping, contrast, "does this actually look
right" — live in the *rendered* pixels. `getBoundingClientRect` tells you where a
box should be; a screenshot shows where it is. Handing the model the image closes
that gap and lets it see what the user sees.

The loop is simply **capture, then read the PNG back**:

```sh
capture --url http://localhost:3000 -n home --out-dir /tmp
# → /tmp/home_1440x2400.png, which the agent then views as an image
```

Because it captures the full page in one pass, verifies the file, and exits
non-zero on failure, it slots straight into an agent's tool loop — render a
change, look at it, decide, repeat. That's exactly how this project was built:
each page was captured and viewed to confirm the layout, which is how the
truncated tall page and the collapsed `100vh` page were caught.

### Pairing with Puppeteer / Playwright

The two are complementary — one *acts*, the other *sees*:

- **Puppeteer / Playwright** drive stateful flows: click, type, log in, wait on
  network. Use them to put the page into the state you care about.
- **chromeshot** grabs the frame once that state exists — no browser context to
  manage, no dependency, full-page by default.

So a common pattern is: let Puppeteer navigate and set up state, then call
`chromeshot` to capture the result for the agent to inspect. When you only need
eyes and not hands, reach for `chromeshot` alone.

## Licence

MIT — see [LICENSE](LICENSE).
