"            _           
" _ ____   _(_)_ __ ___  
" | '_ \ \ / / | '_ ` _ \ 
" | | | \ V /| | | | | | |
" |_| |_|\_/ |_|_| |_| |_|

" PLUGINS ----------------------------------------
if ! filereadable(expand('~/.config/nvim/autoload/plug.vim'))
    echo "Downloading junegunn/vim-plug to manage plugins..."
    silent !mkdir -p ~/.config/nvim/autoload/
    silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ~/.config/nvim/autoload/plug.vim
    autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.config/nvim/plugged')
    Plug 'PotatoesMaster/i3-vim-syntax'
    Plug 'vim-airline/vim-airline'
    Plug 'tpope/vim-fugitive'
    Plug 'airblade/vim-gitgutter'
    Plug 'preservim/nerdcommenter'
    Plug 'dylanaraps/wal.vim'
    Plug 'preservim/nerdtree'
    Plug 'kien/ctrlp.vim'
    Plug 'tasn/vim-tsx'
call plug#end()

" GENERAL ----------------------------------------
let mapleader = " "
set nu rnu
set updatetime=100
syntax on
filetype indent plugin on
syntax enable
set number
set cursorline
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
set path+=**
set wildmenu
set clipboard+=unnamedplus

" " Copy to clipboard
vnoremap  <leader>y   "+y
nnoremap  <leader>Y   "+yg_
nnoremap  <leader>y   "+y
nnoremap  <leader>yy  "+yy

" " Paste from clipboard
nnoremap <leader>p    "+p
nnoremap <leader>P    "+P
vnoremap <leader>p    "+p
vnoremap <leader>P    "+P

" Enable autocompletion --------------------------
set wildmode=longest,list,full

" Disables automatic commenting on newline -------
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" Wal Colors -------------------------------------
colorscheme wal

" Check file in shellcheck -----------------------
map <leader>s :!clear && shellcheck %<CR>

" STATUS BAR -------------------------------------
" Handled by airline plugin

" BINDINGS ---------------------------------------

" ESC key to jk or kj or jj ----------------------
inoremap kj <Esc>
inoremap jk <Esc>
inoremap jj <Esc>

" No highlight search ----------------------------
nnoremap :/<CR> :nohlsearch<CR>

" Replace word under cursor ----------------------
nnoremap <Leader>r :%s/\<<C-r><C-w>\>/

" Switch windows with Alt + Arrows ---------------
nmap <silent> <A-Left>  <C-W>h
nmap <silent> <A-Right> <C-W>l
nmap <silent> <A-Up>    <C-W>k
nmap <silent> <A-Down>  <C-W>j

" Toggle comments --------------------------------
map <C-\> <Plug>NERDCommenterToggle^j

"GitGutter Plugin --------------------------------
nmap <leader>gp <Plug>(GitGutterPreviewHunk)
nmap <leader>ga <Plug>(GitGutterStageHunk)
nmap <leader>gn <Plug>(GitGutterNextHunk)
nmap <leader>gb <Plug>(GitGutterPrevHunk)
nmap <leader>gu <Plug>(GitGutterUndoHunk)

" Paste multiple in visual mode ------------------
xnoremap p pgvy

" Correct indentation JSON files
nmap :json<CR> :%!python -m json.tool<CR>

" Abbreviations ----------------------------------
nmap <C-_> :set hlsearch!<CR>

" Vertical resize abbreviation
ca vr vertical resize

" Tabs -------------------------------------------
nmap <silent> <C-T>1 :tabn 1<CR>
nmap <silent> <C-T>2 :tabn 2<CR>
nmap <silent> <C-T>3 :tabn 3<CR>
nmap <silent> <C-T>4 :tabn 4<CR>
nmap <silent> <C-T>5 :tabn 5<CR>
nmap <silent> <C-T>6 :tabn 6<CR>
nmap <silent> <C-T>7 :tabn 7<CR>
nmap <silent> <C-T>8 :tabn 8<CR>
nmap <silent> <C-T>9 :tabn 9<CR>
nmap <silent> <C-T>c :tabnew<CR>

" NERDTree --------------------------------------- 
autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <A-1> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1

" Spellchecker -----------------------------------
map <F6> :setlocal spell! spelllang=en<CR>

" CtrlP ------------------------------------------

nmap <leader><leader> :CtrlP .<CR>
