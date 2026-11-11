#!/bin/sh
# Print the newest release (or commit) of a GitHub repository that is at least N days old.
# Toolchain pins in generated projects must never name a release younger than 14 days
# (docs/adr/0002-dependency-cooldown.md); init-project.sh uses this script to find them.
#
# Usage: aged-version.sh [--days N] [--prefix P] OWNER/REPO
#        aged-version.sh [--days N] --commit BRANCH OWNER/REPO
#
#   Releases: the newest non-draft, non-prerelease release published at least N days ago
#   (default 14), optionally only tags starting with P (e.g. "v24." for Node 24). Printed without
#   a leading "v".
#   --commit BRANCH: the full SHA of the newest commit on BRANCH that is at least N days old.
#
# Needs an authenticated GitHub CLI (`gh`); its built-in jq does the date arithmetic, so no
# `jq`, `date` or `curl` is required. SW_NOW=<epoch seconds> replaces the current time (tests).
set -eu

die() {
    printf 'aged-version.sh: %s\n' "$1" >&2
    exit 1
}

days=14 prefix='' branch='' repo=''
while [ $# -gt 0 ]; do
    case "$1" in
        --days | --prefix | --commit)
            [ $# -ge 2 ] || die "missing value for $1"
            case "$1" in
                --days) days=$2 ;;
                --prefix) prefix=$2 ;;
                --commit) branch=$2 ;;
            esac
            shift 2
            ;;
        -*) die "unknown option $1" ;;
        *)
            [ -z "$repo" ] || die "unexpected argument $1"
            repo=$1
            shift
            ;;
    esac
done

# Values are interpolated into jq programs and URLs: allow only plain characters.
[ -n "$repo" ] || die "usage: aged-version.sh [--days N] [--prefix P | --commit BRANCH] OWNER/REPO"
case "$repo" in
    */*/* | /* | */ | *[!A-Za-z0-9._/-]*) die "repository must be OWNER/REPO, got '$repo'" ;;
    */*) ;;
    *) die "repository must be OWNER/REPO, got '$repo'" ;;
esac
case "$days" in '' | *[!0-9]*) die "--days must be a whole number, got '$days'" ;; esac
case "$prefix" in *[!A-Za-z0-9._-]*) die "--prefix may only contain letters, digits, '.', '_' and '-'" ;; esac
case "$branch" in *[!A-Za-z0-9._/-]*) die "--commit branch name has unsupported characters" ;; esac
now=${SW_NOW:-now}
case "$now" in now) ;; '' | *[!0-9]*) die "SW_NOW must be epoch seconds, got '$now'" ;; esac
command -v gh >/dev/null 2>&1 || die "the GitHub CLI (gh) is required"

cutoff="(($now) - $days * 86400 | todate)"

if [ -n "$branch" ]; then
    # `until` filters by commit date on the server; the first result is the newest such commit.
    cut=$(gh api rate_limit --jq "$cutoff") || die "$repo: could not reach the GitHub API"
    result=$(gh api -X GET "repos/$repo/commits" -f sha="$branch" -f until="$cut" -f per_page=1 \
        --jq '.[0].sha // empty') || die "$repo: could not list commits on '$branch'"
    [ -n "$result" ] || die "$repo: no commit on '$branch' at least $days days old"
    printf '%s\n' "$result"
    exit 0
fi

# One line per eligible release: "<published_at> <tag>". ISO dates sort as text.
filter="$cutoff as \$cut
    | .[]
    | select((.draft or .prerelease) | not)
    | select(.published_at != null and .published_at <= \$cut)
    | select(.tag_name | startswith(\"$prefix\"))
    | \"\(.published_at) \(.tag_name)\""

# The newest 100 releases usually contain the answer; page through the rest only if they don't.
lines=$(gh api "repos/$repo/releases?per_page=100" --jq "$filter") ||
    die "$repo: could not list releases"
if [ -z "$lines" ]; then
    lines=$(gh api --paginate "repos/$repo/releases?per_page=100" --jq "$filter") ||
        die "$repo: could not list releases"
fi
tag=$(printf '%s\n' "$lines" | sort | sed -n '$s/^[^ ]* //p')
if [ -z "$tag" ]; then
    [ -z "$prefix" ] || die "$repo: no release with a tag starting with '$prefix' at least $days days old"
    die "$repo: no release at least $days days old"
fi
printf '%s\n' "${tag#v}"
