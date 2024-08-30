# dotfiles v2

## Description

Personal dotfiles, scripts and configs that I use on my Linux machines, primarily on Arch distributions.

## Usage

Dotfiles are located in the `.config` and are organized to match the `~/.config` folder in most Linux distributions. You can just copy them over or make symlinks to this folder. Linking `dotifles/.config` to your `~/.config` is not advised.

Script sources are located in the `src` directory and upon installation they are copied to the `$HOME/.local/bin` folder without extension and 
made executable.

`.other` contains some Windows program's configurations I like to use.

`make`

Installs scripts

`make install`

Installs everything

`make zsh`

Installs dotfiles only for `zsh`

