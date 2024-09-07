{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."grafana.jointhefreeworld.org" = {
      listen = [{
        addr = "0.0.0.0";
        port = 7979;
      }];
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        extraConfig = ''
          proxy_ssl_server_name on;
          proxy_pass_header Authorization;
          auth_basic "admin area";
          auth_basic_user_file /run/secrets/grafana_nginx_auth;
          sendfile off;
        '';
      };
    };
  };
}
