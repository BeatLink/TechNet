# https://gist.github.com/guillermofbriceno/abef9f1357329778897ea8dbac17b9db

{ lib
, perlPackages
, fetchFromGitHub
, gettext
, multimarkdown
, wrapGAppsHook
, gst_all_1
}:

let
  inherit (perlPackages) makePerlPath;
  deps = with perlPackages; [
    Gtk3 # fix: Can't locate Gtk3.pm in @INC
    Gtk3ImageView
    Gtk3SimpleList
    Cairo # fix: Can't locate Cairo.pm in @INC
    CairoGObject # fix: Can't locate Cairo/GObject.pm in @INC
    Glib # fix: Can't locate Glib.pm in @INC
    GlibObjectIntrospection # fix: 't locate Glib/Object/Introspection.pm in @INC
    NetDBus
    XMLTwig
    XMLParser
    HTMLParser
    Pango
    LocaleGettext
  ];
in

perlPackages.buildPerlPackage  {
  pname = "gmusicbrowser";
  version = "60d4b6f";
  src = fetchFromGitHub {
    owner = "squentin";
    repo = "gmusicbrowser";
    rev = "75c410d0dd71f116082aecd3b52af725f670521a";
    sha256 = "sha256-nZ1/hRrzem5RTeXcGeogvn5PrZoz/U03ZEVPWeYn1Eo=";
  };

  postInstall = ''
      find $out -type f -name "*.pod" -delete
  '';
  dontConfigure = true; # fix: Can't open perl script "Makefile.PL": No such file or directory
  doCheck = false; # fix: make: *** No rule to make target 'test'.  Stop.
  makeFlags = [
    "prefix=$(out)" # fix: mkdir: cannot create directory '/usr': Permission denied
  ];
  outputs = [ "out" ]; # fix: error: builder failed to produce output path for output 'devdoc'
  # fix: Can't locate Gtk3.pm in @INC
  preFixup = ''
    gappsWrapperArgs+=(--prefix PERL5LIB : "${makePerlPath deps}")
  '';
  buildInputs = [ 
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    deps
  ];

  nativeBuildInputs = [
    gettext # fix: msgmerge: command not found
    multimarkdown # fix: markdown: command not found
    wrapGAppsHook # fix? Typelib file for namespace 'Gtk', version '3.0' not found
  ];

  meta = with lib; {
    homepage = "https://github.com/squentin/gmusicbrowser";
    description = "jukebox for large collections of music";
    #maintainers = teams.gnome.members;
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}