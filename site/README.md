# Luma website

Static landing page for https://luma.ksmvc.ch. No npm dependencies or build step.
The canvas is an illustrative palette study, not the Rust simulation.

## Publish with GitHub Pages

1. In repository Settings > Pages, select **GitHub Actions** as the source.
2. Set **Custom domain** to `luma.ksmvc.ch` and save.
3. At the DNS provider create a CNAME record: `luma` -> `ken5998.github.io`.
4. Once GitHub's DNS check and certificate provisioning complete, enable **Enforce HTTPS**.
5. Push to main or run the workflow manually. The workflow builds the Windows ZIP,
   places it in `downloads/`, then publishes the site. Download links resolve to
   the package from the same commit as the page.

The CNAME file documents the intended domain, but custom workflows still require
setting the domain in GitHub Pages settings. Do not point the DNS CNAME at a URL
or at `ken5998.github.io/luma`.

Documentation: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site

Google Fonts supplies the typefaces; system fonts are used if unavailable.
The page respects reduced-motion preferences and pauses its canvas when hidden.
