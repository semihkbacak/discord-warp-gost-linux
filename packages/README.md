# Ubuntu .deb installation packages

The project's **.deb installer files are published as GitHub Release assets**, not checked into the source tree.

- [Download the available beta .deb installer](https://github.com/semihkbacak/discord-warp-gost-linux/releases)
- [v0.2.0 Beta package](https://github.com/semihkbacak/discord-warp-gost-linux/releases/tag/v0.2.0-beta)
- The **v0.2.1 Beta** installer includes uninstall-completion UI fixes and will be listed here once its Release is published.

## Build locally

From the repository root:

```bash
./packaging/build-deb.sh
ls -lh dist/*.deb
```

The generated package lives in `dist/`, which is intentionally not committed. The GitHub Actions workflow `.github/workflows/check.yml` also builds a `.deb` and uploads it as a downloadable workflow artifact.

### Publish a package with GitHub CLI

Once the v0.2.1 source code has been pushed to `main`, on the machine that holds the tested `.deb` file:

```bash
gh release create v0.2.1-beta \
  ./dist/discord-warp-gost-installer_0.2.1_all.deb \
  --repo semihkbacak/discord-warp-gost-linux \
  --title "Discord WARP + GOST v0.2.1 Beta" \
  --notes "Uninstall completion screen, close button, and retry flow fixes. Beta release." \
  --prerelease
```

A `.deb` is a **file**, not a folder. Keeping installers in Releases makes downloads easier and avoids storing duplicate binaries in Git history.
