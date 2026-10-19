# Profile: dev — the development setup every machine gets, personal or
# work: editors, terminals, browsers, Kubernetes and JVM tooling, CLI basics,
# a Docker engine (Colima), and Alfred on Cmd-Space.
{
  systemModules = [
    ./homebrew.nix
    ./packages.nix
  ];
  homeModules = [
    ./docker.nix
    ./alfred.nix
  ];
}
