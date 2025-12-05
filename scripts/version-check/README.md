# BFG Version Checker

[![cd](https://github.com/jonlabelle/docker-bfg/actions/workflows/check-bfg-version/badge.svg)](https://github.com/jonlabelle/docker-bfg/actions/workflows/check-bfg-version)

> This directory contains a script to check for new versions of BFG Repo-Cleaner and automatically update the project.

## Overview

The `check-bfg-version.sh` script:

- Fetches the latest BFG Repo-Cleaner release from GitHub API
- Compares it with the current version in the Dockerfile using semantic versioning
- Prevents downgrades by detecting when the current version is newer than the latest release
- Verifies the new version is available on Maven Central
- Updates project files (`Dockerfile` and `README.md`)
- Optionally creates a branch and commits the changes

## Usage

### Check for Updates (Dry Run)

See what would happen without making any changes:

```bash
./scripts/version-check/check-bfg-version.sh --dry-run
```

### Check and Update Files

Update files if a new version is available:

```bash
./scripts/version-check/check-bfg-version.sh
```

### Create Branch and Commit

Automatically create a branch and commit the changes:

```bash
./scripts/version-check/check-bfg-version.sh --create-branch --commit
```

### Display Help

```bash
./scripts/version-check/check-bfg-version.sh --help
```

## Options

| Option            | Description                                                            |
| ----------------- | ---------------------------------------------------------------------- |
| `--create-branch` | Create a new branch with format `chore(deps): update bfg to <version>` |
| `--commit`        | Commit the changes to the current/new branch                           |
| `--dry-run`       | Show what would be done without making any changes                     |
| `--help`          | Display help message                                                   |

## Requirements

The script requires the following commands to be available:

- `curl` - For making HTTP requests to GitHub API and Maven
- `jq` - For parsing JSON responses
- `git` - For version control operations
- `sed` - For updating files

## Automated Workflow

This script is used by the GitHub Actions workflow `.github/workflows/check-bfg-version.yml`, which:

- Runs automatically every Monday at 9:00 AM UTC
- Can be triggered manually from the GitHub Actions tab
- Creates a pull request when a new version is available
- Includes release notes from the BFG Repo-Cleaner GitHub release

## How It Works

1. **Fetch Current Version**: Reads `ARG BFG_VERSION` from the Dockerfile
2. **Fetch Latest Version**: Queries GitHub API for the latest release
3. **Compare Versions**: Uses semantic versioning to check if an update is available
   - If current == latest: Reports already up-to-date
   - If current > latest: Reports potential pre-release/development version
   - If current < latest: Proceeds with update
4. **Verify Maven**: Confirms the new version exists on Maven Central
5. **Update Files**: Modifies Dockerfile and README.md with the new version
6. **Create Branch/Commit**: Optionally creates a branch and commits changes

## Output for GitHub Actions

When running in a GitHub Actions environment (detected by `$GITHUB_OUTPUT`), the script exports:

- `current_version` - The version before the update
- `latest_version` - The new version available
- `updated` - Boolean indicating if an update was performed
- `release_notes` - The release notes from GitHub

## Example Output

```text
ℹ Checking for BFG Repo-Cleaner updates...
ℹ Current version: 1.15.0
ℹ Latest version: 1.15.1
⚠ New version available: 1.15.1 (current: 1.15.0)
ℹ Checking Maven availability: https://repo1.maven.org/maven2/com/madgag/bfg/1.15.1/bfg-1.15.1.jar
✓ Version 1.15.1 is available on Maven
ℹ Fetching release notes...

Release Notes:
==============
### Bug Fixes
- Fixed issue with large binary files
- Improved performance on Windows

✓ Updated Dockerfile
✓ Updated README.md
ℹ Creating branch: chore(deps): update bfg to 1.15.1
ℹ Committing changes...
✓ Changes committed
✓ Update complete! 🎉
ℹ Updated from 1.15.0 to 1.15.1
```

## Troubleshooting

### API Rate Limiting

If you hit GitHub API rate limits, the script will display an error message. You can:

- Wait for the rate limit to reset
- Use a GitHub personal access token by setting the `GITHUB_TOKEN` environment variable:

```bash
export GITHUB_TOKEN="your_token_here"
./scripts/version-check/check-bfg-version.sh
```

### Maven Availability

Sometimes a GitHub release is published before the artifacts are available on Maven Central. The script checks for Maven availability and will exit with an error if the version isn't ready yet. Simply try again later.

### sed Compatibility

The script handles both macOS and Linux versions of `sed` automatically by detecting the operating system.

### Current Version Newer Than Latest Release

If you see a message like "Current version (X.Y.Z) is newer than latest release", this typically means:

- You're using a pre-release or development version
- You manually set a version that hasn't been officially released yet
- There's a delay in the GitHub releases API

This is intentional behavior to prevent accidental downgrades. The script will not modify files in this case.
