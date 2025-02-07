{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  pkg-config,
  ninja,
  glib,
  gtk3,
  nemo,
}:

stdenv.mkDerivation rec {
  pname = "nemo-preview";
  version = "6.4.0";

  src = fetchFromGitHub {
    owner = "linuxmint";
    repo = "nemo-extensions";
    rev = version;
    hash = "sha256-39hWA4SNuEeaPA6D5mWMHjJDs4hYK7/ZdPkTyskvm5Y=";
  };

  sourceRoot = "${src.name}/nemo-preview";

  nativeBuildInputs = [
    meson
    pkg-config
    ninja
  ];

  buildInputs = [
    glib
    gtk3
    nemo
  ];

  PKG_CONFIG_LIBNEMO_EXTENSION_EXTENSIONDIR = "${placeholder "out"}/${nemo.extensiondir}";

  meta = with lib; {
    homepage = "https://github.com/linuxmint/nemo-extensions/tree/master/nemo-preview";
    description = "A quick previewer for Nemo, the Cinnamon desktop file manager.";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = teams.cinnamon.members;
  };
}