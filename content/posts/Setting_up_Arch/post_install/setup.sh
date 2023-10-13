#!/bin/sh
echo "################################################################"
echo "Cloning Personal Setup repo"
git clone https://github.com/n0k0m3/Personal-Setup --depth=1
cd Personal-Setup/Setting_up_Arch


# Install ZSH
get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist"
}

lsb_dist=$( get_distribution )
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

case "$lsb_dist" in

    ubuntu|debian|raspbian)
        sudo apt-get update && sudo apt-get install zsh curl -y
    ;;

    endeavouros|arch)
        sudo pacman -S zsh curl
    ;;

	centos|fedora|rhel)
		sudo yum install -y -q zsh
	;;

esac

# Automatic copy config
echo "################################################################"
echo "Copy .dotfiles configs"
cp -r -a .dotfiles/. ~

# Initiate ZSH
zsh
