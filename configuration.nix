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
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
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
    sqlite
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

  services = { openssh.enable = true; };

  systemd.services = {
    wikimusic-api = {
      enable = true;
      description = "WikiMusic API";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
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

    wikimusic-database-backup = {
      enable = true;
      description = "WikiMusic Database Backup";
      startAt = "*-*-* 03:15:00"; # run at 03:15 (at night) every day.
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      serviceConfig = {
        WorkingDirectory = "/root";
        RemainAfterExit = "no";
      };
      path = with pkgs; [ awscli2 ];
      script = ''
        export BACKUP_ZIP_NAME="archive-$(date +"%Y-%m-%d")-wikimusic-sqlite.zip"
        zip -r $BACKUP_ZIP_NAME wikimusic.sqlite
        aws s3 cp $BACKUP_ZIP_NAME s3://cloud-infra-state-jjba/wikimusic/backups/sqlite/$BACKUP_ZIP_NAME
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
      amazon_ses_user = { };
      amazon_ses_password = { };
    };
  };
}
