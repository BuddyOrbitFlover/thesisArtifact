#!/bin/sh
# Regenerate SHA256SUMS and build the zip archive with README and LICENSE at the top level.
set -e
cd "$(dirname "$0")"
VERSION=${1:-v1.1}
NAME=imh-bugs-external-validity-artifact-$VERSION
find . -type f -not -path './.git/*' -not -path './dist/*' -not -name SHA256SUMS -not -name .DS_Store | sed 's|^\./||' | LC_ALL=C sort > /tmp/artifact_files.txt
: > SHA256SUMS
while read -r f; do shasum -a 256 "$f" >> SHA256SUMS; done < /tmp/artifact_files.txt
echo "SHA256SUMS: $(wc -l < SHA256SUMS | tr -d ' ') files"
mkdir -p dist && rm -f "dist/$NAME.zip"
zip -q -r "dist/$NAME.zip" . -x '.git/*' 'dist/*' '.DS_Store' '*/.DS_Store'
echo "archive: dist/$NAME.zip ($(du -h "dist/$NAME.zip" | cut -f1))"
echo "sha256:  $(shasum -a 256 "dist/$NAME.zip" | cut -d' ' -f1)"
