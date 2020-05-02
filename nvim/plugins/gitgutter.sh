#!/usr/bin/env sh

mkdir -p ~/.config/nvim/pack/airblade/start &&\
cd ~/.config/nvim/pack/airblade/start &&\
git clone https://github.com/airblade/vim-gitgutter.git &&\
nvim -u NONE -c "helptags vim-gitgutter/doc" -c q
