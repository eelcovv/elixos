{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./docker.nix
    ./direnv.nix
    ./git-default.nix
    ./pycharm.nix
    ./pypi.nix
    ./python.nix
    ./python-devtools.nix
    ./python-rt-libs.nix
    ./uv.nix
    ./vscode.nix
    ./rootless-podman-storage.nix
  ];

  # enable PyPI integration (writes ~/.pypirc from /run/secrets/*)
  pypi = {
    enable = true;
    davelab = {
      enable = true;
      repository = "https://pypi.davelab.eu";
      auth.mode = "basic";
    };
  };

  # Alleen tools, geen compilers (gcc/gfortran horen in de devShell)
  home.packages = with pkgs; [
    alejandra
    direnv
    nodejs
    gnumake
    htop
    tree
    wget
  ];

  # Python runtime libs: alleen runtimes, geen compilers
  pythonRtLibs = {
    enable = true;
    withQtDev = false; # PySide6 via uv
    withWayland = true;
    withX11 = true;
    withBLAS = true; # OpenBLAS runtime voor NumPy/SciPy
    withFortranRuntime = false; # Fortran-runtime komt via nix-ld op systeemniveau
    useLdLibraryPath = false; # nix-ld zorgt voor linker paths
  };
}
