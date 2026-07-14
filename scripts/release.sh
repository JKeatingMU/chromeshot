#!/usr/bin/env bash
#
# release.sh — one-shot chromeshot release helper.
#
# Bumps the version, commits and pushes, creates the GitHub release (tag +
# notes), then updates and pushes the Homebrew tap formula so
# `brew upgrade chromeshot` picks it up.
#
# Usage:
#   scripts/release.sh              # bump patch (1.0.1 -> 1.0.2)
#   scripts/release.sh minor        # 1.0.1 -> 1.1.0
#   scripts/release.sh major        # 1.0.1 -> 2.0.0
#   scripts/release.sh 1.4.0        # explicit version
#
# Tap location defaults to ~/homebrew-tap; override with CHROMESHOT_TAP_DIR.
# Requires: gh (authenticated as the repo owner), curl, shasum, python3.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAP_DIR="${CHROMESHOT_TAP_DIR:-$HOME/homebrew-tap}"
FORMULA="$TAP_DIR/Formula/chromeshot.rb"
cd "$REPO_DIR"

die() { echo "error: $*" >&2; exit 1; }

# --- preflight ---------------------------------------------------------------
command -v gh    >/dev/null || die "gh not found on PATH"
command -v curl  >/dev/null || die "curl not found on PATH"
[ -f capture ]              || die "run from the chromeshot repo (capture not found)"
[ -f "$FORMULA" ]          || die "formula not found at $FORMULA (set CHROMESHOT_TAP_DIR)"
[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || die "not on the main branch"
[ -z "$(git status --porcelain)" ] || die "working tree not clean — commit or stash first"
git pull --ff-only origin main >/dev/null 2>&1 || die "could not fast-forward main from origin"

CUR="$(sed -nE 's/^__version__ = "([0-9]+\.[0-9]+\.[0-9]+)"$/\1/p' capture)"
[ -n "$CUR" ] || die "could not read __version__ from capture"

# --- compute the new version -------------------------------------------------
BUMP="${1:-patch}"
if [[ "$BUMP" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  NEW="$BUMP"
else
  IFS=. read -r MA MI PA <<<"$CUR"
  case "$BUMP" in
    major) NEW="$((MA + 1)).0.0" ;;
    minor) NEW="${MA}.$((MI + 1)).0" ;;
    patch) NEW="${MA}.${MI}.$((PA + 1))" ;;
    *)     die "bump must be one of: patch | minor | major | X.Y.Z" ;;
  esac
fi
TAG="v$NEW"
git rev-parse "$TAG" >/dev/null 2>&1 && die "tag $TAG already exists"

echo "Releasing chromeshot $CUR -> $NEW ($TAG)"

# --- bump, commit, push ------------------------------------------------------
sed -i '' -E "s/^__version__ = \".*\"$/__version__ = \"$NEW\"/" capture
python3 -c "import ast; ast.parse(open('capture').read())" || die "capture failed to parse after bump"
./capture --version | grep -q "$NEW" || die "capture --version did not report $NEW"

git add capture
git commit -q -m "Bump version to $NEW

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push -q origin main

# --- github release (creates the tag at HEAD) --------------------------------
gh release create "$TAG" --title "chromeshot $NEW" --generate-notes

# --- checksum the release tarball --------------------------------------------
TARBALL="https://github.com/JKeatingMU/chromeshot/archive/refs/tags/$TAG.tar.gz"
echo "Fetching release tarball checksum..."
SHA=""
for _ in 1 2 3 4 5; do
  if SHA="$(curl -fsSL "$TARBALL" | shasum -a 256 | awk '{print $1}')" && [ -n "$SHA" ]; then
    break
  fi
  sleep 3
done
[ -n "$SHA" ] || die "could not fetch/checksum $TARBALL"

# --- update + push the tap formula -------------------------------------------
sed -i '' -E "s#archive/refs/tags/v[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz#archive/refs/tags/$TAG.tar.gz#" "$FORMULA"
sed -i '' -E "s/sha256 \"[a-f0-9]{64}\"/sha256 \"$SHA\"/" "$FORMULA"

(
  cd "$TAP_DIR"
  git add Formula/chromeshot.rb
  git commit -q -m "chromeshot $NEW

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  git push -q origin main
)

echo
echo "Released chromeshot $NEW"
echo "  Release: https://github.com/JKeatingMU/chromeshot/releases/tag/$TAG"
echo "  Formula: updated to $TAG (sha256 $SHA)"
echo "  Install: brew update && brew upgrade chromeshot"
