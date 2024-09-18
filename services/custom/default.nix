{ pkgs, ... }:
let
  wikimusicSqsQueue =
    "https://sqs.eu-west-3.amazonaws.com/831168501272/wikimusic-version-release.fifo";
  wikimusicSSRSqsQueue =
    "https://sqs.eu-west-3.amazonaws.com/831168501272/wikimusic-ssr-version-release.fifo";
  dotfilesSqsQueue =
    "https://sqs.eu-west-3.amazonaws.com/831168501272/dotfiles-ec2-version-release.fifo";
in {

  systemd.services = {
    wikimusic-api = {
      enable = true;
      description = "WikiMusic API";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ nix git gnumake stack gnutar ];
      script = ''
        stack run -- "/root/Ontwikkeling/wikimusic-api/resources/config/run-production.toml"
      '';
      serviceConfig = {
        User = "joe";
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
      after = [ "network-online.target" ];
      path = with pkgs; [ nix git gnumake stack gnutar ];
      script = ''
        stack run -- "/root/Ontwikkeling/wikimusic-ssr/resources/config/run-production.toml"
      '';
      serviceConfig = {
        User = "joe";
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
      path = with pkgs; [ awscli2 zip ];
      script = ''
        export BACKUP_ZIP_NAME="archive-$(date +"%Y-%m-%d")-wikimusic-sqlite.zip"
        zip -r $BACKUP_ZIP_NAME wikimusic.sqlite
        aws s3 cp $BACKUP_ZIP_NAME s3://cloud-infra-state-jjba/wikimusic/backups/sqlite/$BACKUP_ZIP_NAME
      '';
    };
  };
}

