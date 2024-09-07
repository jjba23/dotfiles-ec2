{
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
