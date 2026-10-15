{ lib, stdenvNoCC, python3, makeWrapper }:

let
  python = python3.withPackages (packages: [ packages.psutil ]);
in
stdenvNoCC.mkDerivation {
  pname = "oseasy-video";
  version = "0.1.0";

  # Include only runtime files, not .git, virtualenvs, captures or bytecode.
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../play.py
      ../laptop_proxy.py
      ./relay.py
      (lib.fileset.fileFilter
        (file: file.hasExt "py" || file.name == "mock-thumbnail.jpg")
        ../oseasy_helper)
    ];
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    PYTHONDONTWRITEBYTECODE=1 ${python}/bin/python3 -c 'import laptop_proxy, play; from oseasy_helper import cli, video; import nixos.relay'
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    runtime="$out/share/oseasy-helper"
    mkdir -p "$runtime/nixos" "$out/bin"
    cp -r oseasy_helper "$runtime/"
    install -m644 play.py laptop_proxy.py "$runtime/"
    install -m644 nixos/relay.py "$runtime/nixos/relay.py"

    makeWrapper ${python}/bin/python3 "$out/bin/oseasy-helper" \
      --add-flags "-m oseasy_helper" \
      --prefix PYTHONPATH : "$runtime"
    makeWrapper ${python}/bin/python3 "$out/bin/oseasy-play-raw" \
      --add-flags "$runtime/play.py" \
      --prefix PYTHONPATH : "$runtime"
    makeWrapper ${python}/bin/python3 "$out/bin/oseasy-proxy" \
      --add-flags "$runtime/laptop_proxy.py" \
      --prefix PYTHONPATH : "$runtime"
    makeWrapper ${python}/bin/python3 "$out/bin/oseasy-relay" \
      --add-flags "$runtime/nixos/relay.py" \
      --prefix PYTHONPATH : "$runtime"
    runHook postInstall
  '';

  meta = {
    description = "OsEasy classroom H.264 receiver and HTTP video relay";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
