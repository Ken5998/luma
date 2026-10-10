# Luma website

Static landing page for https://luma.ksmvc.ch. No npm dependencies or build step.
The canvas is an illustrative palette study, not the Rust simulation.

## Publish with GitHub Pages

1. In repository Settings > Pages, select **GitHub Actions** as the source.
2. Set **Custom domain** to `luma.ksmvc.ch` and save.
3. At the DNS provider create a CNAME record: `luma` -> `ken5998.github.io`.
4. Once GitHub's DNS check and certificate provisioning complete, enable **Enforce HTTPS**.
5. Push to main or run the workflow manually. The workflow builds and tests the
   Windows ZIP before publishing the site. Download buttons point to GitHub's
   latest public release, where users choose the installer or ZIP and checksums.
   Documentation-only changes therefore never replace a released download.

The production MSI is being prepared on `codex/msi-release`. Until its acceptance
checks pass and a release is published, the site continues to offer the existing
release. The visual design and illustrative palette controls remain unchanged.

The CNAME file documents the intended domain, but custom workflows still require
setting the domain in GitHub Pages settings. Do not point the DNS CNAME at a URL
or at `ken5998.github.io/luma`.

Documentation: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site

Google Fonts supplies the typefaces; system fonts are used if unavailable.
The page respects reduced-motion preferences and pauses its canvas when hidden.
