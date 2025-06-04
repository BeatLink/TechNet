{ lib
, perlPackages
, fetchFromGitHub
, gettext
, multimarkdown
, gtk3
, wrapGAppsHook
, gst_all_1
, glib
, gobject-introspection
}:

let
  inherit (perlPackages) makePerlPath;

  deps = with perlPackages; [
    Gtk3
    Gtk3ImageView
    Gtk3SimpleList
    Cairo
    CairoGObject
    Glib
    GlibObjectIntrospection
    NetDBus
    XMLTwig
    XMLParser
    HTMLParser
    Pango
    LocaleGettext
  ];
in

perlPackages.buildPerlPackage rec {
  pname = "gmusicbrowser";
  version = "60d4b6f";

  src = fetchFromGitHub {
    owner = "squentin";
    repo = "gmusicbrowser";
    rev = "75c410d0dd71f116082aecd3b52af725f670521a";
    sha256 = "sha256-nZ1/hRrzem5RTeXcGeogvn5PrZoz/U03ZEVPWeYn1Eo=";
  };

  dontConfigure = true;
  doCheck = false;

  makeFlags = [ "prefix=$(out)" ];

  outputs = [ "out" ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp gmusicbrowser.pl $out/bin/gmusicbrowser
    chmod +x $out/bin/gmusicbrowser
    runHook postInstall
  '';

  postInstall = ''
    find $out -type f -name "*.pod" -delete
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix PERL5LIB : "${makePerlPath deps}")
    wrapProgram $out/bin/gmusicbrowser \
      --prefix PERL5LIB : "${makePerlPath deps}"
  '';

  propagatedBuildInputs = deps;

  buildInputs = [
    gtk3
    glib
    gobject-introspection
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

  nativeBuildInputs = [
    gettext
    multimarkdown
    wrapGAppsHook
  ];

  meta = with lib; {
    homepage = "https://github.com/squentin/gmusicbrowser";
    description = "A jukebox for large collections of music, written in Perl with a GTK3 GUI";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ]; # Fill in if desired
  };
}
