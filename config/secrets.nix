{
  sops = {
    defaultSopsFile = /home/joe/secrets/example.yaml;
    age = {
      keyFile = "/home/joe/.config/sops/age/keys.txt";
      generateKey = false;
    };
    secrets = {
      amazon_ses_user = { };
      amazon_ses_password = { };
    };
  };
}
