#!/usr/bin/env bash
# Tests for the bootstrap and the gitnexus MCP launcher.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib.sh"
BS="$ROOT/scripts/bootstrap.sh"

# --check never mutates and exits 0
out="$(bash "$BS" --check 2>&1)"; rc=$?
assert_exit_code 0 "$rc" "bootstrap --check exits 0"

# every documented prerequisite is verified
for t in git rg jq node npm python3 gh curl uv gitnexus roborev; do
  assert_contains "$out" "$t" "check reports $t"
done

# a missing prerequisite surfaces a MISSING line, an install command, and the opt-in
out2="$(DESTRIER_FAKE_MISSING=jq bash "$BS" --check 2>&1)"; rc2=$?
assert_exit_code 0 "$rc2" "check still exits 0 with a missing tool"
assert_contains "$out2" "MISSING" "missing tool reported as MISSING"
assert_contains "$out2" "jq ->" "missing tool shows an install command"
assert_contains "$out2" "install-deps" "offers --install-deps for missing prerequisites"

# uv is an OPTIONAL (opt-in SDD) prerequisite: reported when missing, but never
# funneled into the auto-install (--install-deps) path.
out_uv="$(DESTRIER_FAKE_MISSING=uv bash "$BS" --check 2>&1)"
assert_contains "$out_uv" "optional" "uv reported as optional when missing"
if printf '%s' "$out_uv" | grep -qF 'uv ->'; then fail "uv must not enter the --install-deps path"; else echo "  ok: uv excluded from --install-deps path"; fi

# launcher with no install present -> exit 1 with guidance, no crash
empty="$(mktemp -d)"; fx="$(mktemp -d)"; fx_bad="$(mktemp -d)"
home_mono="$(mktemp -d)"; home_flat="$(mktemp -d)"; home_bad="$(mktemp -d)"
trap 'rm -rf "$empty" "$fx" "$fx_bad" "$home_mono" "$home_flat" "$home_bad"' EXIT
out3="$(DESTRIER_HOME="$empty" bash "$ROOT/scripts/gitnexus-mcp-launch.sh" 2>&1)"; rc3=$?
assert_exit_code 1 "$rc3" "launcher exits 1 when gitnexus missing"
assert_contains "$out3" "destrier-setup" "launcher tells user to run setup"

# bootstrap builds the upstream MONOREPO layout: CLI package in gitnexus/,
# gitnexus-shared/ must be installed+built FIRST (per upstream CONTRIBUTING.md
# — no npm workspaces), root package.json has no build script. The fixture's
# CLI build fails unless the shared package was built before it, encoding the
# ordering requirement. Uses a local fixture repo via the
# DESTRIER_GITNEXUS_REPO seam; roborev+curl faked missing so the roborev
# section never touches the real machine.
git -C "$fx" init -q
mkdir -p "$fx/gitnexus/scripts" "$fx/gitnexus-shared"
printf '%s\n' '{ "name": "gitnexus-monorepo", "private": true, "scripts": { "lint": "true" } }' > "$fx/package.json"
cat > "$fx/gitnexus-shared/package.json" <<'EOF'
{ "name": "gitnexus-shared", "version": "0.0.0",
  "scripts": { "build": "node -e \"require('fs').mkdirSync('dist',{recursive:true});require('fs').writeFileSync('dist/marker','ok')\"" } }
EOF
printf '%s\n' '{ "name": "gitnexus", "version": "0.0.0", "scripts": { "build": "node scripts/build.js" } }' > "$fx/gitnexus/package.json"
cat > "$fx/gitnexus/scripts/build.js" <<'EOF'
const fs = require('fs');
if (!fs.existsSync('../gitnexus-shared/dist/marker')) {
  console.error('shared package not built before CLI package');
  process.exit(1);
}
fs.mkdirSync('dist/cli', { recursive: true });
fs.writeFileSync('dist/cli/index.js', 'console.log("FAKE-GITNEXUS " + (process.argv[2] || ""))');
EOF
git -C "$fx" add -A >/dev/null && git -C "$fx" -c user.email=t@t -c user.name=t commit -qm fixture
out4="$(DESTRIER_HOME="$home_mono" DESTRIER_GITNEXUS_REPO="$fx" DESTRIER_FAKE_MISSING="roborev curl gitnexus" bash "$BS" 2>&1)"; rc4=$?
assert_exit_code 0 "$rc4" "bootstrap succeeds on monorepo layout"
assert_contains "$out4" "built at" "bootstrap reports the build location"
if [ -f "$home_mono/vendor/gitnexus/gitnexus/dist/cli/index.js" ]; then
  echo "  ok: monorepo build produced dist/cli/index.js in the gitnexus/ package"
else
  fail "monorepo build did not produce gitnexus/dist/cli/index.js"
fi

# launcher resolves the monorepo entry point and passes the mcp subcommand
out5="$(DESTRIER_HOME="$home_mono" bash "$ROOT/scripts/gitnexus-mcp-launch.sh" 2>&1)"; rc5=$?
assert_exit_code 0 "$rc5" "launcher runs against a monorepo install"
assert_contains "$out5" "FAKE-GITNEXUS mcp" "launcher execs the monorepo entry with mcp subcommand"

# launcher still resolves the legacy FLAT layout (dist at the repo root)
mkdir -p "$home_flat/vendor/gitnexus/dist/cli"
printf '%s\n' 'console.log("FAKE-FLAT " + (process.argv[2] || ""))' > "$home_flat/vendor/gitnexus/dist/cli/index.js"
out6="$(DESTRIER_HOME="$home_flat" bash "$ROOT/scripts/gitnexus-mcp-launch.sh" 2>&1)"; rc6=$?
assert_exit_code 0 "$rc6" "launcher runs against a flat install"
assert_contains "$out6" "FAKE-FLAT mcp" "launcher execs the flat entry with mcp subcommand"

# a FAILING build must not be reported as success, and bootstrap exits non-zero
git -C "$fx_bad" init -q
mkdir -p "$fx_bad/gitnexus"
printf '%s\n' '{ "name": "gitnexus-monorepo", "private": true }' > "$fx_bad/package.json"
printf '%s\n' '{ "name": "gitnexus", "version": "0.0.0", "scripts": { "build": "exit 1" } }' > "$fx_bad/gitnexus/package.json"
git -C "$fx_bad" add -A >/dev/null && git -C "$fx_bad" -c user.email=t@t -c user.name=t commit -qm fixture
out7="$(DESTRIER_HOME="$home_bad" DESTRIER_GITNEXUS_REPO="$fx_bad" DESTRIER_FAKE_MISSING="roborev curl gitnexus" bash "$BS" 2>&1)"; rc7=$?
if [ "$rc7" != 0 ]; then echo "  ok: bootstrap exits non-zero on build failure (exit $rc7)"; else fail "bootstrap must exit non-zero on build failure"; fi
if printf '%s' "$out7" | grep -qF 'built at'; then fail "bootstrap must not claim success on build failure"; else echo "  ok: no success claim on build failure"; fi
assert_contains "$out7" "build failed" "bootstrap reports the build failure"

# .mcp.json valid and points at the launcher
if command -v jq >/dev/null 2>&1; then
  jq -e '.mcpServers.gitnexus.command' "$ROOT/.mcp.json" >/dev/null 2>&1
  assert_exit_code 0 $? ".mcp.json registers gitnexus"
fi

pass "bootstrap"
