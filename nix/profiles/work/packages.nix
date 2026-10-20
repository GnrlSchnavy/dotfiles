# Azure tooling for the Tech NL KaaS (AKS) clusters: az for login and
# credentials, kubelogin for the Azure AD token kubectl uses.
{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.azure-cli
    pkgs.kubelogin
  ];
}
