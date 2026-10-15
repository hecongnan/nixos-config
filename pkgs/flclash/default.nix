{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, gtk3
, glib
, libayatana-appindicator
, keybinder3
, libx11
, libepoxy
, libsecret
, systemd
, openssl
, libGL
, wayland
, fontconfig
}:
stdenv.mkDerivation {
  pname = "flclash-bin";
  version = "0.8.99";
  src = fetchurl {
    url = "https://github.com/chen08209/FlClash/releases/download/v0.8.99/FlClash-0.8.99-linux-amd64.deb";
    hash = "sha256-3Vtg1oqvsPdiaS1JcFD9Lty913L0xTgioG6yg3y/iF8=";
  };
  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];
  buildInputs = [
    gtk3
    glib
    libayatana-appindicator
    keybinder3
    libx11
    libepoxy
    libsecret
    systemd
    openssl
    libGL
    wayland
    fontconfig
    stdenv.cc.cc.lib
  ];
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';
  dontBuild = true;
  # The helper embeds the original Core hash; do not strip/patch this static ELF.
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/opt" "$out/bin" "$out/share"
    cp -r opt/FlClash "$out/opt/"
    # Android-only JNI library is absent from Linux's NativeAssetsManifest.
    # Keeping it would introduce an unused full JVM solely for autoPatchelf.
    rm "$out/opt/FlClash/lib/libdartjni.so"
    cp -r usr/share/. "$out/share/"
    substituteInPlace "$out/share/applications/FlClash.desktop" \
      --replace-fail 'Exec=FlClash %U' "Exec=$out/bin/FlClash %U"
    makeWrapper "$out/opt/FlClash/FlClash" "$out/bin/FlClash" \
      --prefix LD_LIBRARY_PATH : "$out/opt/FlClash/lib:${lib.makeLibraryPath [ libGL libsecret keybinder3 libayatana-appindicator ]}"
    # Verify the privileged helper will still accept the bundled Core.
    expected=$(sed -n 's/.*"coreSha256":"\([^"]*\)".*/\1/p' "$out/opt/FlClash/manifest.json")
    actual=$(sha256sum "$out/opt/FlClash/FlClashCore" | cut -d ' ' -f 1)
    test "$expected" = "$actual"
    runHook postInstall
  '';
  postFixup = ''
    expected=$(sed -n 's/.*"coreSha256":"\([^"]*\)".*/\1/p' "$out/opt/FlClash/manifest.json")
    actual=$(sha256sum "$out/opt/FlClash/FlClashCore" | cut -d ' ' -f 1)
    test "$expected" = "$actual"
  '';
  meta = {
    description = "FlClash desktop client with its matching Linux TUN helper";
    homepage = "https://github.com/chen08209/FlClash";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "FlClash";
  };
}
