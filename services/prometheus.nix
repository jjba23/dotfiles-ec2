{ config, ... }: {
  services.prometheus = {
    enable = true;
    exporters = {
      node = {
        enable = true;
        port = 9100;
        enabledCollectors = [ "logind" "systemd" ];
        disabledCollectors = [ "textfile" ];
        openFirewall = true;
        firewallFilter = "-i br0 -p tcp -m tcp --dport 9100";
      };
    };

    globalConfig = { scrape_interval = "10s"; };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [
            "127.0.0.1:${
              toString config.services.prometheus.exporters.node.port
            }"
          ];
        }];
        honor_labels = true;
        honor_timestamps = true;
      }
      {
        job_name = "wikimusic-ssr";
        static_configs = [{
          targets = [ "127.0.0.1:6923" ];
          labels = { job = "wikimusic-ssr"; };

        }];
        honor_labels = true;
        honor_timestamps = true;
      }
      {
        job_name = "wikimusic-api";
        static_configs = [{
          targets = [ "127.0.0.1:50050" ];
          labels = { job = "wikimusic-api"; };

        }];
        honor_labels = true;
        honor_timestamps = true;
      }
    ];
  };

}
