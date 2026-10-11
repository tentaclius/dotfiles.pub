function ModMap(modes, key, expr)
  for c in a:modes
    exe c . "noremap " . a:key . " " . a:expr
  endfor
endfunction
command! -nargs=+ ModMap call ModMap(<f-args>)

function PluginExists(name)
  if !exists('g:plugins_dir') || empty(g:plugins_dir)
    let g:plugins_dir = has('nvim') ? '~/.local/share/nvim/site/pack/paqs/start/' : '~/.vim/plugged' 
  endif
  return len(glob(g:plugins_dir . '/' . a:name)) > 0
endfunction

function! GetVisualSelection()
    " Credit: @FocusedWolf and @xolox on StackOverflow
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0 | return getline('.') | endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

"=================================================================================
" Options
"
set title
set clipboard+=unnamedplus
set ts=2
set shiftwidth=2
set expandtab
set smartindent
set nowrap
set foldmethod=syntax
set nofoldenable
set conceallevel=2
set concealcursor=nv
set hlsearch
set ignorecase
set smartcase
set hidden
set noswapfile
set textwidth=120
setglobal laststatus=2
silent! set guifont=DroidSansMono\ Nerd\ Font:h10
silent! set termguicolors

syntax on
filetype plugin on
filetype plugin indent on
silent! colorscheme lucius

"let currtime = strftime('%R')
"if currtime > '17:00' || currtime < '07:00'
  "set background=dark
"else
  "set background=light
"endif
set background=dark

"=================================================================================
" keys and commands
"
let @l='λ'
nnoremap <leader>b :Ls<cr>:b 
nnoremap <F9> :below sp\|Scratch<cr>
nnoremap <F9> :tabe\|Scratch<cr>
ModMap nixtv <F12> 
ModMap nixtv  

" font scale
if has('nvim')
  nnoremap <C-=> :let g:neovide_scale_factor=g:neovide_scale_factor+0.05<cr>
  nnoremap <C--> :let g:neovide_scale_factor=g:neovide_scale_factor-0.05<cr>
endif

" terminal functions
if has('nvim')
  function VimTerm()
    enew
    let g:term_bufnr = termopen('bash')
    exe 'file term' . g:term_bufnr
    setlocal hidden
    call TermSend('function NvimEdit() { nvim --server "$NVIM" --remote "$(realpath $1)"; }; alias r=NvimEdit')
  endfunction
  function VimTermCmd(cmd)
    sp|ene|set buftype=nofile|setlocal nohidden
    call termopen(a:cmd)
    normal i
  endfunction
  function TermSend(text)
    call luaeval('vim.api.nvim_chan_send(tonumber(vim.g.term_bufnr), _A)', a:text .. "\n")
  endfunction
  function TermSetup()
    let g:term_bufnr = matchlist(bufname(), '^term\(\d\+\)')[1]
    silent! normal i
  endfunction
else
  function VimTerm()
    :term ++curwin ++noclose
    let g:term_bufnr = bufnr()
    exe 'file term'.bufnr()
    setlocal hidden
    au BufEnter <buffer> :setlocal hidden
    call TermSend('function VimEdit() { echo -e "\033]51;[\"drop\", \"$(realpath $1)\"]\007"; }; alias r=VimEdit')
  endfunction
  function VimTermCmd(cmd)
    let tmpfile = '/tmp/vicmd'
    call writefile([a:cmd], tmpfile)
    exe 'term' 'sh' tmpfile
  endfunction
  function TermSend(text)
    call term_sendkeys(g:term_bufnr, a:text .. "\n")
  endfunction
  function TermSetup()
    let g:term_bufnr = bufnr()
    silent! normal i
  endfunction
endif

autocmd BufWinEnter,WinEnter * if &buftype == 'terminal' && bufname() =~ '^term\d\+$' | call TermSetup() | endif

function! TermSendParagraph()
  normal vipy
  call TermSend(@")
endfunction
function! TermSendMdCodeBlock()
  let curpos = getcurpos()
  let firstline = search('```', 'bcnW')
  call cursor(firstline + 1, 0)
  let lastline = search('```', 'nW')
  if firstline != 0 && lastline != 0
    call TermSend(getline(firstline + 1, lastline - 1)->join("\r"))
  endif
  call cursor(curpos[1], curpos[2])
endfunction
function! TermFind()
  if exists('g:term_bufnr') && bufname() == 'term' .. g:term_bufnr
    hide
  elseif exists('g:term_bufnr') && bufexists('term' .. g:term_bufnr)
    exe 'buffer' 'term'..g:term_bufnr
  else
    let termbufs = getbufinfo(#{buflisted: 1})->filter({i, v -> v.name =~ '\<term\d\+$'})
    if !termbufs->empty()
      exe 'buffer' termbufs[0].name
    else
      call VimTerm()
    endif
  endif
endfunction
function! TermSplit()
  let termwin = gettabinfo(tabpagenr())[0].windows
        \ ->map({i, v -> v->getwininfo()[0]})
        \ ->map({i, v -> #{buf: v.bufnr->getbufinfo()[0].name, winid: v.winid}})
        \ ->filter({i, v -> v.buf =~ '\(^\|/\)term\d\+$'})
  if !empty(termwin)
    call win_execute(termwin[0].winid, 'q')
    "call win_gotoid(termwin[0].winid)
  else
    below split
    call TermFind()
  endif
endfunction

command TermNew call VimTerm()
command Term call TermFind()
command -narg=1 TermCmd call VimTermCmd(<f-args>)
command -range TermSend call TermSend(getline(<line1>, <line2>)->join("\n"))
command -range TermSendV call TermSend(GetVisualSelection())
nnoremap  :call TermSend(getline('.'))<cr>
vnoremap  :TermSendV<cr>
nnoremap p :call TermSendParagraph()<cr>
nnoremap m :call TermSendMdCodeBlock()<cr>
nnoremap n :call VimTermCmd(getline('.'))<cr>
vnoremap n :call VimTermCmd(GetVisualSelection()))<cr>
nnoremap <leader>t :Term<cr>
nnoremap <F10> :call TermSplit()<cr>
nnoremap <F10> :tabe\|exe 'Term'<cr>
tnoremap <F10> :quit<cr>
tnoremap <F10> :tabe\|exe 'TermNew'<cr>

" toggle concealcursor
nnoremap <leader>c :let &concealcursor = empty(&concealcursor) ? 'nv' : ''<cr>

" alt-n to go to n'th view
for i in range(1, 9)
  " for Vim
  exe 'nnoremap '.i i.'gt'
  exe 'ModMap vit '.i ''.i.'gt'
  " for nvim:
  exe 'ModMap vit <M-'.i.'>' ''.i.'gt'
endfor
" for Vim in Ghostty
ModMap nvit ± 1gt
ModMap nvit ² 2gt
ModMap nvit ³ 3gt
ModMap nvit ´ 4gt
ModMap nvit µ 5gt
ModMap nvit ¶ 6gt
ModMap nvit · 7gt
ModMap nvit ¸ 8gt
ModMap nvit ¹ 9gt

" convenience commands
command! Cfg e ~/dotfiles/vim-commons.vim
command! Cfv e ~/.vimrc
command! Cfn e ~/.config/nvim/init.fnl
command! D windo diffthis         " diff all opened windows
command! Cd lcd %:p:h             " change to file's directory
command! -bang Bd b#|bd<bang>#    " delete the buffer without closing the window
command! Bx w|bd                  " save and close the buffer
command! Scratch ene|set buftype=nofile|setlocal nohidden  " make a scratch buffer
command! Xx windo x

" encryption
if executable('gpg') && executable('base64')
  command! -range Encr <line1>,<line2>!gpg --batch --symmetric --passphrase-file ~/p.txt|base64
  command! -range Decr <line1>,<line2>!base64 -d|gpg --batch --passphrase-file ~/p.txt -d 2>/dev/null
  let @e='!gpg --batch --symmetric --passphrase-file ~/p.txt|base64'
  let @d='!base64 -d|gpg --batch --passphrase-file ~/p.txt -d 2>/dev/null'

  " decrypt and copy
  command! -range Decr <line1>,<line2>!base64 -d|gpg --batch --passphrase-file ~/p.txt -d 2>/dev/null
  function DecrYank() range
    let lines = getline(a:firstline, a:lastline)
    let @+ = system('base64 -d|gpg --batch --passphrase-file ~/p.txt -d 2>/dev/null', lines)
  endfunction
  command! -range DecrYank <line1>,<line2> call DecrYank()
  vnoremap d :DecrYank<cr>
endif

" execute text as shell script in-place
function ExecShell(cmd, ll)
  let out = systemlist(a:cmd)
  call append(a:ll, out)
endfunction
function ExecShellMdCode()
  YankCodeBlock
  call ExecShell(@", line("'>"))
endfunction
function ExecShellParagraph()
  normal vipy
  call ExecShell(@", line("'>"))
endfunction
command! -range ExecShell call ExecShell(GetVisualSelection(), line("'>"))
vnoremap  :ExecShell<cr>
nnoremap  :call ExecShell(getline('.'), line('.'))<cr>
nnoremap p :call ExecShellParagraph()<cr>
nnoremap m :call ExecShellMdCode()<cr>

" execute vimscript in-place
function! ExecVim() range
  let data = getbufline(bufnr(), a:firstline, a:lastline)->execute()->split('\n')
  call append(a:lastline, data)
endfunction
nnoremap v :.call ExecVim()<cr>
vnoremap v :call ExecVim()<cr>
nnoremap r :.source<cr>
vnoremap r :source<cr>

" yank markdown code block
command! YankCodeBlock :silent :?^\s*```?+1,/^\s*```$/-1 yank
nnoremap y :YankCodeBlock<cr>

" delete buffers
function! CloseHiddenBuffers(cmd = 'bd')
  for buf in getbufinfo(#{buflisted: 1})
    if empty(buf.windows) | exe a:cmd buf.bufnr | endif
  endfor
endfunction
command! -bang BD call CloseHiddenBuffers('bd<bang>')

" editable buffer list
function! BufPad()
  function! s:BufPadReload()
    % delete
    eval getbufinfo(#{buflisted: 1})->map({i, buf -> buf.name})
          \ ->filter({i, name -> len(name) > 0})->append(1)
    1 delete
  endfunction

  function! s:BufPadEnter()
    const lnk = getline('.')
    for win in gettabinfo(tabpagenr())[0].windows
      if win != win_getid()
        call win_gotoid(win)
        exe 'edit' lnk
        return
      endif
    endfor
    exe 'edit' lnk
  endfunction

  function! s:BufPadDel()
    exe 'bd' getline('.')
    delete
  endfunction

  45 vsplit
  enew
  setlocal buftype=nofile
  setlocal filetype=dirvish
  setlocal conceallevel=2
  setlocal concealcursor=nv
  setlocal nohidden
  call s:BufPadReload()

  nnoremap <buffer> <cr> :call <SID>BufPadEnter()<cr>
  nnoremap <buffer> <leader>d :call <SID>BufPadDel()<cr>
  nnoremap <buffer> R :call <SID>BufPadReload()<cr>
endfunction
command! BMList call BufPad()

if executable('rg')
  let @r="rg -g '**' -g '!.git' --path-separator=// -n . -e "
  "set grepprg=rg\ --vimgrep
endif
let @f = 'find . -type f | grep -i '

function! Ls()
  for buf in getbufinfo(#{buflisted: 1})
    let name = empty(buf.name) ? '[Scratch]' : buf.name->matchlist('\([^/]*\)/*$')[1]
    let marks = buf.bufnr == bufnr() ? '%' : buf.bufnr == bufnr('#') ? '#' : ' '
    echon printf("% 3d%s %s\n", buf.bufnr, marks, name)
  endfor
endfunction
command! Ls call Ls()

" concealment helper
function Conceal(ptn)
  exe 'sy match MyConceal '''.a:ptn.''' conceal cchar=~'
endfunction
command! -narg=1 Conceal call Conceal(<f-args>)

" some convenience keys for csound
function CsoundRunFile()
  :w
  call TermSend('')
  call TermSend('csound '..expand('%:p'))
endfunction

function CsoundHotkeys()
  nnoremap  :call system('nc -u 127.0.0.1 1234',getline('.'))<cr>
  vnoremap  :call system('nc -u 127.0.0.1 1234',GetVisualSelection())<cr>
  nnoremap r :call CsoundRunFile()<cr>
endfunction
autocmd filetype csound :call CsoundHotkeys()

"=================================================================================
" PLUGINS
"=================================================================================

if PluginExists('vimwiki')
  source ~/dotfiles/vw-wrap.vim
endif

if PluginExists("coc.nvim") && !PluginExists("nvim-lspconfig") && 0
  " Use tab for trigger completion with characters ahead and navigate
  inoremap <silent><expr> <TAB>
        \ coc#pum#visible() ? coc#pum#next(1) :
        \ CheckBackspace() ? "\<Tab>" :
        \ coc#refresh()
  inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
  
  " Make <CR> to accept selected completion item or notify coc.nvim to format
  inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
        \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
  
  function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
  endfunction
  
  " Use <c-space> to trigger completion
  if has('nvim')
    inoremap <silent><expr> <c-space> coc#refresh()
  else
    inoremap <silent><expr> <c-@> coc#refresh()
  endif
  
  " Use `[g` and `]g` to navigate diagnostics
  nmap <silent> [g <Plug>(coc-diagnostic-prev)
  nmap <silent> ]g <Plug>(coc-diagnostic-next)
  
  " Use K to show documentation in preview window
  nnoremap <silent> K :call ShowDocumentation()<CR>
  
  function! ShowDocumentation()
    if CocAction('hasProvider', 'hover')
      call CocActionAsync('doHover')
    else
      call feedkeys('K', 'in')
    endif
  endfunction
  
  " Format selected
  xmap <leader>f  <Plug>(coc-format-selected)
  nmap <leader>f  <Plug>(coc-format-selected)

  " Goto code
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gy <Plug>(coc-type-definition)
  nmap <silent> gi <Plug>(coc-implementation)
  nmap <silent> gr <Plug>(coc-references)
  nmap <silent> gn <Plug>(coc-rename)
endif

if PluginExists('fzf.vim')
  nnoremap  :Files<cr>
  nnoremap  :Buffers<cr>
  nnoremap x :Commands <cr>
  silent! delcommand Filetypes
endif

if PluginExists('vim-startify')
  let g:startify_session_persistence = 1
endif

if PluginExists('nerdcommenter')
  let g:NERDCreateDefaultMappings = 0
  ModMap nv c <plug>NERDCommenterToggle
  inoremap c <plug>NERDCommenterToggle
endif

if PluginExists('vim-dirvish')
  let g:dirvish_mode = ':sort ,.*/,'
endif

if PluginExists('vim-airline')
  let g:airline_theme='pencil'
  let g:airline_powerline_fonts=1
  setglobal laststatus=1
endif

if PluginExists('nerdcommenter')
  let g:NERDCreateDefaultMappings=0
  ModMap nv c <plug>NERDCommenterToggle
endif

if PluginExists('vim-gitgutter')
  let g:gitgutter_enabled = 0
  nnoremap <leader>gg :GitGutterToggle<cr>
  nnoremap <leader>gs :GitGutterStageHunk<cr>
endif

if PluginExists('delimitmate')
  au FileType lisp,scheme,guile,clojure let b:delimitMate_quotes='"'
endif

if PluginExists('calendar.vim') && PluginExists('vimwiki')
  source ~/dotfiles/cal-wrap.vim
endif

" Startup
au VimEnter * silent! call VimStartup()
function VimStartup()
  if argc() == 0 && v:argv[-1] != '-'
    "SL current
    VWC
  endif

  command! -nargs=* G :Git ++curwin <args>
  command! -nargs=* Gw e $w | :Git ++curwin <args>
  command! -nargs=* Ge e $we | :Git ++curwin <args>
  command! Gtree G log --all --decorate --oneline --graph

  if exists(':FZF')
    delcommand BMarks
    delcommand Windows
  endif
endfunction
