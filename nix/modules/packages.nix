{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    # Nixvim configuration
    inputs.nixvim.packages.aarch64-darwin.default
    
    # Development tools
    pkgs.git
    pkgs.maven
    pkgs.rustc
    
    # Containerization
    pkgs.docker
    pkgs.docker-compose
    pkgs.minikube
    
    # Java ecosystem
    pkgs.zulu23
    
    # System utilities
    pkgs.mkalias
  ];
}