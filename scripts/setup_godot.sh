#!/usr/bin/env bash
# Install a headless-capable Godot 4.7 into ~/.local/bin so scripts/run_sim_tests.sh
# can execute the sim test suite. Idempotent. Works in a Claude Code remote
# container ONLY if the environment's network policy allows one of the sources
# below (see CLAUDE.md "Running tests" + memory/open-risks.md).
set -euo pipefail

# 4.7.1 = the standardized target (project targets 4.7 features; owner ruling
# 2026-07-20). NOTE: the SourceForge mirror retains only the ~5 most recent
# releases; if this version vanishes, check
# https://sourceforge.net/projects/godot-engine.mirror/files/ and pick the
# closest 4.7.x/4.x patch (the sim suite is GDScript-only and forward-compatible).
VERSION="4.7.1-stable"
BIN_DIR="${HOME}/.local/bin"
DEST="${BIN_DIR}/godot"

# Pinned SHA-256 of Godot_v4.7.1-stable_linux.x86_64.zip (supply-chain hardening).
# PROVENANCE (honest): the official checksum endpoints (downloads.godotengine.org /
# GitHub SHA512-SUMS.txt) are unreachable through the session proxy, so this hash
# was computed 2026-07-20 from the SourceForge-mirror artifact — trust-on-first-use.
# The extracted binary is bit-identical to the binary the whole 200+ test suite has
# run on. TODO(owner): cross-verify against the official SHA512-SUMS.txt from
# godotengine.org when on an open network, then delete this note.
ZIP_SHA256="c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba"

if command -v godot >/dev/null 2>&1; then
	echo "godot already on PATH: $(godot --version 2>/dev/null || true)"
	exit 0
fi
if [ -x "${DEST}" ]; then
	echo "godot already installed at ${DEST}: $("${DEST}" --version 2>/dev/null || true)"
	echo "add to PATH: export PATH=\"${BIN_DIR}:\$PATH\""
	exit 0
fi

# SourceForge mirror first — VERIFIED WORKING through the session proxy 2026-07-15
# (downloads.godotengine.org is only a redirector; GitHub release assets are
# blocked unless the env allowlists the githubusercontent asset domains).
URLS=(
	"https://sourceforge.net/projects/godot-engine.mirror/files/${VERSION}/Godot_v${VERSION}_linux.x86_64.zip/download"
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
			got_sha="$(sha256sum "${TMP}/godot.zip" | cut -d' ' -f1)"
			if [ "${got_sha}" = "${ZIP_SHA256}" ]; then
				ok="yes"
				break
			fi
			echo "  CHECKSUM MISMATCH: got ${got_sha}"
			echo "  expected           ${ZIP_SHA256} — refusing this artifact, next source"
			continue
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
