# To install PTGui in NixOS: see default.nix
{
  pkgs,
  src,
  version,
  ...
}:
with pkgs; let
  versionhash = builtins.hashString "sha1" version;
  # Keep the simple heuristic but we’ll wrap the binary instead of stuffing env into Exec
  isv13 = (builtins.match ".*13\\..*" version) != null;
in
  stdenvNoCC.mkDerivation {
    inherit version src;
    pname = "ptgui";

    # Add wrappers for GTK env and for setting GDK_BACKEND on v13
    nativeBuildInputs = [autoPatchelfHook wrapGAppsHook makeWrapper];

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

    # Unpack and strip the top-level directory
    unpackPhase = ''
      tar --strip-components=1 -xzf "$src"
    '';

    installPhase = ''
          set +x
          runHook preInstall

          mkdir -p "$out/opt/ptgui" "$out/bin" "$out/share/applications" "$out/share/mime/packages"
          cp -r * "$out/opt/ptgui"

          # Link raw binaries first…
          ln -s "$out/opt/ptgui/PTGui"       "$out/bin/PTGui"
          ln -s "$out/opt/ptgui/PTGuiViewer" "$out/bin/PTGuiViewer"

          # …then wrap PTGui so GDK_BACKEND is x11 for v13 (Wayland compatibility)
          if ${
        if isv13
        then "true"
        else "false"
      }; then
            rm "$out/bin/PTGui"
            makeWrapper "$out/opt/ptgui/PTGui" "$out/bin/PTGui" \
              --set GDK_BACKEND x11
          fi

          cat > "$out/share/applications/newhouse-ptgui-${versionhash}.desktop" <<'EOF'
      [Desktop Entry]
      Name=PTGui ${version}
      Comment=PTGui Stitching Software
      Keywords=panorama;stitching;stitch;stitcher;panoramas;
      Exec="$out/bin/PTGui" %F
      Icon=$out/opt/ptgui/ptgui_icon.png
      Terminal=false
      Type=Application
      Categories=Graphics
      MimeType=application/x-ptguiproject;application/x-ptguibatchlist;image/tiff;image/jpeg;image/png;image/x-exr;image/x-canon-crw;image/x-canon-cr2;image/x-canon-cr3;image/x-nikon-nef;image/x-fuji-raf;image/x-sigma-x3f;image/x-minolta-mrw;image/x-sony-srf;image/x-adobe-dng;image/x-olympus-orf;image/x-sony-arw;image/x-pentax-pef;image/x-kodak-dcr;image/x-sony-sr2;image/x-gopro-gpr;image/x-panasonic-raw
      EOF

          cat > "$out/share/applications/newhouse-ptguiviewer-${versionhash}.desktop" <<'EOF'
      [Desktop Entry]
      Name=PTGui Viewer ${version}
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
      description = "PTGui";
      longDescription = ''
        PTGui Panoramic photo stitching software
      '';
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      license = licenses.unfree;
      platforms = platforms.linux;
      mainProgram = "PTGui";
    };
  }
