#!/usr/bin/env bash
# Emits a plain-text digest of GitHub activity for one user/org over a date
# range: repos created in range (with README excerpts) and PRs opened against
# repos the user doesn't own. Requires `gh` (authenticated) and `jq`.
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "Usage: $0 <github-user> <since:YYYY-MM-DD> <until:YYYY-MM-DD>" >&2
  exit 1
fi

user="$1"
since="$2"
until_date="$3"
until_ts="${until_date}T23:59:59Z"

echo "# GitHub activity: $user, $since to $until_date"
echo

echo "## Repos created in range"
echo
repos_json=$(gh repo list "$user" --limit 300 \
  --json name,createdAt,description,isPrivate,isFork,primaryLanguage,url \
  --jq "[.[] | select(.createdAt >= \"$since\" and .createdAt <= \"$until_ts\")] | sort_by(.createdAt)")

echo "$repos_json" | jq -r '.[] |
  "\(.createdAt[:10])  \(.name)  [\(if .isPrivate then "private" else "public" end)\(if .isFork then ", fork" else "" end)]  \(.primaryLanguage.name // "?")  \(.description // "")"'

echo
echo "## README excerpts"
echo "$repos_json" | jq -r '.[].name' | while read -r repo; do
  echo
  echo "### $repo"
  gh api "repos/$user/$repo/readme" --jq '.content' 2>/dev/null \
    | base64 -d 2>/dev/null | head -c 500 \
    || echo "(no README)"
  echo
done

echo
echo "## External PRs (repos not owned by $user)"
gh search prs --author "$user" --created "$since..$until_date" --limit 300 \
  --json title,url,repository,createdAt \
  --jq "[.[] | select(.repository.nameWithOwner | startswith(\"$user/\") | not)]
        | sort_by(.createdAt)
        | .[] | \"\(.createdAt[:10])  \(.repository.nameWithOwner)  \(.title)  \(.url)\""
