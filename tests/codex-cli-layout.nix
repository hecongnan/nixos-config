# Exercise the actual install recipe with a small archive, without downloading
# the release or pretending this is a functional test of the official binary.
{ pkgs }:
let
  fixture = pkgs.runCommand "codex-cli-layout-fixture.tar.zst" {
    nativeBuildInputs = [ pkgs.zstd ];
  } ''
    mkdir -p package/bin package/codex-resources package/codex-path
    cat > package/bin/codex <<'SH'
#!/bin/sh
echo packaging-fixture
SH
    chmod +x package/bin/codex
    cp package/bin/codex package/bin/codex-code-mode-host
    echo '{}' > package/codex-package.json
    tar --zstd -cf "$out" -C package .
  '';
  package = (pkgs.callPackage ../pkgs/codex-cli { }).overrideAttrs (_: {
    src = fixture;
  });
in
pkgs.runCommand "codex-cli-layout-check" { } ''
  test "$(${package}/bin/codex)" = packaging-fixture
  test -x ${package}/bin/codex-code-mode-host
  test -d ${package}/codex-resources
  test -d ${package}/codex-path
  test -f ${package}/codex-package.json
  test ! -e ${package}/env-vars
  touch "$out"
''
