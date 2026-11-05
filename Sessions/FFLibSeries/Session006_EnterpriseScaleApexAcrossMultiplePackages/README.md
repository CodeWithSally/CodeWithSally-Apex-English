# Session 006 — Enterprise-Scale Apex Across Multiple Packages

Recorded live on Tuesday, November 3, 2026. The last session of the FFLib Series.

How do you let packages work together without wiring them so tightly that every change ripples through all of them? This session takes the layers from Sessions 1 to 5 and splits them across packages, using fflib Apex Common, force-di and AT4DX. It follows Meridian Corporation, whose four divisions (Sales, Service, Marketing and Meridian Fulfillment, home of the Warehouse Operations app) share one org.

Topics:

- **The package layers:** Business, Project Common, Org-wide Common, Universal Common and Framework, and the three rules that keep them apart
- **Cross-package architecture:** unlocked packages, package prefixes and naming conventions
- **Shared contracts and interfaces** between packages
- **Configuration-driven design:** AT4DX's Application factories and custom metadata bindings
- **Extensibility patterns:** selector field injection, selector method injection, domain process injection and platform event distribution

This session is concepts and architecture only, so there's no app code in this folder.

## Slides

- [`slides/presentation.md`](slides/presentation.md) — slide source (Marp)
- [`slides/presentation.html`](slides/presentation.html) — browser deck
- [`slides/presentation.pdf`](slides/presentation.pdf) — PDF

To rebuild after editing, run `./slides/bin/build.sh` from this folder. `./slides/bin/preview.sh` serves a live preview. The first run installs the Marp toolchain under `slides/bin/build/`.
