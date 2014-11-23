#!/bin/zsh
###
# Copy over config files
#
# Authors:
#   Robert Clipsham <robert@octarineparrot.com>
###

set -x

# AA of config files
# Example:
#    config_files[foobar]="cf1 cf2"
# Result:
#    ln -s foobar/cf1 ~/.cf1
#    ln -s foobar/cf2 ~/.cf2
typeset -A config_files

config_files[X11]="Xresources xinitrc"
config_files[git]="gitconfig"
config_files[vim]="vimrc"

# As above, but for directories in ~/.config/
typeset -A config_dirs

config_dirs[awesome]="awesome"

cd $(dirname $0)

##
# Create a symbolic link safely
#
# Params:
#    $1 = Target name
#    $2 = Link name
##
function safe_make_link() {
    local target=$1
    local link_name=$2

    # Delete the symlink if it already exists
    if [[ -h $link_name ]]; then
        rm $link_name
    fi

    # If the file already exists, back it up
    if [[ -e $link_name ]]; then
        echo "warning: $link_name already exists - backing up as $link_name.backup"
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
#    $2 = Alternative message to print (optional)
# Returns:
#    1 if config files should be copied, 0 otherwise
##
function should_install() {
    if [[ -n "$2" ]]; then
        echo -n $2
    else
        echo -n "Install config files for $1? [Y/n]: "
    fi
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
function install_config() {
    for file in ${(s/ /)config_files[$1]}; do
        safe_make_link `pwd`/$1/$file ~/.$file
    done
}

##
# Install configuration directories for $1
#
# Params:
#    $1 = Application to install ~/.config/ directories for
##
function install_config_dir() {
    for dir in ${(s/ /)config_dirs[$1]}; do
        safe_make_link `pwd`/$dir ~/.config/$dir
    done
}

##
# Install vim plugins
##
function install_vim_plugins() {
    mkdir -p ~/.vim/dfplugins/
    for dir in $(ls vim/plugins); do
        local target=$(pwd)/vim/plugins/$dir
        local link_name=~/.vim/dfplugins/$dir

        safe_make_link "$target" "$link_name"
    done
}

##
# Install vim plugin configuration
##
function install_vim_plugin_conf() {
    mkdir -p ~/.vim/dfconf/
    for dir in $(ls vim/conf); do
        local target=$(pwd)/vim/conf/$dir
        local link_name=~/.vim/dfconf/$dir

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

for app in ${(k)config_dirs}; do
    should_install $app
    if (( $? == 1 )); then
        install_config_dir $app
    fi
done

##
# Vim plugins
##
should_install 'vim plugins'
if (( $? == 1 )); then
    # Compile YouCompleteMe with clang and C# support
    should_install plugin "Compile YouCompleteMe? [Y/n] "
    if (( $? == 1 )) && [[ -e vim/plugins/YouCompleteMe ]]; then
        if [[ -n $(which xbuild) || -n $(which msbuild) ]]; then
            local ycm_flags="--omnisharp-completer"
        else
            local ycm_flags=""
        fi
        cd vim/plugins/YouCompleteMe
        should_install plugin "Use system libclang? [Y/n] "
        if (( $? == 1 )); then
            ./install.sh --clang-completer $ycm_flags --system-libclang
        else
            ./install.sh --clang-completer $ycm_flags
        fi
        cd -
    fi
    should_install plugin "Install ghc-mod? [Y/n] "
    if (( $? == 1 )); then
        cabal update
        cabal install ghc-mod
    fi
    install_vim_plugins
    install_vim_plugin_conf
fi
