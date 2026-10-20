# Official standalone package: includes the CLI, code-mode host and resources.
{ lib, stdenvNoCC, fetchurl, zstd }:
stdenvNoCC.mkDerivation {
  pname = "codex-cli";
  version = "0.162.1";
  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v0.162.1/codex-package-x86_64-unknown-linux-musl.tar.zst";
    hash = "sha256-vSTQK+Z4iUtHvFZb0tqNR6BeOn3Qtu9mqpVymbJOyPI=";
  };
  nativeBuildInputs = [ zstd ];
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    # Accept both a top-level package directory and a flat upstream archive.
    package_root=$(dirname "$(find . -name codex-package.json -print -quit)")
    test -f "$package_root/bin/codex"
    test -f "$package_root/bin/codex-code-mode-host"
    mkdir -p "$out"
    for item in bin codex-resources codex-path codex-package.json; do
      cp -a "$package_root/$item" "$out/$item"
    done
    chmod -R u+w "$out"
    chmod +x "$out/bin/codex" "$out/bin/codex-code-mode-host"
    runHook postInstall
  '';
  meta = {
    description = "Pinned official Codex CLI standalone distribution";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
