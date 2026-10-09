# Markfly landing page

A static landing page for Markfly, the native macOS Markdown viewer.

## Sections

1. Hero with the real Markfly app preview and latest-release download link.
2. Product features, including Mermaid diagram, code, and split views.
3. CSS-built Finder-to-Markfly opening demo.
4. Three-step workflow: open, read, search or copy.
5. macOS download callout and compact project footer.

## Preview locally

From this directory, run:

```sh
python3 -m http.server 4173
```

Then open `http://localhost:4173`. No build step, package manager, or runtime service required.

## Design and assets

`design.md` is copied byte-for-byte from the Markfly desktop app repository and is the shared visual reference. This page uses its warm cream, coral, serif display type, and dark footer. Licensed display fonts are unavailable, so the site uses local system serif and sans-serif fallbacks.

`assets/source/` keeps the supplied originals unchanged. Cropped or resized copies in `assets/` power the page. The hero and feature panel use the supplied Markfly app screenshot. Finder illustration and motion use CSS only; no runtime JavaScript or new image assets.

## Downloads

The call to action opens the [latest GitHub release](https://github.com/rizkidarmawan21/markfly.md/releases/latest). Current release metadata includes macOS arm64 DMG, PKG, and ZIP builds.
