# Publish on GitHub

This repository snapshot deliberately includes no Git credentials or user profile data.

## Option A — using the GitHub website + ChatGPT's connected GitHub app

1. Create an **empty** repository at https://github.com/new named `discord-warp-gost-linux`.
2. Pick **public or private** yourself. Do not enable auto-generated README, .gitignore or license; those are already included.
3. Share the full `owner/repo` or repository URL in the chat. The connected GitHub app can then create the source files in the existing repository (subject to granted permissions).

## Option B — GitHub CLI on your Ubuntu machine

Unzip the source bundle, open a terminal in the extracted `discord-warp-gost-linux` directory, then:

```bash
git init -b main
git add .
git commit -m "Initial release: Discord-specific WARP + GOST launcher"
gh auth login
gh repo create discord-warp-gost-linux --public --source=. --remote=origin --push
```

Change `--public` to `--private` if appropriate. `gh auth login` will request your own authentication; never put tokens or secrets into source code. Avoid committing Cloudflare WARP configuration and registration files. If your Git identity is unset, configure `git config user.name` and `git config user.email` with values you choose.

### Before publishing

- Review `README.md`, `LICENSE`, and `docs/ARCHITECTURE.md`.
- Run `bash tests/test.sh`.
- Ensure no private IPs, names, WARP registration IDs or authentication secrets were added.
- Do not bundle upstream WARP, Discord, or GOST binaries without respecting their licenses.
