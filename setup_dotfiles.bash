#!/bin/bash -ex
if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root" 1>&2
	exit 1
fi
script_error_report() {
    local script="$1"
    local parent_lineno="$2"
    local message="$3"
    local code="${4:-1}"
    echo "Error near ${script} line ${parent_lineno}; exiting with status ${code}"
    if [[ -n "$message" ]] ; then
        echo -e "Message: ${message}"
    fi
    exit "${code}"
}
trap 'script_error_report "${BASH_SOURCE[0]}" ${LINENO}' ERR

# Setup for password-less sudo
if [ -n "$USER" -a "$USER" != "root" -a ! -f /etc/sudoers.d/50_${USER}_sh ]; then
	echo "Add NOPASSWD for user, required by functional test to replace /etc/hcfs.conf"
	sudo grep -q "^#includedir.*/etc/sudoers.d" /etc/sudoers || (echo "#includedir /etc/sudoers.d" | sudo tee -a /etc/sudoers)
	( umask 226 && echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/50_${USER}_sh )
fi

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current
source bashrc.d/get-platform

# Disable DNS resolution to speedup ssh
if [ -f /etc/ssh/sshd_config ]; then
    sudo sed -i -e "s:^#\?UseDNS yes:UseDNS no:" /etc/ssh/sshd_config
    grep "UseDNS no" /etc/ssh/sshd_config || echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config
fi

#######################
## Delete dead links
#######################

sudo find -L ~ -maxdepth 1 -type l -print -delete

#######################
## Backup dotfiles and replace with link
#######################

dotfiles_oldfolder="$HOME/.dotfiles_old_`date +%Y%m%d%H%M%S`"
[ ! -e "$dotfiles_oldfolder" ] && mkdir "$dotfiles_oldfolder"
(
    unset GREP_OPTIONS
    \ls | grep -v "~$" | while read file;
    do
        [[ "$file" =~ _dotfiles.bash ]] && continue
        target="$HOME/.$file"
        [ -e "$target" -a ! -h "$target" ] && mv -f "$target" "$dotfiles_oldfolder/"
        ln -Tfvs "$(realpath "$file" )" "$target"
    done
)

find "$dotfiles_oldfolder" -type d -empty | xargs rm -rvf

#######################
## install packages on new machine
#######################

packages="git dos2unix wget curl"

case $platform in
    'linux')
        packages="$packages exuberant-ctags"
        packages="$packages make"
        packages="$packages build-essential"
        packages="$packages libssl-dev"
        packages="$packages libbz2-dev"
        packages="$packages zlib1g-dev"
        packages="$packages libreadline-dev"
        packages="$packages libsqlite3-dev"
        packages="$packages vim"
        ;;
    'mac')
        brew help > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        packages="$packages ctags"
        packages="$packages python"
        packages="$packages coreutils"
        ;;
esac

linux_check_pkg() { dpkg -s "$1" >/dev/null 2>&1; }
linux_install_pkg() { sudo apt-get install -y $@; }
mac_check_pkg() { brew list -1 | grep -q "^${1}\$"; }
mac_install_pkg() { brew install $@; }

install_packages=""
for P in $packages; do
    if ${platform}_check_pkg $P; then
        echo "$P is installed."
    else
        echo "$P is not installed."
        install_packages="$install_packages $P"
    fi
done
[ -n "$install_packages" ] && ${platform}_install_pkg $install_packages

#######################
## install vim plugins
#######################
mkdir -p vim/bundle
pushd vim/bundle
if [ -e Vundle.vim ]; then
    cd Vundle.vim
    git pull
else
    git clone --depth 1 https://github.com/VundleVim/Vundle.vim
fi
popd

vim +BundleInstall +qa
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;

#######################
## install pyenv
#######################
#CFLAGS='-g -O2'
#curl -L https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
#export setupdotfile=yes
#set +e
#source ~/.bashrc
#set -e
#pyenv versions | grep -q 2.7.7 || pyenv install 2.7.7
#pyenv global 2.7.7

#######################
## install powerline
#######################
# Remove deprecated pyenv version powerline
rm -rf ~/.pyenv/

if hash pip 2>/dev/null; then
	sudo -H pip install -U pip
else
	# install pip
	#[[ $platform == 'mac' ]]
        if [[ $platform == 'linux' ]]; then
            curl https://bootstrap.pypa.io/get-pip.py | sudo python
            hash -r
        fi
fi

hash powerline-daemon && powerline-daemon -k || true
if (which powerline | grep /usr -q); then
	sudo -H pip install powerline-status powerline-gitstatus argparse --upgrade
else
	pip install --user powerline-status powerline-gitstatus argparse --upgrade
fi


#######################
## Local changes
#######################
# Setup self default using rebase when pull
git config branch.master.rebase true

# patch fonts for powerline
[ "$1" = "x" ] && get fontconfig && fc-cache -vf ~/.fonts

# Daily Update dotfiles repo
if ! (crontab -l | grep -q git_update_dotfiles.bash); then
	crontab -l \
		| { cat; echo "@daily $current/git_update_dotfiles.bash"; } \
		| crontab -
fi

#######################
## Local fixes
#######################
rm -rf local
[ -L ~/.local ] && rm ~/.local
if [ -n "$USER" -a "$USER" != "root" ]; then
	sudo chown -R $USER:$GROUPS $HOME
fi

