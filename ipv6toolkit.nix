{ lib, stdenv, fetchurl, makeWrapper, libpcap, perl, bind }:

stdenv.mkDerivation rec {
  pname = "ipv6toolkit";
  version = "2.0";

  src = fetchurl {
    #url = "https://www.si6networks.com/tools/ipv6toolkit/ipv6toolkit-v${version}.tar.gz";
    url = "http://pages.cs.wisc.edu/~plonka/ipv6toolkit/ipv6toolkit-v${version}.tar.gz";
    sha256 = "sha256-FvE9Pn0XlA/1PwKO8AkOSqOhk6IkyXcosH6m4moZ6Yc=";
  };

  buildInputs = [
    libpcap
    perl
    bind
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  dontConfigure = true;
  makefile = "GNUmakefile";
  makeFlags = [ "DESTDIR=${placeholder "out"}" "PREFIX=/" ];
  # Noisy
  NIX_CFLAGS_COMPILE = "-Wno-address-of-packed-member -Wno-misleading-indentation";

  postPatch = ''
    substituteInPlace GNUmakefile \
      --replace 'gcc' 'cc'

    substituteInPlace GNUmakefile \
      --replace '/sbin' '/bin'

    # fix configuration file contents
    substituteInPlace GNUmakefile \
      --replace '=$(PREFIX)/share/' '=${placeholder "out"}/share/'

    # TODO: patch to read conf file path from env
    for f in $(grep -lr -F '/etc/ipv6toolkit.conf' tools/); do
      substituteInPlace $f \
        --replace '/etc/ipv6toolkit.conf' '${placeholder "out"}/etc/ipv6toolkit.conf'
    done

    patchShebangs tools/
  '';

  postFixup = ''
    for s in script6 blackhole6; do
      wrapProgram $out/bin/$s \
        --prefix PATH : ${lib.makeBinPath [ (placeholder "out") bind.host ]}
    done
  '';

  meta = with lib; {
    description = "Security assessment and troubleshooting tool for IPv6";
    homepage = "https://www.si6networks.com/research/tools/ipv6toolkit/";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
  };
}
