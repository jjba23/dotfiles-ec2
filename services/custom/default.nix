{ pkgs, ... }:

{

  systemd.services = {
    wikimusic-api = {
      enable = true;
      description = "WikiMusic API";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ nix git gnumake stack gnutar ];
      script = ''
        stack run -- "/home/joe/Ontwikkeling/wikimusic-api/resources/config/run-production.toml"
      '';
      serviceConfig = {
        User = "joe";
        WorkingDirectory = "/home/joe/Ontwikkeling/wikimusic-api";
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
        stack run -- "/home/joe/Ontwikkeling/wikimusic-ssr/resources/config/run-production.toml"
      '';
      serviceConfig = {
        User = "joe";
        WorkingDirectory = "/home/joe/Ontwikkeling/wikimusic-ssr";
        Restart = "always";
        RemainAfterExit = "no";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    byggsteg = {
      enable = true;
      description = "Byggsteg";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ nix git gnumake gnutar zip unzip guile ];
      script = ''
        GUILE_AUTO_COMPILE=0 guile run-server.scm
      '';
      serviceConfig = {
        User = "joe";
        WorkingDirectory = "/home/joe/Ontwikkeling/byggsteg";
        Restart = "always";
        RemainAfterExit = "no";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    wikimusic-database-backup = {
      enable = true;
      description = "WikiMusic Database Backup";
      startAt = "*-*-* 03:15:00"; # run at 03:15 (at night) every day.
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      serviceConfig = {
        WorkingDirectory = "/home/joe";
        RemainAfterExit = "no";
      };
      path = with pkgs; [ awscli2 zip gnutar ];
      script = ''
        export BACKUP_ZIP_NAME="archive-$(date +"%Y-%m-%d")-wikimusic-sqlite.zip"
        zip -r $BACKUP_ZIP_NAME wikimusic.sqlite
        aws s3 cp $BACKUP_ZIP_NAME s3://cloud-infra-state-jjba/wikimusic/backups/sqlite/$BACKUP_ZIP_NAME
      '';
    };
  };
}

