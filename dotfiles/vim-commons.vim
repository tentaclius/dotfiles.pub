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
  source ~/dotfiles/wrap-vimwiki.vim
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
  let g:vw_calendar_id = '1'                " essentially, the directory name at ~/.cache/calendar.vim/local/event/
  let g:vw_calendar_ignore_old_notes = 0    " if 1 diary files earlier than today will not be processed
  let g:vw_calendar_keep_old_tasks = 0      " if 0, old vimwiki tasks will be removed
  let g:calendar_date_full_month_name = 1

  function VwCalSync()
    function! s:FilterExistingTasks(i, v)
      " choose what tasks to remove from the calendar's cache
      const src = a:v->get('source', '')
      const start = a:v->get('start', {})
      const date = start->get('date', start->get('dateTime', ''))
      return src != 'vimwiki' || (exists('g:vw_calendar_keep_old_tasks') && g:vw_calendar_keep_old_tasks && date < strftime('%F'))
    endfunction

    function! s:MapTask(day, i, v)
      " convert a task string into the calendar object
      const next_day = strftime('%F', strptime('%F', a:day[0:9]) + 60*60*24)
      const mtch = a:v->matchlist('^\s*\* \(\[[ xcm]\]\s\)\?\((\(\d\d\?:\d\d\)\(-\(\d\d:\d\d\)\)*) \)\?\(.*\)$')
      const time = mtch[3]
      const endtime = mtch[5]
      const taskmark = mtch[1] =~ 'x' ? '☒ '
            \ : mtch[1] =~ 'c' ? '🗙 '
            \ : mtch[1] =~ 'm' ? '↷ '
            \ : mtch[1] =~ ' ' ? '☐ '
            \ : ''
      const descr = mtch[6]->substitute('\[\([^\]]\+\)\]([^()]\+)', '\1', 'g')->substitute('\[\[\([^\]]\+\)\]\]', '\1', 'g')
      const summary = taskmark .. descr

      let object = #{summary: summary, start: #{date: a:day[0:9]}, end: #{date: next_day}, source: 'vimwiki'}
      if !empty(time)
        let object.start = #{dateTime: a:day[0:9].'T'.time}
        if !empty(endtime) 
          let object.end = #{dateTime: a:day[0:9].'T'.endtime}
        else
          const next_hour = strftime('%FT%H:%M', strptime('%FT%H:%M', a:day[0:9].'T'.time) + 60*60)
          let object.end = #{dateTime: next_hour}
        endif
      endif
      return object
    endfunction

    VimwikiIndex
    const cal_cache = expand('~/.cache/calendar.vim/local/event/' . g:vw_calendar_id)
    const today = strftime('%F') . '.md'
    const diary_files = vimwiki#diary#get_diary_files()

    let tasks_mnth = {}
    for file in diary_files
      let day = file->slice(file->strridx('/') + 1)
      if exists('g:vw_calendar_ignore_old_notes') && g:vw_calendar_ignore_old_notes && day < today | continue | endif
      let tasks = readfile(file)->filter({i, v -> v =~ '^\s*\*\s'})->map(function('s:MapTask', [day]))
      let tasks_mnth[day[0:3]..day[5:6]] = tasks_mnth->get(day[0:3]..day[5:6], [])->extend(tasks)
    endfor

    for task_day in tasks_mnth->keys()
      let tasks = tasks_mnth[task_day]
      let path = cal_cache . '/' . task_day[0:3] . '/' . task_day[4:5]
      let items = []
      if filereadable(path . '/0')
        let items = readfile(path . '/0')
              \ ->join("\n")
              \ ->json_decode().items
              \ ->filter(function('s:FilterExistingTasks'))
      endif
      eval items->extend(tasks)

      call mkdir(path, 'p')
      eval [{'items': items}->json_encode()]->writefile(path . '/0')
    endfor
    Calendar -position=here
  endfunction
  command! VWC call VwCalSync()

  function! DiaryDay(day, month, year, wnum) abort
    let link = printf("%04d-%02d-%02d", a:year, a:month, a:day)
    silent call vimwiki#diary#make_note(a:wnum, 0, link)
  endfunction
  autocmd FileType calendar nmap <buffer> <CR> :call DiaryDay(b:calendar.day().get_day(), b:calendar.day().get_month(), b:calendar.day().get_year(), v:count1)<CR>

  command! -nargs=* Cal Calendar -position=here <args>
endif

" story templates
function! IteqGoto(num)
  VimwikiIndex
  exe 'VimwikiGoto' '/hl/ITEQ-'..a:num
  if getline(1) == ''
    call append(0, '# [ITEQ-'..a:num..'](/hl/ITEQ-'..a:num..') - ')
    call append(1, '- jira: https://support.hlag.com/servicedesk/browse/ITEQ-'..a:num)
  endif
endfunction
function! IteqHints(ArgLead, CmdLine, CursorPos)
  return glob(g:vimwiki_list[0].path .. '/hl/ITEQ-*.md', 0, 1)
        \ ->map({i, v -> v->matchlist('.*-\(\d\+\)\.md$')})
        \ ->filter({i, v -> !v->empty()})
        \ ->map({i, v -> v[1]})
        \ ->filter({i, v -> v->match('^'..a:ArgLead) != -1})
endfunction
command! -nargs=1 -complete=customlist,IteqHints ITEQ call IteqGoto(<f-args>)
function! ItcrrGoto(num)
  VimwikiIndex
  exe 'VimwikiGoto' '/hl/ITCRR-'..a:num
  if getline(1) == ''
    call append(0, '# [ITCRR-'..a:num..'](/hl/ITCRR-'..a:num..') - ')
    call append(1, '- jira: https://support.hlag.com/servicedesk/browse/ITCRR-'..a:num)
  endif
endfunction
function! ItcrrHints(ArgLead, CmdLine, CursorPos)
  return glob(g:vimwiki_list[0].path .. '/hl/ITCRR-*.md', 0, 1)
        \ ->map({i, v -> v->matchlist('.*-\(\d\+\)\.md$')})
        \ ->filter({i, v -> !v->empty()})
        \ ->map({i, v -> v[1]})
        \ ->filter({i, v -> v->match('^'..a:ArgLead) != -1})
endfunction
command! -nargs=1 -complete=customlist,ItcrrHints ITCRR call ItcrrGoto(<f-args>)

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
