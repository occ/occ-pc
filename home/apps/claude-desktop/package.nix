{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  addDriverRunpath,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libcap_ng,
  libGL,
  libdrm,
  libgbm,
  libseccomp,
  libglvnd,
  libnotify,
  libpulseaudio,
  libsecret,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxshmfence,
  libxtst,
  libxkbcommon,
  nspr,
  nss,
  pango,
  systemd,
  vulkan-loader,
  wayland,
  xdg-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "1.19367.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${finalAttrs.version}_amd64.deb";
    hash = "sha256-dvVwcwwRhZJOJCPF+IonvsF8HnrbBV7NCUAaDpOpKZs=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libcap_ng # virtiofsd
    libdrm
    libgbm
    libnotify
    libseccomp # virtiofsd
    libsecret
    libuuid
    libxkbcommon
    nspr
    nss
    pango
    (lib.getLib systemd)
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxshmfence
    libxtst
    stdenv.cc.cc.lib
  ];

  # Loaded with dlopen() at runtime rather than linked, so autoPatchelf can't
  # see them; they go on LD_LIBRARY_PATH in the wrapper instead.
  runtimeLibs = [
    libGL
    libglvnd
    libpulseaudio
    vulkan-loader
    wayland
  ];

  unpackCmd = "dpkg-deb -x $curSrc source";
  sourceRoot = "source";

  dontConfigure = true;
  dontBuild = true;

  # The wrapper below already sets everything up; let wrapGAppsHook only
  # contribute its GTK/GSettings env vars.
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin $out/share
    cp -r usr/lib/claude-desktop $out/lib/
    cp -r usr/share/applications usr/share/icons $out/share/

    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.runtimeLibs}:${addDriverRunpath.driverLink}/lib" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --add-flags "--ozone-platform-hint=auto"

    substituteInPlace $out/share/applications/com.anthropic.Claude.desktop \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    runHook postInstall
  '';

  meta = {
    description = "Desktop application for Claude.ai, with Chat, Cowork, and Claude Code";
    homepage = "https://claude.ai/download";
    license = lib.licenses.unfree;
    mainProgram = "claude-desktop";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
