{ config, ... }: {
  sops = {
    defaultSopsFile = /home/joe/secrets/example.yaml;
    age = {
      keyFile = "/home/joe/.config/sops/age/keys.txt";
      generateKey = false;
    };
    secrets = {
      amazon_ses_user = { owner = config.users.users.joe.name; };
      amazon_ses_password = { owner = config.users.users.joe.name; };
    };
  };
}
