{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 50050 50051 22 6923 7979 7980 ];
  };
}
