#!/usr/bin/env bash
# Install a headless-capable Godot 4.5 into ~/.local/bin so scripts/run_sim_tests.sh
# can execute the sim test suite. Idempotent. Works in a Claude Code remote
# container ONLY if the environment's network policy allows one of the sources
# below (see CLAUDE.md "Running tests" + memory/open-risks.md).
set -euo pipefail

VERSION="4.5-stable"
BIN_DIR="${HOME}/.local/bin"
DEST="${BIN_DIR}/godot"

if command -v godot >/dev/null 2>&1; then
	echo "godot already on PATH: $(godot --version 2>/dev/null || true)"
	exit 0
fi
if [ -x "${DEST}" ]; then
	echo "godot already installed at ${DEST}: $("${DEST}" --version 2>/dev/null || true)"
	echo "add to PATH: export PATH=\"${BIN_DIR}:\$PATH\""
	exit 0
fi

URLS=(
	"https://downloads.godotengine.org/godot/4.5/Godot_v${VERSION}_linux.x86_64.zip"
	"https://github.com/godotengine/godot-builds/releases/download/${VERSION}/Godot_v${VERSION}_linux.x86_64.zip"
	"https://github.com/godotengine/godot/releases/download/${VERSION}/Godot_v${VERSION}_linux.x86_64.zip"
)

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
ok=""
for url in "${URLS[@]}"; do
	echo "trying ${url}"
	if curl -fsSL -o "${TMP}/godot.zip" "${url}"; then
		if unzip -tq "${TMP}/godot.zip" >/dev/null 2>&1; then
			ok="yes"
			break
		fi
		echo "  downloaded file is not a valid zip (proxy block page?) — next source"
	else
		echo "  download failed — next source"
	fi
done

if [ -z "${ok}" ]; then
	echo "FAIL: no source reachable. In a Claude Code environment, allow the domain"
	echo "downloads.godotengine.org (or GitHub release assets) in the network policy,"
	echo "or add the godotengine/godot-builds repo to the session (add_repo)."
	exit 1
fi

mkdir -p "${BIN_DIR}"
unzip -o -q "${TMP}/godot.zip" -d "${TMP}"
mv "${TMP}/Godot_v${VERSION}_linux.x86_64" "${DEST}"
chmod +x "${DEST}"
echo "installed: ${DEST}"
"${DEST}" --version
echo "If ~/.local/bin is not on PATH: export PATH=\"${BIN_DIR}:\$PATH\" (or set GODOT_BIN=${DEST})"
