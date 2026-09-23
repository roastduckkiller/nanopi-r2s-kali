#!/usr/bin/env bash
# User-local Node + Pi installation. Does not write model credentials.
set -Eeuo pipefail
NODE_VERSION=24.21.0
PI_VERSION=0.87.1
if [[ ${1:-} == --help ]]; then
 echo "Usage: $0 (as an ordinary user on ARM64 Linux)"; exit 0
fi
[[ $# == 0 && $EUID != 0 && $(uname -s) == Linux && $(uname -m) == aarch64 ]] || {
 echo 'Run without sudo on ARM64 Linux' >&2; exit 1;
}
for cmd in curl sha256sum python3; do command -v "$cmd" >/dev/null; done
BASE=$HOME/.local
DEST=$BASE/opt/node-v$NODE_VERSION-linux-arm64
[[ ! -e $DEST && ! -e $BASE/bin/pi ]] || { echo 'Node target or Pi already exists; refusing to overwrite' >&2; exit 1; }
for exe in node npm npx; do
 [[ ! -e $BASE/bin/$exe && ! -L $BASE/bin/$exe ]] || { echo "$BASE/bin/$exe already exists" >&2; exit 1; }
done
WORK=$(mktemp -d)
trap 'rm -rf -- "$WORK"' EXIT
FILE=node-v$NODE_VERSION-linux-arm64.tar.xz
URL=https://nodejs.org/dist/v$NODE_VERSION
curl --fail --location --retry 3 "$URL/$FILE" -o "$WORK/$FILE"
curl --fail --location --retry 3 "$URL/SHASUMS256.txt" -o "$WORK/SHASUMS256.txt"
(cd "$WORK"; awk -v file="$FILE" '$2 == file {print}' SHASUMS256.txt > CHECKSUM; [[ -s CHECKSUM ]]; sha256sum -c CHECKSUM)
mkdir -p "$BASE/opt" "$BASE/bin"
python3 - "$WORK/$FILE" "$BASE/opt" <<'PYTHON'
import sys, tarfile
# data_filter is supported by the Python version shipped in the tested Kali image.
with tarfile.open(sys.argv[1]) as archive:
    archive.extractall(sys.argv[2], filter="data")
PYTHON
for exe in node npm npx; do ln -s "$DEST/bin/$exe" "$BASE/bin/$exe"; done
export PATH="$BASE/bin:$PATH"
npm install --global --prefix "$BASE" --ignore-scripts --no-audit --no-fund \
 "@earendil-works/pi-coding-agent@$PI_VERSION"
node --version
pi --version
printf '\nInstalled. Ensure ~/.local/bin is on PATH in your login shell.\n'
printf 'Next: follow docs/pi-agent.md to configure your own model endpoint.\n'
