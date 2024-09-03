# Joe's dotfiles
# Copyright (C) 2023  Josep Jesus Bigorra Algaba (jjbigorra@gmail.com)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

{ config, pkgs, lib, modulesPath, ... }:

let
  wikimusicSqsQueue =
    "https://sqs.eu-west-3.amazonaws.com/831168501272/wikimusic-version-release.fifo";
  wikimusicSSRSqsQueue =
    "https://sqs.eu-west-3.amazonaws.com/831168501272/wikimusic-ssr-version-release.fifo";
  dotfilesSqsQueue =
    "https://sqs.eu-west-3.amazonaws.com/831168501272/dotfiles-ec2-version-release.fifo";
in {
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
        "https://cache.iog.io"
        "https://wikimusic-api.cachix.org"
        "https://wikimusic-ssr.cachix.org"
        # "https://jdb-api.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        # "jdb-api.cachix.org-1:foTSPfkghcj12xPzzydSaSfaBhmSNcaugcztEB8Je5Q="
        "wikimusic-api.cachix.org-1:Lm/BHLGnsv75YHkDxEdv33cjwgbZfFSaXBvrX87+NI0="
        "wikimusic-ssr.cachix.org-1:T+rJqh9tVOb/1ZfMZls7jTsBueRzDK2vLcmMZDsoyEU="
      ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 20d";
    };
  };

  system.stateVersion = "24.05";
  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    channel = "https://nixos.org/channels/nixos-unstable";
  };

  environment.systemPackages = with pkgs; [
    git
    gnumake
    autoconf
    vim
    neovim
    emacs
    zip
    unzip
    xz
    home-manager
    fish
    curl
    wget
    docker-compose
    htop
    screen
    ripgrep
    jq
    yq
    awscli2
    gawk
    age
    sops
    openssl
    neofetch
    mailutils
    direnv
    postgresql
    cachix
  ];

  users.users.joe = {
    isNormalUser = true;
    description = "Joe";
    extraGroups = [ "networkmanager" "network" "wheel" "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJDyoK3CG6oBA+YsYwJTv7Ue+438rQ3xaxwwUIbAfUU"
    ];
  };

  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [ 80 443 50050 22 55432 63379 ];
    allowedTCPPorts = [ 80 443 50050 50051 22 6923 ];
  };

  security.sudo.wheelNeedsPassword = false;
  programs.fish.enable = true;
  virtualisation.docker.enable = true;
  nixpkgs.config.allowUnfree = true;

  services = {
    openssh.enable = true;

    postgresql = {
      enable = true;
      checkConfig = true;
      package = pkgs.postgresql_15;
      settings = { port = 55432; };
      enableTCPIP = true;
      authentication = lib.mkForce ''
        local all all trust
        host all all 0.0.0.0/0 md5
        host all all ::1/128 md5
      '';
      initialScript = pkgs.writeText "init-sql-script" "\n";
    };

    postgresqlBackup = {
      enable = true;
      startAt = "*-*-* 01:15:00"; # 01:15 (at night) every day.
      databases = [ "wikimusic_database" ];
      location = "/var/backup/postgresql";
      pgdumpOptions = lib.strings.concatMapStrings (x: " " + x) [
        "-C"
        "--port=55432"
        ''
          --file=/var/backup/postgresql/wikimusic_database_$(date "+%Y-%m-%d-%T").sql''
      ];
    };

    redis.servers.wikimusic = {
      enable = true;
      port = 63379;
      requirePassFile = config.sops.secrets.wikimusic_redis_key.path;
    };
  };

  systemd.services = {
    wikimusic-api = {
      enable = true;
      description = "WikiMusic API";
      requires = [ "network-online.target" ];
      after = [
        "network-online.target"
        "postgresql.service"
        "redis-wikimusic.service"
      ];
      path = with pkgs; [ nix git gnumake ];
      script = ''
        nix run -L . -- "/root/Ontwikkeling/wikimusic-api/resources/config/run-production.toml"
      '';
      serviceConfig = {
        User = "root";
        WorkingDirectory = "/root/Ontwikkeling/wikimusic-api";
        Restart = "always";
        RemainAfterExit = "no";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    wikimusic-ssr = {
      enable = true;
      description = "WikiMusic SSR";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" "wikimusic-api.service" ];
      path = with pkgs; [ nix git gnumake ];
      script = ''
        nix run -L . -- "/root/Ontwikkeling/wikimusic-ssr/resources/config/run-production.toml"
      '';
      serviceConfig = {
        User = "root";
        WorkingDirectory = "/root/Ontwikkeling/wikimusic-ssr";
        Restart = "always";
        RemainAfterExit = "no";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # jdb-api = {
    #   enable = true;
    #   description = "JDB API";
    #   requires = [ "network-online.target" ];
    #   after = [
    #     "network-online.target"
    #     "postgresql.service"
    #     "redis-wikimusic.service"
    #   ];
    #   path = with pkgs; [ nix git gnumake ];
    #   script = ''
    #     nix run --accept-flake-config . -- "/root/Ontwikkeling/jdb-api/resources/config/run-production.toml"
    #   '';
    #   serviceConfig = {
    #     User = "root";
    #     WorkingDirectory = "/root/Ontwikkeling/jdb-api";
    #     Restart = "always";
    #     RemainAfterExit = "no";
    #     StandardOutput = "journal";
    #     StandardError = "journal";
    #   };
    # };

    dotfiles-updater = {
      enable = true;
      description = "Dotfiles EC2 Updater";
      startAt = "*-*-* *:*/5:00";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ nix git gawk gnumake awscli2 bash nixos-rebuild ];
      script = ''
        cmd=$(aws sqs receive-message --queue-url ${dotfilesSqsQueue} --max-number-of-messages 1)
        if [[ -n $cmd  ]]; then
           git pull origin master || true
           make nr || true
        fi
      '';

      serviceConfig = {
        User = "root";
        WorkingDirectory = "/root/Ontwikkeling/dotfiles-ec2";
        RemainAfterExit = "no";
      };
    };

    wikimusic-api-updater = {
      enable = true;
      description = "WikiMusic API Updater";
      startAt = "*-*-* *:*/10:00"; # run every 10 minutes
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ nix git gawk gnumake awscli2 bash ];
      script = ''
        cmd=$(aws sqs receive-message --queue-url ${wikimusicSqsQueue} --max-number-of-messages 1)
        if [[ -n $cmd ]]; then
          git pull origin master || true
          systemctl restart wikimusic-api.service || true
        fi
      '';
      serviceConfig = {
        User = "root";
        WorkingDirectory = "/root/Ontwikkeling/wikimusic-api";
        RemainAfterExit = "no";
      };
    };

    wikimusic-ssr-updater = {
      enable = true;
      description = "WikiMusic SSR Updater";
      startAt = "*-*-* *:*/10:00"; # run every 10 minutes
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ nix git gawk gnumake awscli2 bash ];
      script = ''
        cmd=$(aws sqs receive-message --queue-url ${wikimusicSSRSqsQueue} --max-number-of-messages 1)
        if [[ -n $cmd ]]; then
          git pull origin master || true
          systemctl restart wikimusic-ssr.service || true
        fi
      '';
      serviceConfig = {
        User = "root";
        WorkingDirectory = "/root/Ontwikkeling/wikimusic-ssr";
        RemainAfterExit = "no";
      };
    };

    # jdb-api-updater = {
    #   enable = true;
    #   description = "JDB API Updater";
    #   startAt = "*-*-* *:*/10:00"; # run every 10 minutes
    #   requires = [ "network-online.target" ];
    #   after = [ "network-online.target" ];
    #   path = with pkgs; [ nix git gawk gnumake awscli2 bash ];
    #   script = ''
    #     cmd=$(aws sqs receive-message --queue-url ${wikimusicSqsQueue} --max-number-of-messages 1)
    #     if [[ -n $cmd ]]; then
    #       git pull origin master || true
    #       systemctl restart jdb-api.service || true
    #     fi
    #   '';
    #   serviceConfig = {
    #     User = "root";
    #     WorkingDirectory = "/root/Ontwikkeling/jdb-api";
    #     RemainAfterExit = "no";
    #   };
    # };

    wikimusic-database-backup = {
      enable = true;
      description = "WikiMusic Database Backup";
      startAt = "*-*-* 03:15:00"; # run at 03:15 (at night) every day.
      after = [ "postgresql.service" "network-online.target" ];
      requires = [ "postgresql.service" "network-online.target" ];
      serviceConfig = {
        WorkingDirectory = "/var/backup/postgresql";
        RemainAfterExit = "no";
      };
      path = with pkgs; [ awscli2 ];
      script = ''
        aws s3 sync . s3://cloud-infra-state-jjba/wikimusic/backups/postgresql/
      '';
    };
    wikimusic-database-cleanup-backup = {
      enable = true;
      description = "WikiMusic Database Cleanup Backup";
      startAt =
        "Sat *-*-1..7 18:00:00"; # run the first saturday of every month at 18h
      serviceConfig = {
        WorkingDirectory = "/var/backup/postgresql";
        RemainAfterExit = "no";
      };
      path = with pkgs; [ awscli2 ];
      script = ''
        echo "TODO, implement me"
      '';
    };
  };

  sops = {
    defaultSopsFile = /root/secrets/example.yaml;
    age = {
      keyFile = "/root/.config/sops/age/keys.txt";
      generateKey = false;
    };
    secrets = {
      wikimusic_postgres_key = { };
      wikimusic_redis_key = { };
      amazon_ses_user = { };
      amazon_ses_password = { };
    };
  };
}
