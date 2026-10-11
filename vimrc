" =================================================================================
" Plugins 
"
if empty(glob("~/.vim/autoload/plug.vim"))
  !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'mhinz/vim-startify'  " startup screen and session manager
"Plug 'neoclide/coc.nvim', {'branch': 'release'}  " code completion
Plug 'justinmk/vim-dirvish'  " in-buffer file manager
Plug 'junegunn/fzf', {'dir': '~/.config/nvim/fzf', 'do': './install --all' }  " fzf binary installer
Plug 'junegunn/fzf.vim'  " fuzzy finder
Plug 'vimwiki/vimwiki'  " note taking
Plug 'itchyny/calendar.vim'  " calendar
Plug 'tpope/vim-fugitive'  " Git wrapper
"Plug 'scrooloose/nerdcommenter'  " (un-)comment lines
Plug 'machakann/vim-sandwich'  " manage parens
Plug 'Raimondi/delimitMate'  " automatic parens
Plug 'jonathanfilip/vim-lucius'  " colorscheme
Plug 'romainl/vim-cool'  " clear search highlighting automatically
"Plug 'mg979/vim-visual-multi', {'branch': 'master'}  " multicursor
"Plug 'bakpakin/fennel.vim'  " Fennel syntax highlighting
call plug#end()

source ~/dotfiles/vim-commons.vim
