{ ... }:

{
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Kubectl aliases (declarative, replaces shell/.zprofile aliases)
  environment.shellAliases = {
    k   = "kubectl";
    kg  = "kubectl get";
    kgp = "kubectl get pods";
    kgd = "kubectl get deployments";
    kgs = "kubectl get services";
    kga = "kubectl get all";
    kd  = "kubectl describe";
    kaf = "kubectl apply -f";
    kdf = "kubectl delete -f";
  };
}
