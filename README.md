# Docker BFG

[![cd](https://github.com/jonlabelle/docker-bfg/actions/workflows/cd.yml/badge.svg)](https://github.com/jonlabelle/docker-bfg/actions/workflows/cd.yml)
[![docker pulls](https://img.shields.io/docker/pulls/jonlabelle/bfg?label=docker%20pulls)](https://hub.docker.com/r/jonlabelle/bfg)
[![image size](https://img.shields.io/docker/image-size/jonlabelle/bfg/latest?label=image%20size)](https://hub.docker.com/r/jonlabelle/bfg/tags)

> A Docker image for the [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/), a simpler, faster alternative to `git filter-branch` for removing large files, passwords, credentials, and other unwanted data from Git repository history.

**Current BFG Version:** 1.15.0

## Features

- All the wonderful features of [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) without all the setup.
- No Java installation required; Java is bundled within the Docker image.
- Includes the latest version of BFG Repo-Cleaner.
- Uses [Eclipse Temurin](https://hub.docker.com/_/eclipse-temurin) JRE for a lightweight environment.
- Multi-architecture support (amd64, arm64).

## Usage

Run BFG by mounting your repository directory:

```bash
docker run --rm -v /path/to/repo:/work jonlabelle/bfg [options]
```

Show BFG help:

```bash
docker run --rm jonlabelle/bfg --help
```

## Examples

### Remove large files

Remove all files larger than 100MB from your repository history:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --strip-blobs-bigger-than 100M my-repo.git
```

### Delete specific files

Remove all files named `passwords.txt` from history:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --delete-files passwords.txt my-repo.git
```

### Remove folders

Remove a folder from all commits:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --delete-folders .secrets my-repo.git
```

### Replace sensitive data

Replace passwords in all files using a text file with replacements:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --replace-text replacements.txt my-repo.git
```

### Clean up after BFG

After running BFG, clean up your repository:

```bash
cd my-repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

For more options and detailed documentation, see the [BFG Repo-Cleaner website](https://rtyley.github.io/bfg-repo-cleaner/).

## Wrapper Functions

Create a shell function to use BFG like a native command without typing the full Docker command each time.

### Bash

Add to `~/.bashrc` or `~/.zshrc`:

```bash
bfg() {
  docker run --rm -v "$(pwd):/work" jonlabelle/bfg "$@"
}
```

### PowerShell

Add to your PowerShell profile:

```powershell
function bfg {
  docker run --rm -v "${PWD}:/work" jonlabelle/bfg $args
}
```

## License

[MIT License](LICENSE)
