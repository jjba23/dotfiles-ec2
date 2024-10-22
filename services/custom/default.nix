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
        stack run -- "/var/log/byggsteg/job-clone/wikimusic-api/trunk/resources/config/run-production.toml"
      '';
      serviceConfig = {
        User = "root";
        WorkingDirectory = "/var/log/byggsteg/job-clone/wikimusic-api/trunk";
        Restart = "always";
        RemainAfterExit = "yes";
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
        stack run -- "/var/log/byggsteg/job-clone/wikimusic-ssr/trunk/resources/config/run-production.toml"
      '';
      serviceConfig = {
        User = "root";
        WorkingDirectory = "/var/log/byggsteg/job-clone/wikimusic-ssr/trunk";
        Restart = "always";
        RemainAfterExit = "yes";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    byggsteg = {
      enable = true;
      description = "Byggsteg";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [
        nix
        git
        gnumake
        gnutar
        stack
        zip
        unzip
        python3
        guile
        unixtools.xxd
        sbt
        scala_2_13
      ];
      script = ''
        GUILE_AUTO_COMPILE=0 guile run-server.scm
      '';
      serviceConfig = {
        User = "root";
        WorkingDirectory = "/var/log/byggsteg/job-clone/byggsteg/trunk";
        Restart = "always";
        RemainAfterExit = "yes";
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

