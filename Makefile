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

include .make/log.mk

nixos-dotfiles-install:
	@make -s log-info MSG="installing dotfiles"
	cp -f *.nix /etc/nixos/
	cp -f README.org /etc/nixos/
	rm -rf /etc/nixos/services
	cp -rf services /etc/nixos/services
	rm -rf /etc/nixos/config
	cp -rf config /etc/nixos/config
	rm -rf /home/joe/secrets/example.yaml
	mkdir -p /home/joe/secrets && cp -f sops.yaml /home/joe/secrets/example.yaml

nr: nixos-dotfiles-install
	@make -s log-info MSG="rebuilding NixOS system flake"
	nix-shell -p mount --run "sudo mount -o remount,size=30G tmpfs"
	nixos-rebuild switch --verbose --impure --flake '/etc/nixos#nixos'
	cp -f flake.lock /etc/nixos/flake.lock

fmt:
	-find . -name '*.nix' -exec nixfmt {} \;
