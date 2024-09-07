{ pkgs, ... }: {
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
        "https://cache.iog.io"
        "https://wikimusic-api.cachix.org"
        "https://wikimusic-ssr.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "wikimusic-api.cachix.org-1:Lm/BHLGnsv75YHkDxEdv33cjwgbZfFSaXBvrX87+NI0="
        "wikimusic-ssr.cachix.org-1:T+rJqh9tVOb/1ZfMZls7jTsBueRzDK2vLcmMZDsoyEU="
      ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 20d";
    };
  };
}
