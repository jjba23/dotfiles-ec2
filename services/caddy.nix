{
  services.caddy = {
    enable = true;
    virtualHosts."grafana.jointhefreeworld.org".extraConfig = ''
      basic_auth {
        root 
      }
      reverse_proxy http://127.0.0.1:3000
    '';
  };
}
