# Docker BFG

[![cd](https://github.com/jonlabelle/docker-bfg/actions/workflows/cd.yml/badge.svg)](https://github.com/jonlabelle/docker-bfg/actions/workflows/cd.yml)
[![docker pulls](https://img.shields.io/docker/pulls/jonlabelle/bfg?label=docker%20pulls)](https://hub.docker.com/r/jonlabelle/bfg)
[![image size](https://img.shields.io/docker/image-size/jonlabelle/bfg/latest?label=image%20size)](https://hub.docker.com/r/jonlabelle/bfg/tags)

> A Docker image for the [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/), a simpler, faster alternative to `git filter-branch` for removing large files, passwords, credentials, and other unwanted data from Git repository history.

**Current BFG Version:** 1.15.0

## Table of Contents

- [Features](#features)
- [Usage](#usage)
- [Before You Start](#before-you-start)
- [Examples](#examples)
  - [Complete Workflow](#complete-workflow)
  - [Delete specific files](#delete-specific-files)
  - [Remove folders](#remove-folders)
  - [Replace sensitive data](#replace-sensitive-data)
- [More Examples](#more-examples)
- [Troubleshooting](#troubleshooting)
- [Wrapper Functions](#wrapper-functions)
  - [Bash](#bash)
  - [PowerShell](#powershell)
- [My other Docker repos](#my-other-docker-repos)
- [License](#license)

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

## Before You Start

> [!Warning]
> **BFG rewrites Git history, which can be destructive. Follow these steps first:**

1. **Backup your repository** - Make a complete backup before proceeding
2. **Coordinate with your team** - Ensure everyone has committed and pushed their work
3. **Test on a copy first** - Clone a separate copy to test your BFG commands
4. **Understand the impact** - After force pushing, all team members must reset their local copies
5. **Update protected branches** - You may need to temporarily disable branch protection rules

## Examples

> [!Important]
> BFG protects your current commit by default. Files in your HEAD commit are never modified—only their history is cleaned. [Learn more](https://rtyley.github.io/bfg-repo-cleaner/#protected-commits)

### Complete Workflow

Example workflow for removing large files from a repository and syncing across the team:

```bash
# Clone the repository as a bare mirror (safer for rewriting history)
git clone --mirror https://github.com/user/repo.git

# Run BFG to remove large files
docker run --rm -v $(pwd):/work jonlabelle/bfg --strip-blobs-bigger-than 100M repo.git

# Enter the repository directory (bare repo's have .git suffix)
cd repo.git

# Clean up and garbage collect
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push changes back to the remote repository
git push --force-with-lease
```

**After pushing**, other team members with local clones need to update their repositories:

```bash
# Fetch the rewritten history and reset to match the remote
git fetch origin
git reset --hard origin/main
```

> [!Warning]
> `git reset --hard` will discard any uncommitted changes. Commit or stash work before running this command.

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

Create a `replacements.txt` file with your replacements, then run:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --replace-text replacements.txt my-repo.git
```

Example `replacements.txt` format:

```text
PASSWORD1==>***REMOVED***
api_key_12345==>***REMOVED***
```

## More Examples

<details>
<summary>Remove files by extension</summary>

Remove all `.log`, `.zip`, or `.db` files from history:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --delete-files '*.{log,zip,db}' my-repo.git
```

</details>

<details>
<summary>Remove private keys</summary>

Remove accidentally committed SSH keys and certificates:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --delete-files '*.{pem,key,p12,pfx}' my-repo.git
```

Or remove specific key files:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --delete-files '{id_rsa,id_rsa.pub,private.key}' my-repo.git
```

</details>

<details>
<summary>Remove environment files</summary>

Remove `.env` files containing secrets:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --delete-files '{.env,.env.local,.env.production}' my-repo.git
```

</details>

<details>
<summary>Remove files with ID list</summary>

Remove specific blob IDs listed in a file:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --strip-blobs-with-ids blob-ids.txt my-repo.git
```

</details>

<details>
<summary>Protect recent commits</summary>

Protect the last 5 commits from being modified (only clean older history):

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg --delete-files credentials.json --protect-blobs-from HEAD~5 my-repo.git
```

</details>

<details>
<summary>Combine multiple operations</summary>

Remove large files AND delete sensitive files:

```bash
docker run --rm -v $(pwd):/work jonlabelle/bfg \
  --strip-blobs-bigger-than 50M \
  --delete-files '{*.key,*.pem,secrets.json}' \
  my-repo.git
```

</details>

For more options and detailed documentation, see the [BFG Repo-Cleaner website](https://rtyley.github.io/bfg-repo-cleaner/).

## Troubleshooting

<details>
<summary>"Protected commits" warning - files still in repository</summary>

BFG protects your HEAD commit by default. If files you want to remove are in your latest commit:

1. Make a new commit that deletes those files
2. Run BFG again on the updated repository
3. Or use `--no-blob-protection` flag (not recommended)

</details>

<details>
<summary>Force push rejected</summary>

If `git push --force-with-lease` is rejected:

- Someone may have pushed new commits - coordinate with your team
- Protected branch rules may be enabled - temporarily disable them
- Use `--force` instead (less safe but works if you're certain)

</details>

<details>
<summary>Repository size didn't decrease</summary>

After BFG, you must run cleanup commands and force push:

```bash
cd my-repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force-with-lease
```

Other clones won't see size reduction until they re-clone or reset.

</details>

<details>
<summary>Docker volume mounting issues on Windows</summary>

On Windows, use forward slashes and ensure path sharing is enabled in Docker Desktop:

```powershell
docker run --rm -v "${PWD}:/work" jonlabelle/bfg [options]
```

</details>

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

Add to your PowerShell `$PROFILE` (`Microsoft.PowerShell_profile.ps1`):

```powershell
function bfg {
  docker run --rm -v "${PWD}:/work" jonlabelle/bfg $args
}
```

> [!Tip]
> Need a modern PowerShell profile? Checkout mine at [jonlabelle/pwsh-profile](https://github.com/jonlabelle/pwsh-profile).

## My other Docker repos

- [jonlabelle/docker-network-tools](https://github.com/jonlabelle/docker-network-tools) — A Docker image with various network tools pre-installed
- [jonlabelle/docker-nmap](https://github.com/jonlabelle/docker-nmap) — Minimal Docker image with Nmap Network Security Scanner pre-installed

## License

[MIT License](LICENSE)
