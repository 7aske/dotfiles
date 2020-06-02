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
    Plug 'tpope/vim-surround'
    Plug 'PotatoesMaster/i3-vim-syntax'
    Plug 'vim-airline/vim-airline'
    Plug 'tpope/vim-fugitive'
    Plug 'airblade/vim-gitgutter'
    Plug 'preservim/nerdcommenter'
    Plug 'dylanaraps/wal.vim'
    Plug 'preservim/nerdtree'
    "Plug 'git@github.com:Valloric/YouCompleteMe.git'
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'leafgarland/typescript-vim'
    Plug 'lyuts/vim-rtags'
    Plug 'kien/ctrlp.vim'
    Plug 'tasn/vim-tsx'
	Plug 'arcticicestudio/nord-vim'
	Plug 'mbbill/undotree'
call plug#end()

" GENERAL ----------------------------------------
let mapleader = " "
syntax on
set nu rnu
set updatetime=100
filetype indent plugin on
set number
set cursorline
set encoding=utf-8
set backspace=indent,eol,start
set laststatus=2
set showcmd
set t_Co=256
set mouse=a
set noshowmode
set smartindent
set noexpandtab tabstop=4 shiftwidth=4
set hlsearch 
set wildmenu
set smartcase
set path+=**
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

" Colorscheme -------------------------------------
"colorscheme wal
set background=dark
set termguicolors
colorscheme nord

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
nnoremap <leader>r :%s/\<<C-r><C-w>\>/

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
nmap <leader>gN <Plug>(GitGutterPrevHunk)
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
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']
nmap <leader><leader> :CtrlP .<CR>

" Coc --------------------------------------------

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()
nmap <leader>gd <Plug>(coc-definition)
nmap <leader>gy <Plug>(coc-type-definition)
nmap <leader>gi <Plug>(coc-implementation)
nmap <leader>gf <Plug>(coc-references)
nmap <leader>gR <Plug>(coc-rename)
nmap <leader>g[ <Plug>(coc-diagnostic-prev)
nmap <leader>g] <Plug>(coc-diagnostic-next)
nnoremap <leader>cr :CocRestartmap <leader>jd <Plug>(coc-definition)

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader><C-l>  <Plug>(coc-format-selected)
nmap <leader><C-l>  <Plug>(coc-format-selected)
nmap <leader><C-L>  <Plug>(coc-format)

" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)
" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)

" Add `:Format` command to format current buffer.
"command! -nargs=0 Format :call CocAction('format')
command! -nargs=0 Prettier :CocCommand prettier.formatFile

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}


