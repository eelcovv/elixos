# pkgs/capytaine/default.nix
{
  lib,
  buildPythonPackage,
  fetchPypi,
  # Build-time dependencies
  meson-python,
  oldest-supported-numpy,
  charset-normalizer,
  gfortran,
  # Runtime dependencies
  numpy,
  scipy,
  pandas,
  xarray,
  matplotlib,
  meshio,
}:
buildPythonPackage rec {
  pname = "capytaine";
  version = "2.3.1";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-N17CmS2Cs32zP23iCfs7uRkEvMTArzRkKMiqK1x5aKA=";
  };

  postPatch = ''
    substituteInPlace meson.build \
      --replace "run_command('src/capytaine/__about__.py', check: true).stdout().strip()" "'${version}'"
  '';

  nativeBuildInputs = [
    meson-python
    oldest-supported-numpy
    charset-normalizer
    gfortran
  ];

  propagatedBuildInputs = [
    numpy
    scipy
    pandas
    xarray
    matplotlib
    meshio
  ];

  meta = with lib; {
    description = "A Python-based hydrodynamics code for floating bodies";
    homepage = "https://github.com/capytaine/capytaine";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [
      eelcovv
    ];
    platforms = platforms.unix;
  };
}
