# Docker engine: a Colima VM (default profile), started at login by a
# launchd agent. It replaces Docker Desktop: the shell, IntelliJ,
# Testcontainers and Claude Code all use it.
#
# Colima makes itself the active docker context at start (`colima`, written
# to ~/.docker/config.json — an app-owned file, never symlinked) and the shell
# gets DOCKER_HOST. colima.yaml is a store symlink, which is fine: the agent
# starts with --save-config=false, so Colima never rewrites it.
{ config, ... }:

let
  home = config.home.homeDirectory;
  socket = "${home}/${config.services.colima.colimaHomeDir}/default/docker.sock";

  dockerEnv = {
    DOCKER_HOST = "unix://${socket}";
    # Testcontainers' Ryuk mounts the socket path inside the VM.
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
  };
in
{
  # The docker CLI, with the compose and buildx plugins.
  home.packages = [ config.services.colima.dockerPackage ];

  home.sessionVariables = dockerEnv;
  # Claude Code sessions started from the desktop app don't inherit the shell.
  dotfiles.claude.settings.env = dockerEnv;

  services.colima = {
    enable = true;
    profiles.default = {
      isService = true;
      isActive = true;
      # Spelled out in full (Colima 0.10's `colima template` defaults) rather
      # than relying on how Colima fills in keys a colima.yaml leaves out.
      settings = {
        cpu = 4;
        # The Linux page cache makes the VM look full; 3 GB is plenty.
        memory = 3;
        disk = 60;
        rootDisk = 20;
        arch = "host";
        cpuType = "host";
        runtime = "docker";
        hostname = null;
        kubernetes.enabled = false;
        network = {
          address = false;
          mode = "shared";
          interface = "en0";
          preferredRoute = false;
          dns = [ ];
          dnsHosts."host.docker.internal" = "host.lima.internal";
          hostAddresses = false;
        };
        forwardAgent = false;
        docker = { };
        vmType = "vz";
        portForwarder = "ssh";
        rosetta = false;
        binfmt = true;
        nestedVirtualization = false;
        mountType = "virtiofs";
        mountInotify = false;
        provision = [ ];
        sshPort = 0;
        diskImage = "";
        env = { };
        autoActivate = true;
        # Leave ~/.ssh/config untouched.
        sshConfig = false;
        # Replaces Colima's default mount of all of $HOME: containers (and so
        # a sandboxed Claude session with the socket) see ~/projects only.
        mounts = [
          {
            location = "${home}/projects";
            writable = true;
          }
        ];
      };
    };
  };
}
