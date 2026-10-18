# Profile: dev — the development setup every machine gets, personal or
# work: editors, terminals, browsers, Kubernetes and JVM tooling, CLI basics,
# and a Docker engine (Colima).
{
  systemModules = [
    ./homebrew.nix
    ./packages.nix
  ];
  homeModules = [ ./docker.nix ];
}
