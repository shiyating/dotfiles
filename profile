# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    export BPATH="$PATH"
	. "$HOME/.bashrc"
    fi
fi

export LANG="zh_TW.utf8"
export LANGUAGE="zh_TW:en"
export mydroid=/mydroid/

#-------------------------------------------------------------
# Greeting, motd etc...
#-------------------------------------------------------------

if [ -x /usr/games/fortune ]; then
    /usr/games/fortune -s     # Makes our day a bit more fun.... :-)
fi
