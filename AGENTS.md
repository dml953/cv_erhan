# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

This is a static single-page website for "Brasserie Terroir & Savoirs", a French brewery. The entire site lives in `brasserie.html` — a self-contained HTML file with embedded CSS, JavaScript, and base64-encoded images. There is no build step, no package manager, and no backend.

### Running the site

Serve with any static HTTP server:

```bash
python3 -m http.server 8080 --directory /workspace
```

Then open `http://localhost:8080/brasserie.html`.

### Testing

There are no automated tests, linters, or build tools. Manual browser testing is the only verification method. Key interactive features to verify:

- Product filter tabs (TOUS / BIÈRES / SPIRITUEUX) in the Produits section
- Product detail modals (click "EN SAVOIR PLUS" on any product card)
- Contact form submission (displays a green "MESSAGE ENVOYÉ ✓" confirmation)
