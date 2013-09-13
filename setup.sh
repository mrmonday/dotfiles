#!/bin/bash
###
# Copy over config files
#
# Authors:
#   Robert Clipsham <robert@octarineparrot.com>
###

# AA of config files
# Example:
#    config_files[foobar]="cf1 cf2"
# Result:
#    ln -s foobar/cf1 ~/.cf1
#    ln -s foobar/cf2 ~/.cf2
declare -A config_files

config_files[X11]="Xresources"
config_files[git]="gitconfig"
config_files[vim]="vimrc"

cd $(dirname $0)

##
# Should config files for $1 be installed?
#
# Params:
#    $1 = Directory name/application name to prompt the user for
# Returns:
#    1 if config files should be copied, 0 otherwise
##
should_install() {
    echo -n "Install config files for $1? [Y/n]: "
    read yn
    case $yn in
        [Nn]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

##
# Install configuration files for $1
#
# Params:
#    $1 = Directory/application name to install config files for
##
install_config() {
    for file in ${config_files[$1]}; do
        ln -s `pwd`/$1/$file ~/.$file
    done
}

##
# Install vim plugins
##
install_vim_plugins() {
    mkdir -p ~/.vim/dfplugins/
    for dir in $(ls vim/plugins); do
        target=$(pwd)/vim/plugins/$dir
        link_name=~/.vim/dfplugins/$dir

        # Delete the symlink if it already exists
        if [[ -h $link_name ]]; then
            rm $link_name
        fi
        ln -s $target $link_name
    done
}

##
# Prompt the user to install each config file
##
for app in "${!config_files[@]}"; do
    should_install $app
    if (( $? == 1 )); then
        install_config $app
    fi
done

##
# Vim plugins
##
should_install 'vim plugins'
if (( $? == 1 )); then
    install_vim_plugins
fi
