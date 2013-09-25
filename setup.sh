#!/bin/zsh
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
typeset -A config_files

config_files[X11]="Xresources"
config_files[git]="gitconfig"
config_files[vim]="vimrc"

cd $(dirname $0)

##
# Create a symbolic link safely
#
# Params:
#    $1 = Target name
#    $2 = Link name
##
safe_make_link() {
    target=$1
    link_name=$2

    # Delete the symlink if it already exists
    if [[ -h $link_name ]]; then
        rm $link_name
    fi

    # If the file already exists, back it up
    if [[ -e $link_name ]]; then
        echo -n "warning: $link_name already exists - backing up as $link_name.backup"
        mv $link_name $link_name.backup
    fi

    # Create link
    ln -s $target $link_name
}

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
        safe_make_link `pwd`/$1/$file ~/.$file
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

        safe_make_link "$target" "$link_name"
    done
}

##
# Install vim plugin configuration
##
install_vim_plugin_conf() {
    mkdir -p ~/.vim/dfconf/
    for dir in $(ls vim/conf); do
        target=$(pwd)/vim/conf/$dir
        link_name=~/.vim/dfconf/$dir

        safe_make_link $target $link_name
    done
}

echo Updating submodules...
git submodule update --init --recursive

##
# Prompt the user to install each config file
##
for app in ${(k)config_files}; do
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
    # Compile YouCompleteMe with clang and C# support
    if [[ -e vim/plugins/YouCompleteMe ]]; then
        cd vim/plugins/YouCompleteMe
        ./install.sh --clang-completer --omnisharp-completer
        cd -
    fi
    install_vim_plugins
    install_vim_plugin_conf
fi
