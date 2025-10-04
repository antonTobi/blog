#!/usr/bin/env bash
# Helper to create a new Hugo post, open editor, stage, commit and push

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v hugo >/dev/null 2>&1; then
  echo "hugo is not installed or not in PATH. Please install Hugo to use this script." >&2
  exit 1
fi

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <slug> [Title of the post]" >&2
  exit 1
fi

SLUG="$1"
shift || true
TITLE="$*"

POST_PATH="content/posts/${SLUG}.md"

if [ -e "$POST_PATH" ]; then
  echo "Post already exists: $POST_PATH" >&2
  exit 1
fi

echo "Creating new post: $POST_PATH"
hugo new "posts/${SLUG}.md"

# If user provided a title, replace the generated title in front-matter
if [ -n "$TITLE" ]; then
  # support TOML front-matter (PaperMod default)
  # replace first title = "..." occurrence
  sed -i "0,/^title =/s//title = \"$(printf '%s' "$TITLE" | sed 's/[&/]/\\&/g')\"/" "$POST_PATH" || true
fi

EDITOR_CMD="${EDITOR:-${VISUAL:-nano}}"
echo "Opening $POST_PATH in editor ($EDITOR_CMD). Save and exit to continue..."
$EDITOR_CMD "$POST_PATH"

git add "$POST_PATH"
COMMIT_MSG="Add post: ${TITLE:-$SLUG}"
git commit -m "$COMMIT_MSG"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Pushing to origin/$BRANCH..."
git push origin "$BRANCH"

echo "Done. New post created and pushed: $POST_PATH"
