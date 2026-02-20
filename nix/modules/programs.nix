{ ... }:

{
  environment.etc."gitconfig".text = ''
    [user]
    	name = Yvan
    	email = yvanstemmerik@gmail.com
    [core]
    	excludesfile = ~/.gitignore_global
    [init]
    	defaultBranch = main
    [pull]
    	rebase = true
    [push]
    	autoSetupRemote = true
    [merge]
    	conflictstyle = diff3
    [diff]
    	algorithm = histogram
    [rerere]
    	enabled = true
  '';
}
