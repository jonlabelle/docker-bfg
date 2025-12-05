#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="rtyley/bfg-repo-cleaner"
MAVEN_BASE_URL="https://repo1.maven.org/maven2/com/madgag/bfg"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCKERFILE="${PROJECT_DIR}/Dockerfile"
README="${PROJECT_DIR}/README.md"

# Parse arguments
CREATE_BRANCH=false
COMMIT_CHANGES=false
DRY_RUN=false
BRANCH_NAME=""

while [[ ${#} -gt 0 ]]; do
  case ${1} in
  --create-branch)
    CREATE_BRANCH=true
    shift
    ;;
  --commit)
    COMMIT_CHANGES=true
    shift
    ;;
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --branch-name)
    BRANCH_NAME="${2}"
    shift 2
    ;;
  --help)
    echo "Usage: ${0} [OPTIONS]"
    echo ""
    echo "Check for new BFG Repo-Cleaner versions and optionally update the project."
    echo ""
    echo "Options:"
    echo "  --create-branch       Create a new branch for the update"
    echo "  --commit              Commit the changes"
    echo "  --branch-name <name>  Specify custom branch name (default: chore-deps-update-bfg-<version>)"
    echo "  --dry-run             Show what would be done without making changes"
    echo "  --help                Show this help message"
    exit 0
    ;;
  *)
    echo "Unknown option: ${1}"
    echo "Use --help for usage information"
    exit 1
    ;;
  esac
done

log_info() {
  echo -e "${BLUE}ℹ${NC} ${1}"
}

log_success() {
  echo -e "${GREEN}✓${NC} ${1}"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} ${1}"
}

log_error() {
  echo -e "${RED}✗${NC} ${1}"
}

# Get current version from Dockerfile
get_current_version() {
  grep "ARG BFG_VERSION=" "$DOCKERFILE" | cut -d'=' -f2
}

# Get latest version from GitHub releases
get_latest_version() {
  local response
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    response=$(curl -sS -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/$GITHUB_REPO/releases/latest")
  else
    response=$(curl -sS "https://api.github.com/repos/$GITHUB_REPO/releases/latest")
  fi

  if ! echo "$response" | jq -e '.tag_name' >/dev/null 2>&1; then
    log_error "Failed to fetch latest release from GitHub API"
    if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
      log_error "API message: $(echo "$response" | jq -r '.message')"
    fi
    return 1
  fi

  # Remove 'v' prefix from tag name
  echo "$response" | jq -r '.tag_name' | sed 's/^v//'
}

# Get release notes from GitHub
get_release_notes() {
  local version=${1}
  local response

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    response=$(curl -sS -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${GITHUB_REPO}/releases/tags/v${version}")
  else
    response=$(curl -sS "https://api.github.com/repos/${GITHUB_REPO}/releases/tags/v${version}")
  fi

  if ! echo "$response" | jq -e '.body' >/dev/null 2>&1; then
    log_error "Failed to fetch release notes for version v${version} from GitHub API"
    if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
      log_error "API message: $(echo "$response" | jq -r '.message')"
    fi
    return 1
  fi

  echo "$response" | jq -r '.body'
}

# Check if version exists on Maven repository
check_maven_availability() {
  local version=${1}
  local url="${MAVEN_BASE_URL}/${version}/bfg-${version}.jar"

  log_info "Checking Maven availability: ${url}"

  if curl -sSf -I "${url}" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Update Dockerfile
update_dockerfile() {
  local new_version=${1}

  if [[ "${DRY_RUN}" == true ]]; then
    log_info "[DRY RUN] Would update BFG_VERSION in ${DOCKERFILE} to ${new_version}"
    return 0
  fi

  if [[ "${OSTYPE}" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^ARG BFG_VERSION=.*/ARG BFG_VERSION=${new_version}/" "${DOCKERFILE}"
  else
    # Linux
    sed -i "s/^ARG BFG_VERSION=.*/ARG BFG_VERSION=${new_version}/" "${DOCKERFILE}"
  fi

  log_success "Updated Dockerfile"
}

# Update README
update_readme() {
  local new_version=${1}

  if [[ "${DRY_RUN}" == true ]]; then
    log_info "[DRY RUN] Would update version in ${README} to ${new_version}"
    return 0
  fi

  if [[ "${OSTYPE}" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|\*\*Current BFG Version:\*\* \[.*\](https://github.com/rtyley/bfg-repo-cleaner/releases/tag/v.*)|**Current BFG Version:** [${new_version}](https://github.com/rtyley/bfg-repo-cleaner/releases/tag/v${new_version})|" "${README}"
  else
    # Linux
    sed -i "s|\*\*Current BFG Version:\*\* \[.*\](https://github.com/rtyley/bfg-repo-cleaner/releases/tag/v.*)|**Current BFG Version:** [${new_version}](https://github.com/rtyley/bfg-repo-cleaner/releases/tag/v${new_version})|" "${README}"
  fi

  log_success "Updated README.md"
}

# Compare two version strings
# Returns: 0 if $1 > $2, 1 if $1 == $2, 2 if $1 < $2
compare_versions() {
  local version1=${1}
  local version2=${2}

  if [[ "${version1}" == "${version2}" ]]; then
    return 1
  fi

  # Use sort -V for semantic version comparison
  local sorted
  sorted=$(printf '%s\n%s' "${version1}" "${version2}" | sort -V | head -n1)

  if [[ "${sorted}" == "${version1}" ]]; then
    # version1 is older (or equal)
    return 2
  else
    # version1 is newer
    return 0
  fi
}

# Create branch and commit changes
create_branch_and_commit() {
  local new_version=${1}
  local branch_name="${BRANCH_NAME:-chore-deps-update-bfg-${new_version}}"

  if [[ "${DRY_RUN}" == true ]]; then
    log_info "[DRY RUN] Would create branch: ${branch_name}"
    log_info "[DRY RUN] Would commit changes"
    return 0
  fi

  cd "${PROJECT_DIR}"

  if [[ "${CREATE_BRANCH}" == true ]]; then
    log_info "Creating branch: ${branch_name}"
    git checkout -b "${branch_name}"
  fi

  if [[ "${COMMIT_CHANGES}" == true ]]; then
    log_info "Committing changes..."
    git add "${DOCKERFILE}" "${README}"
    git commit -m "chore(deps): update bfg to ${new_version}"
    log_success "Changes committed"

    if [[ "${CREATE_BRANCH}" == true ]]; then
      log_info "To push this branch, run: git push -u origin \"${branch_name}\""
    fi
  fi
}

# Main execution
main() {
  log_info "Checking for BFG Repo-Cleaner updates..."

  # Check required commands
  for cmd in curl jq git sed; do
    if ! command -v "${cmd}" &>/dev/null; then
      log_error "Required command not found: ${cmd}"
      exit 1
    fi
  done

  # Get current version
  CURRENT_VERSION=$(get_current_version)
  log_info "Current version: ${CURRENT_VERSION}"

  # Get latest version
  LATEST_VERSION=$(get_latest_version)
  if [[ -z "${LATEST_VERSION}" ]]; then
    log_error "Failed to get latest version"
    exit 1
  fi
  log_info "Latest version: ${LATEST_VERSION}"

  # Compare versions
  set +e # Temporarily disable exit on error to capture return code
  compare_versions "${CURRENT_VERSION}" "${LATEST_VERSION}"
  local comparison=$?
  set -e # Re-enable exit on error

  case ${comparison} in
  0)
    # Current version is newer than latest release
    log_warning "Current version (${CURRENT_VERSION}) is newer than latest release (${LATEST_VERSION})"
    log_info "This might indicate a pre-release or development version"
    exit 0
    ;;
  1)
    # Versions are equal
    log_success "Already on the latest version (${CURRENT_VERSION})"
    exit 0
    ;;
  2)
    # Latest version is newer - proceed with update
    log_warning "New version available: ${LATEST_VERSION} (current: ${CURRENT_VERSION})"
    ;;
  esac

  # Check Maven availability
  if ! check_maven_availability "${LATEST_VERSION}"; then
    log_error "Version ${LATEST_VERSION} not yet available on Maven repository"
    log_warning "The release might be too new. Please try again later."
    exit 1
  fi
  log_success "Version ${LATEST_VERSION} is available on Maven"

  # Get release notes
  log_info "Fetching release notes..."
  RELEASE_NOTES=$(get_release_notes "${LATEST_VERSION}")

  if [[ -n "${RELEASE_NOTES}" ]]; then
    echo ""
    echo "Release Notes:"
    echo "=============="
    echo "${RELEASE_NOTES}"
    echo ""
  fi

  # Update files
  update_dockerfile "${LATEST_VERSION}"
  update_readme "${LATEST_VERSION}"

  # Create branch and/or commit if requested
  if [[ "${CREATE_BRANCH}" == true ]] || [[ "${COMMIT_CHANGES}" == true ]]; then
    create_branch_and_commit "${LATEST_VERSION}"
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    log_info "[DRY RUN] No actual changes were made"
  else
    log_success "Update complete! 🎉"
    log_info "Updated from ${CURRENT_VERSION} to ${LATEST_VERSION}"
  fi

  # Export version for GitHub Actions
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      echo "current_version=${CURRENT_VERSION}"
      echo "latest_version=${LATEST_VERSION}"
      echo "updated=true"
      echo "release_notes<<EOF"
      echo "${RELEASE_NOTES}"
      echo "EOF"
    } >>"${GITHUB_OUTPUT}"
  fi
}

main "$@"
