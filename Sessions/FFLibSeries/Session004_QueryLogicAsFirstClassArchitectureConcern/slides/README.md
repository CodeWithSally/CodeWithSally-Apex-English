# Session 004 slides

[`presentation.md`](presentation.md) is the slide source. Edit it by hand, or ask an agent in Cursor or Claude to edit it. The agent reads and writes that markdown, then you both check the result in preview. The build script turns the same file into HTML, a PDF, and one PNG per slide.

## Working with an agent

Start preview first so the deck is on screen while the agent works:

```bash
./slides/bin/preview.sh
```

Open the URL it prints (default `http://localhost:8080/presentation.md`) in a browser. Saving `presentation.md` reloads the deck. Leave the server running. You and the agent look at the same slides, then the agent changes the markdown and you refresh the preview to judge layout, type size, and diagrams.

Ask the agent for a slide, a layout, or a graphic. Layouts live in the markdown as HTML with classes from [`theme/presentation.css`](theme/presentation.css) (`detail-slide`, `checklist-slide`, `color-key-split`, and the rest of the `session` theme). Graphics are SVG files under [`images/`](images/). The agent writes the SVG, then references it from the slide with an image or `<img>` tag, for example `images/callers-graphic.svg`. SVG stays editable: the agent can change labels, colors, and boxes in the file and you see the update on the next preview reload.

Earlier sessions in this series use the same slide layout. An agent can open their `presentation.md` and `images/` and copy a slide or diagram into this deck, then adapt the wording:

- `Sessions/FFLibSeries/Session001_Separation_of_Concerns_in_Apex/slides/`
- `Sessions/FFLibSeries/Session002_Service_Layers_Explained/slides/`
- `Sessions/FFLibSeries/Session003_DomainVsService/slides/`

Copy the markdown slide (the block between `---` rules) and any SVG it references. Keep the theme classes and image paths so the copied slide still matches this deck. After the preview looks right, run the build so `presentation.html` and `presentation.pdf` match the source.

## Build HTML and PDF

From this session directory:

```bash
./slides/bin/build.sh
```

Or from this `slides` directory:

```bash
./bin/build.sh
```

The first run installs the Marp toolchain under `slides/bin/build/` (`@marp-team/marp-cli` and `highlightjs-apex`). Later runs reuse that install.

It writes:

| Output | Path |
| --- | --- |
| Browser deck | [`presentation.html`](presentation.html) |
| PDF | `presentation.pdf` |
| One PNG per slide | `bin/out/slides/slide.001.png`, `slide.002.png`, … |

Open `presentation.html` in a browser. Arrow keys move between slides.

PDF export needs a local Chromium browser (Google Chrome, Chromium, or Microsoft Edge). Marp prints the deck through that browser. If the PDF step fails, install Chrome and run the same command again. HTML and PNGs are written before the PDF step, so a PDF failure still leaves those files.

## Preview while editing

```bash
./slides/bin/preview.sh
```

Leave that running, then open the URL it prints (default `http://localhost:8080/presentation.md`). Saving `presentation.md` reloads the deck. If port 8080 is taken, the script uses the next free port. Ctrl+C stops the server.

The preview server is the live view. Opening `presentation.html` in Cursor does not refresh when the markdown changes. After you finish editing, run `./slides/bin/build.sh` again so `presentation.html` and `presentation.pdf` match the source.

## What the build uses

- `presentation.md` — slide source. `---` starts a new slide. The front matter sets `theme: session`.
- `theme/presentation.css` — the `session` theme (extends Marp Gaia).
- `bin/build/engine.js` — Marp engine that highlights Apex fences and adds line numbers.
- `bin/build/.marprc.yml` — flags used by the build (`html`, local images, theme, engine).
- `images/` — logos and diagrams referenced from the markdown.
