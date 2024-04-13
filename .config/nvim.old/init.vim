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

set packpath=/usr/local/share/nvim/runtime,~/.local/share/nvim/site

call plug#begin('~/.config/nvim/plugged')
	Plug 'jiangmiao/auto-pairs'
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	Plug 'junegunn/goyo.vim'
	Plug 'machakann/vim-highlightedyank'
	Plug 'andymass/vim-matchup'
	Plug 'godlygeek/tabular'
	Plug 'tpope/vim-markdown'
	Plug 'ap/vim-css-color'
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	Plug 'sheerun/vim-polyglot'
	Plug 'vim-airline/vim-airline'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'
    Plug 'PotatoesMaster/i3-vim-syntax'
    Plug 'airblade/vim-gitgutter'
    Plug 'kien/ctrlp.vim'
    Plug 'preservim/nerdcommenter'
    Plug 'tpope/vim-fugitive'
	Plug 'ryanoasis/vim-devicons'
	Plug 'preservim/nerdtree' |
				\ Plug 'Xuyuanp/nerdtree-git-plugin'

	" colorschemes
    Plug 'dylanaraps/wal.vim'
	Plug 'arcticicestudio/nord-vim'
	Plug 'joshdick/onedark.vim'
	Plug 'morhetz/gruvbox'

	Plug 'github/copilot.vim', {'branch': 'release'}
call plug#end()

let g:copilot_filetypes = {
			\ 'markdown': v:true,
			\ }


" GENERAL ----------------------------------------
"set clipboard+=unnamedplus
filetype indent plugin on
let mapleader=" "
set backspace=indent,eol,start
set colorcolumn=80
set cursorline
set encoding=utf-8
set hlsearch
set laststatus=2
set mouse=
set nobackup
set noexpandtab tabstop=4 shiftwidth=4
set noshowmode
set noswapfile
set nowrap
set nu rnu
set number
set path+=**
set showcmd
set signcolumn=yes:2
set ignorecase
set smartindent
set t_Co=256
set updatetime=50
set wildmenu
set isfname+=@-@
syntax on
let &scrolloff = &lines / 5

let g:markdown_syntax_conceal = 0

" Copy to clipboard
vnoremap  <leader>y   "+y
nnoremap  <leader>Y   "+yg_
nnoremap  <leader>y   "+y
nnoremap  <leader>yy  "+yy

" Paste from clipboard
nnoremap <leader>p    "+p
nnoremap <leader>P    "+P
vnoremap <leader>p    "+p
vnoremap <leader>P    "+P

" Enable autocompletion --------------------------
set wildmode=longest,list,full

" Disables automatic commenting on newline -------
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" trim whitespace on save
" autocmd BufWritePre * %s/\s\+$//e

" Colorscheme -------------------------------------
colorscheme nord
set background=dark
set termguicolors
" darker background
highlight Normal      cterm=NONE ctermbg=17 gui=NONE guibg=NONE
highlight LineNr      cterm=NONE ctermbg=17 gui=NONE guibg=NONE
highlight SignColumn  cterm=NONE ctermbg=17 gui=NONE guibg=NONE
highlight ColorColumn cterm=NONE ctermbg=16 gui=NONE guibg=NONE


" STATUS BAR -------------------------------------
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'        " disable file paths in tabline
let g:airline#extensions#tabline#show_close_button = 0  " remove 'X' at the end of the tabline
let g:airline#extensions#tabline#tab_nr_type = 1        " tab number

" BINDINGS ---------------------------------------

let g:loaded_matchit = 1

nmap <CR> o<C-[>
" Edit vimr configuration file
nnoremap <leader>Ve :e $MYVIMRC<CR>
" Reload vimr configuration file
nnoremap <leader>Vr :source $MYVIMRC<CR>

" Replace word under cursor ----------------------
nnoremap <leader>r :%s/\<<C-r><C-w>\>/
vnoremap <leader>r "ry :%s/<C-R>=substitute(escape(@r, '/\'), "\n", '\\n', 'ge')<CR>/

" Toggle comments --------------------------------
map <C-\> <Plug>NERDCommenterToggle^j

" Sweet Sweet FuGITive
nmap <leader>gq :diffget //3<CR>
nmap <leader>gp :diffget //2<CR>
nmap <leader>gs :G<CR>

" open terminal in current directory
nnoremap <leader>t :silent !env $TERMINAL &<CR>

" Correct indentation JSON files
nmap :json<CR> :%!python -m json.tool<CR>

" Vertical/Horizontal resize abbreviation
ca vr vertical resize
ca hr resize

map <leader>g{ :GitGutterNextHunk<CR>
map <leader>g} :GitGutterPrevHunk<CR>
map <leader>gu :GitGutterUndoHunk<CR>
map <leader>gh :GitGutterPreviewHunk<CR>

" Coc Bindings -----------------------------------
" Use <c-space> to trigger completion.

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')
command! -nargs=0 Prettier :CocCommand prettier.formatFile

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')
command! -nargs=0 Prettier :CocCommand prettier.formatFile
nnoremap <leader>cr :CocRestartmap
inoremap <silent><expr> <c-space> coc#refresh()
nmap <leader>gd     :call CocActionAsync('jumpDefinition', 'tabe')<CR>
nmap <leader>gD     <Plug>(coc-references)
nmap <leader>gi     :call CocActionAsync('jumpImplementation', 'tabe')<CR>
nmap <leader>gt     <Plug>(coc-type-definition)
nmap <leader>g[     <Plug>(coc-diagnostic-prev)
nmap <leader>g]     <Plug>(coc-diagnostic-next)
nmap <leader>rn     <Plug>(coc-rename)
nmap <leader>rs     <Plug>(coc-search)
xmap <leader><C-l>  <Plug>(coc-format-selected)
vmap <leader><C-l>  <Plug>(coc-format-selected)
nmap <leader><C-l>  <Plug>(coc-format-selected)
nmap <C-A-l>        <Plug>(coc-format)
nmap <leader>qf     <Plug>(coc-fix-current)
nmap <leader>ac     <Plug>(coc-codeaction)
xmap <leader>a      <Plug>(coc-codeaction-selected)
nmap <leader>a      <Plug>(coc-codeaction-selected)

" Tabs and Windows -------------------------------
nmap <silent> <C-T>1       :tabn 1<CR>
nmap <silent> <C-T>2       :tabn 2<CR>
nmap <silent> <C-T>3       :tabn 3<CR>
nmap <silent> <C-T>4       :tabn 4<CR>
nmap <silent> <C-T>5       :tabn 5<CR>
nmap <silent> <C-T>6       :tabn 6<CR>
nmap <silent> <C-T>7       :tabn 7<CR>
nmap <silent> <C-T>8       :tabn 8<CR>
nmap <silent> <C-T>9       :tabn 9<CR>
nmap <silent> <C-T>c       :tabnew<CR>
nmap <silent> <C-W>c       :tabnew<CR>
nmap <silent> <C-W>t       :tabnew<CR>
nmap <silent> <C-T>q       :tabclose<CR>
nmap <silent> <C-W>w       :Windows<CR>
nmap <silent> <C-W>Q       :q!<CR>
nmap <silent> <A-Left>     :tabprev<CR>
nmap <silent> <A-Right>    :tabnext<CR>
nmap <silent> <C-A-Right>  :bnext<CR>
nmap <silent> <C-A-Left>   :bprevious<CR>
" <C-W>T moves window to a new tab


" NERDTree ---------------------------------------
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
map <A-1> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let NERDTreeIgnore = ['\.git$', 'node_modules$', '__pycache__']

" Spellchecker -----------------------------------
map <F6> :setlocal spell! spelllang=en<CR>
map <F7> :setlocal spell! spelllang=sr@latin<CR>

" fzf --------------------------------------------
let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.8 } }
let $FZF_DEFAULT_OPTS='--reverse'
map <leader><leader> :Files<CR>
map <C-F> :Rg<CR>
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, {'options': ['--layout=reverse', '--info=inline', '--preview', '~/.config/nvim/plugged/fzf.vim/bin/preview.sh {}']}, <bang>0)

" compiler
map <leader>c :w! \| silent !npile <c-r>%<CR>
map <leader>m :w! \| silent !make<CR>


" Coc --------------------------------------------

" disable running coc at startup
 let g:coc_start_at_startup = v:false

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

set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
