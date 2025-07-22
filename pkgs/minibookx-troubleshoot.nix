{
  stdenv,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "minibookx-troubleshoot";
  version = "1.0";
  src = ./minibookx-troubleshoot.sh;
  dontUnpack = true;
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    install -Dm755 $src $out/bin/minibookx-troubleshoot
  '';
}
