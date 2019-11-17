" GENERAL ----------------------------------------
" PLUGINS

if ! filereadable(expand('~/.config/nvim/autoload/plug.vim'))
	echo "Downloading junegunn/vim-plug to manage plugins..."
	silent !mkdir -p ~/.config/nvim/autoload/
	silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ~/.config/nvim/autoload/plug.vim
	autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.config/vim/plugged')
Plug 'tpope/vim-surround'
Plug 'PotatoesMaster/i3-vim-syntax'
Plug 'vimwiki/vimwiki'
Plug 'terryma/vim-multiple-cursors'
call plug#end()

let mapleader =" "

" Enable autocompletion:
set wildmode=longest,list,full

" Disables automatic commenting on newline:
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

syntax enable
set number
set cursorline
hi CursorLine cterm=bold term=bold ctermbg=black
" set ruler
set encoding=utf-8
set backspace=indent,eol,start
set laststatus=2
set showcmd
set t_Co=256
set mouse=a
set noshowmode
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch 

" Check file in shellcheck:
map <leader>s :!clear && shellcheck %<CR>

syntax on
filetype indent plugin on

" STATUS BAR -------------------------------------

" Status bar style
set statusline=
set statusline +=%7*%{(mode()=='n')?'\ \ N\ ':''}
set statusline +=%8*%{(mode()=='i')?'\ \ I\ ':''}
set statusline +=%8*%{(mode()=='R')?'\ \ R\ ':''}
set statusline +=%6*%{(mode()=='v')?'\ \ V\ ':''}
set statusline +=%1*\ %n\ %*        "  buffer number
set statusline +=%3*%{&ff}%*        "  file format
set statusline +=%5*\ %y%*          "  file type
set statusline +=%4*\ %<%F%*        "  full path
set statusline +=%2*%m%*            "  modified flag
set statusline +=%1*%=%5l%*         "  current line
set statusline +=%2*/%L%*           "  total lines
set statusline +=%1*%4v\ %*         "  virtual column number
set statusline +=%2*0x%04B\ %*      "  character under cursor
set statusline +=%3*%{winwidth(0)}  "  window width

" Colors for status bar
hi User1 ctermfg=166 ctermbg=236
hi User2 ctermfg=9   ctermbg=236
hi User3 ctermfg=13  ctermbg=236
hi User4 ctermfg=12  ctermbg=236
hi User5 ctermfg=11  ctermbg=236

hi User6 ctermfg=255 ctermbg=60
hi User7 ctermfg=255 ctermbg=28
hi User8 ctermfg=255 ctermbg=94

" BINDINGS ---------------------------------------

" ESC key to jk or kj or jj
inoremap kj <Esc>
inoremap jk <Esc>
inoremap jj <Esc>

" No highlight search
nnoremap :/<CR> :nohlsearch<CR>

" Automaticaly close brackets
inoremap {      {}<Left>
inoremap {<CR>  {<CR>}<Esc>O
inoremap {{     {
inoremap {}     {}


" Automaticaly close brackets
inoremap (      ()<Left>
inoremap (<CR>  (<CR>)<Esc>O
inoremap ((     (
inoremap ()     ()


" Automaticaly close brackets
inoremap [      []<Left>
inoremap [<CR>  [<CR>]<Esc>O
inoremap [[     [
inoremap []     []

" Automaticaly close quotes
inoremap "      "<Left>
inoremap "<CR>  "<CR><Esc>O
inoremap ""     "
inoremap "     ""

" Switch windows with Alt + Arrows
nmap <silent> <A-Left> <C-W>h
nmap <silent> <A-Right> <C-W>l
nmap <silent> <A-Up> <C-W>k
nmap <silent> <A-Down> <C-W>j

" Previous/Next/Toggle switching buffers
"nmap <C-P> :bprev<CR>
"nmap <C-N> :bnext<CR>
nmap <C-B> <C-^>
nmap :bt<CR> <C-^>

" Toggle comments
map <C-@> <Plug>NERDCommenterToggle

" GitGutter Plugin
nmap :gd <Plug>GitGutterPreviewHunk
nmap :ga <Plug>GitGutterStageHunk
nmap :gn <Plug>GitGutterNextHunk

" FZF Plugin -------------------------------------------------------------------
" Files (':Files' with devicons)
nmap <C-p> :call Fzf_files_with_dev_icons($FZF_DEFAULT_COMMAND)<CR>
" Git tracked files (ignore submodules + .gitignore files)
nmap <C-g> :call Fzf_files_with_dev_icons("git ls-files \| uniq")<CR>
" Lines
nmap <C-f> :Lines<CR>
" Tags
nmap <C-t> :Tags<CR>
" Git diff
nmap <C-d> :call Fzf_git_diff_files_with_dev_icons()<CR> 

" Paste multiple in visual mode
xnoremap p pgvy


" Correct indentation JSON files
nmap :json<CR> :%!python -m json.tool<CR>

nmap <C-_> :set hlsearch!<CR>

" Abbreviations ----------------------------------

" Abbreviation for ack tool
ca Ack Ack!
nnoremap <C-a> :Ack!<Space>

" Vertical resize abbreviation
ca vr vertical resize

