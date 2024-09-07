# Joe's dotfiles
# Copyright (C) 2023  Josep Jesus Bigorra Algaba (jjbigorra@gmail.com)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    "./services"
    "./config"
  ];

  system.stateVersion = "24.05";
  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    channel = "https://nixos.org/channels/nixos-unstable";
  };

  users.users.joe = {
    isNormalUser = true;
    description = "Joe";
    extraGroups = [ "networkmanager" "network" "wheel" "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJDyoK3CG6oBA+YsYwJTv7Ue+438rQ3xaxwwUIbAfUU"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  programs.fish.enable = true;
  virtualisation.docker.enable = true;
  nixpkgs.config.allowUnfree = true;

  services = { openssh.enable = true; };

}
