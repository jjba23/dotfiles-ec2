{
  services.caddy = {
    enable = true;
    virtualHosts."grafana.jointhefreeworld.org".extraConfig = ''
      basic_auth {
        root $2a$14$zYpcVd.oPgzVFU5Rr3Rz8OA7113VfnzRttWhnmihN.akMZ54de64m
      }
      reverse_proxy http://127.0.0.1:3000
    '';
  };
}
