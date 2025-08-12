# Improved PTGui packaging with robust version handling and conditional Wayland->X11 fallback
{
  pkgs,
  lib ? pkgs.lib,
  src,
  # Visible label in menus / desktop files (what users see)
  versionLabel ? "Pro 13.2",
  # Optional purely-numeric upstream version (e.g., "13.2"). If omitted, parsed from versionLabel.
  upstreamVersion ? null,
  # Optional override for X11 fallback behavior (true/false). If null, auto policy applies.
  forceX11 ? null,
  ...
}:
with pkgs; let
  # Extract first "digits[.digits]" from versionLabel; fallback to "0"
  # Use POSIX-compatible regex (no lazy quantifiers or non-capturing groups)
  derivedSemver = let
    m = builtins.match ".*([0-9]+(\\.[0-9]+)?).*" versionLabel;
  in
    if m == null
    then "0"
    else builtins.elemAt m 0;

  effectiveSemver =
    if upstreamVersion == null
    then derivedSemver
    else upstreamVersion;

  # Default policy: for v13+ force X11 when running under Wayland.
  autoForceX11 = lib.versionAtLeast effectiveSemver "13";
  useForceX11 =
    if forceX11 == null
    then autoForceX11
    else forceX11;

  versionhash = builtins.hashString "sha1" versionLabel;
in
  stdenvNoCC.mkDerivation {
    pname = "ptgui";
    # Keep the user-facing label
    version = versionLabel;
    inherit src;

    nativeBuildInputs = [
      autoPatchelfHook
      wrapGAppsHook
      makeWrapper
    ];

    buildInputs = [
      udev
      alsa-lib
      egl-wayland
      libGL
      eglexternalplatform
      expat
      gtk3
      gdk-pixbuf
      glib
      cairo
      libGLU
      harfbuzz
      pango
      atk
      wayland
      libxkbcommon
      dbus
      ocl-icd
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libICE
      xorg.libSM
      xorg.libXext
      xorg.libXtst
    ];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      tar --strip-components=1 -xzf "$src"
    '';

    installPhase = ''
          set +x
          runHook preInstall

          mkdir -p "$out/opt/ptgui" "$out/bin" "$out/share/applications" "$out/share/mime/packages"
          cp -r * "$out/opt/ptgui"

          # Wrap binaries so terminal and desktop launches behave the same.
          makeWrapper "$out/opt/ptgui/PTGui" "$out/bin/PTGui" \
            ${lib.optionalString useForceX11 ''--run 'if [ "''${XDG_SESSION_TYPE:-}" = wayland ]; then export GDK_BACKEND=x11; fi' ''}

          makeWrapper "$out/opt/ptgui/PTGuiViewer" "$out/bin/PTGuiViewer"

          cat > "$out/share/applications/newhouse-ptgui-${versionhash}.desktop" <<EOF
      [Desktop Entry]
      Name=PTGui ${versionLabel}
      Comment=PTGui Stitching Software
      Keywords=panorama;stitching;stitch;stitcher;panoramas;
      Exec="$out/bin/PTGui" %F
      Icon=$out/opt/ptgui/ptgui_icon.png
      Terminal=false
      Type=Application
      Categories=Graphics
      MimeType=application/x-ptguiproject;application/x-ptguibatchlist;image/tiff;image/jpeg;image/png;image/x-exr;image/x-canon-crw;image/x-canon-cr2;image/x-canon-cr3;image/x-nikon-nef;image/x-fuji-raf;image/x-sigma-x3f;image/x-minolta-mrw;image/x-sony-srf;image/x-adobe-dng;image/x-olympus-orf;image/x-sony-arw;image/x-pentax-pef;image/x-kodak-dcr;image/x-sony-sr2;image/x-gopro-gpr;image/x-panasonic-raw
      EOF

          cat > "$out/share/applications/newhouse-ptguiviewer-${versionhash}.desktop" <<EOF
      [Desktop Entry]
      Name=PTGui Viewer ${versionLabel}
      Comment=Viewer for spherical panoramas
      Keywords=panorama;panoramas;viewer;PTGui;
      Exec="$out/bin/PTGuiViewer" %F
      Icon=$out/opt/ptgui/ptguiviewer_icon.png
      Terminal=false
      Type=Application
      StartupNotify=false
      Categories=Graphics
      MimeType=image/tiff;image/jpeg;image/png;image/x-exr
      EOF

          cat > "$out/share/mime/packages/newhouse-ptguimimetypes.xml" <<'EOF'
      <?xml version="1.0"?>
      <mime-info xmlns='http://www.freedesktop.org/standards/shared-mime-info'>
        <mime-type type="application/x-ptguiproject">
          <comment>PTGui project file</comment>
          <glob pattern="*.pts"/>
        </mime-type>
        <mime-type type="application/x-ptguibatchlist">
          <comment>PTGui batch list</comment>
          <glob pattern="*.ptgbatch"/>
        </mime-type>
      </mime-info>
      EOF

          runHook postInstall
    '';

    meta = with lib; {
      homepage = "https://www.ptgui.com/";
      description = "PTGui panoramic photo stitching software (binary distribution)";
      longDescription = ''
        PTGui panoramic photo stitching software packaged for Nix.
        This derivation wraps the vendor binaries and adjusts environment variables
        for Wayland compatibility when appropriate.
      '';
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      license = licenses.unfree;
      platforms = platforms.linux;
      mainProgram = "PTGui";
    };
  }
