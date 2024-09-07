{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "grafana.jointhefreeworld.org";
        root_url = "https://grafana.jointhefreeworld.org/";
        serve_from_sub_path = false;
      };
    };
  };
}
