{ pkgs }:

pkgs.buildGoModule rec {
  pname = "dnsproxy";
  version = "0.71.2";
  src = pkgs.fetchFromGitHub {
    owner = "AdguardTeam";
    repo = "dnsproxy";
    rev = "v${version}";
    sha256 = "sha256-fsJWyb3YFmTeLf1qbO42RTldiEv3MeXyrySywGmIg5A=";
  };
  vendorHash = "sha256-oINdRXLtfoCOpZ+n4HAkPtXyKen4m9VaDz1ggiEzehc=";
  subPackages = [ "." ]; # Build only the main package
  # Inject version into main.versionString
  ldflags = [
    "-s" "-w" # Strip debug info for smaller binary
    "-X main.versionString=${version}"
  ];
  # Ensure build flags are passed correctly, with lib in scope
  preBuild = ''
    echo "Building with ldflags: ${pkgs.lib.concatStringsSep " " ldflags}"
  '';
  meta = with pkgs.lib; {
    description = "Simple DNS proxy with DoH, DoT, DoQ, and DNSCrypt support";
    homepage = "https://github.com/AdguardTeam/dnsproxy";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
} 