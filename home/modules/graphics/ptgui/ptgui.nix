#####################################
# To install PTGui in NixOS:
#
# Download PTGui from www.ptgui.com. This gives a file named (for example) PTGui_Pro_12.27.tar.gz
# Place this in a persistent directory of your choice, for example /var/lib/ptgui/PTGui_Pro_12.27.tar.gz
#
# You could also place it under /etc/nixos/, but please note that redistributing the PTGui 
# application is not allowed. So don't do this if you keep your nixos profile in a public repository.
#
# Copy the current file (ptgui.nix) to /etc/nixos/ptgui.nix
#
# In your /etc/nixos/configuration.nix, add PTGui to the systemPackages:
#
#   environment.systemPackages = with pkgs; [
#     ...
#     (callPackage ./ptgui.nix {src = /var/lib/ptgui/PTGui_Pro_12.27.tar.gz; version = "Pro 12.27"; })
#   ];
#
# Multiple versions of PTGui can be installed by adding multiple lines to environment.systemPackages.
#####################################
{ pkgs, src, version, ... }:
with pkgs;
let
  versionhash = (builtins.hashString "sha1" version);
  isv12 = ((builtins.match ".*12\\..*" version) != null); # match the string "12." anywhere in the version string
  gdkbackendprefix = if isv12 then "env GDK_BACKEND=x11" else "";
in
stdenvNoCC.mkDerivation {
  inherit version;
  inherit src;
  inherit gdkbackendprefix;
  pname = "ptgui";

  nativeBuildInputs = [ autoPatchelfHook ];

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
    tar --strip-components=1 -xzf $src
  '';

  installPhase = ''
    set +x
    runHook preInstall

    mkdir -p $out/opt/ptgui $out/bin $out/share/applications $out/share/mime/packages
    cp -r * $out/opt/ptgui
    ln -s $out/opt/ptgui/PTGui $out/bin/PTGui
    ln -s $out/opt/ptgui/PTGuiViewer $out/bin/PTGuiViewer

    cat <<EOF > "$out/share/applications/newhouse-ptgui-${versionhash}.desktop"
    [Desktop Entry]
    Name=PTGui ${version}
    Comment=PTGui Stitching Software
    Keywords=panorama;stitching;stich;stitcher;panoramas;
    Exec=${gdkbackendprefix} "$out/bin/PTGui" %F
    Icon=$out/opt/ptgui/ptgui_icon.png
    Terminal=false
    Type=Application
    Categories=Graphics
    MimeType=application/x-ptguiproject;application/x-ptguibatchlist;image/tiff;image/jpeg;image/png;image/x-exr;image/x-canon-crw;image/x-canon-cr2;image/x-canon-cr3;image/x-nikon-nef;image/x-fuji-raf;image/x-sigma-x3f;image/x-minolta-mrw;image/x-sony-srf;image/x-adobe-dng;image/x-olympus-orf;image/x-sony-arw;image/x-pentax-pef;image/x-kodak-dcr;image/x-sony-sr2;image/x-gopro-gpr;image/x-panasonic-raw
    EOF

    cat << EOF > "$out/share/applications/newhouse-ptguiviewer-${versionhash}.desktop"
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

    cat << EOF > "$out/share/mime/packages/newhouse-ptguimimetypes.xml"
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
    homepage = "https://ptgui.com/";
    description = "PTGui";
    longDescription = ''
      PTGui Panoramic photo stitching software
    '';
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = platforms.linux;
    mainProgram = "PTGui";
  };
}
