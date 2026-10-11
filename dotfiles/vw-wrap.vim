let g:vimwiki_list = [#{
      \ path: '~/notes',
      \ syntax: 'markdown',
      \ ext: 'md',
      \ listsyms: ' x',
      \ diary_rel_path: '',
      \ auto_diary_index: 1,
      \ diary_caption_level: -1}]
let g:vimwiki_folding = 'syntax'
let g:vimwiki_global_ext = 0
let g:vimwiki_conceallevel = 2
if executable('git') && executable('vwsync.sh')
  command! VwSync :TermCmd vwsync.sh
elseif executable('git')
  command! VwSync !cd ~/notes && git add '*' && git commit -a -m edits && git pull -r && git push || git pull -r
endif
if executable('pandoc')
  command! VwPrev !pandoc %:p -o /tmp/md.pdf && xdg-open /tmp/md.pdf
endif

if isdirectory('/c/Windows')
  function! VimwikiLinkHandler(link)
    let browser = 'C:/Program Files/Google/Chrome/Application/chrome.exe'
    if a:link =~ '^https\?://'
      silent! execute '!start "' . browser . '" ' . a:link
      return 1
    else
      return 0
    endif
  endfunction
endif

function! Timestamp()
  let line = getline('.')
  let col = col('.') - 1
  call setline('.', line[:col-1] . strftime('%Y%m%d') . line[col:])
  call cursor(line('.'), col + 8)
endfunction
command! Tst :call Timestamp()

function! s:UpdatePeriodicTasks(lines, date)
  let updated_lines = []
  for item in a:lines
    let mtch = item->matchlist('\(\s*[-*] \[ ] .*\)\s*(repeat: \([^)'']*\))')
    if !empty(mtch)
      let new_date = system('date +%F -d ''' . a:date . ' + ' . mtch[2] . "'")[0:9]
      let diary_name = printf('%s/%s/%s.md',
            \ g:vimwiki_list[v:count1-1].path,
            \ g:vimwiki_list[v:count1-1].diary_rel_path,
            \ new_date)
      eval [item]->writefile(diary_name->expand(), 'a')
      eval updated_lines->add(mtch[1])
    else
      eval updated_lines->add(item)
    endif
  endfor
  return updated_lines
endfunction

function s:MarkTasksMoved(file)
  const TODO_PATTERN = '^\s*[-*] \[ ]\s.*$'
  call readfile(a:file)->map({i, v -> v =~ TODO_PATTERN ? substitute(v, '\[ \]', '[m]', '') : v })->writefile(a:file)
endfunction

function IsANoteFile(data, date)
  const NOTE_PTN = 'wikinote: ' . a:date
  if a:data->get(0, '') == '---'
    for line in a:data->slice(1)
      if line->slice(0, NOTE_PTN->strlen()) == NOTE_PTN
        return 1
      endif
    endfor
  endif
  return 0
endfunction

function VwDailyCopy()
  const TODO_PATTERN = '^\s*\(#\+\s\|[-*] \[ ]\s\|$\)'

  VimwikiMakeDiaryNote
  write

  const date = strftime('%F %V %u %a')
  if IsANoteFile(getline(0, '$'), date[0:9]) | return | endif

  let todos = []
  const diary_files = vimwiki#diary#get_diary_files()->sort()->map({i,v -> v->matchlist('.*/\(\d\d\d\d-\d\d-\d\d\.md\)')[1]})
  const today_idx = diary_files->index(expand('%:t'))
  for day_idx in range(today_idx - 1, 0, -1)
    let diary_file_name = expand(g:vimwiki_list[v:count1-1].path . '/' . g:vimwiki_list[v:count1-1].diary_rel_path 
          \ . '/' . diary_files->get(day_idx))
    let file_lines = readfile(diary_file_name)
    let day_data = file_lines->copy()->filter({i, v -> v =~ TODO_PATTERN})
    let id_date = diary_files[day_idx]->substitute('\(.*/\)\?\(\d\d\d\d-\d\d-\d\d\)\.md', '\2', '')
    call s:UpdatePeriodicTasks(day_data, id_date)

    call s:MarkTasksMoved(diary_file_name)
    eval todos->extend(day_data, 0)

    if IsANoteFile(file_lines, id_date) | break | endif
  endfor

  " process today separately, taking all the lines, not only tasks and headers:
  eval todos->extend(s:UpdatePeriodicTasks(getbufline(bufnr(), 1, '$'), date[0:9]))

  % delete
  call append(0, '---')
  call append(1, 'wikinote: ' . date[0:10].date[16:-1])
  call append(2, '---')
  call append(3, '')
  call append(4, todos)
  while getline(line('$')) =~ '^\s*$' | $ del | endwhile

  silent! %s/\n\s*\n\s*\n/\r\r/
endfunction
command VwDailyCopy call VwDailyCopy()
command! VWD WvDailyCopy

function VwAgenda()
  VimwikiIndex
  VimwikiGoto agenda
  % delete
  const today = strftime('%F') . '.md'
  const diary_files = vimwiki#diary#get_diary_files()->sort()
  for file in diary_files
    let day = file->slice(strridx(file, '/') + 1)
    if day >= today
      let weekday = strftime('%a', strptime('%F', day[0:9]))
      call append('$', '# ['.day[0:9].' '.weekday.']'.'('.day.')')
      call append('$', readfile(file)
            \ ->filter({i, v -> v =~ '^\s*[-*] \(\[ \]\s\)\?'})
            \ ->map({i, v -> v .. ' :link:'})
            \ ->add(''))
    endif
  endfor
  1 delete
  write
endfunction
command! VwAgenda call VwAgenda()
command! VWA VwAgenda

function VwGotoCal()
  const dt = expand('%:t:r')
  if dt !~ '\d\d\d\d-\d\d-\d\d' | return | endif
  exe 'Cal' dt[8:9] dt[5:6] dt[0:3]
endfunction
autocmd filetype vimwiki :nnoremap <buffer> <leader>d :call VwGotoCal()<cr>

function! VwTags()
  VimwikiIndex
  VimwikiGoto tags
  %d
  write

  const wiki_ptn = '\[\[[^\]#]+(#.*)?\]\]'
  const md_ptn = '\[[^\]]+\]\([^\)#]+(#.*)?\)'
  const search_ptn = '('.wiki_ptn.'|'.md_ptn.')'

  call system('rg -Io ' .. glob(g:vimwiki_list[0].path) .. ' -e '''.search_ptn.''''
        \ .. '| sed ''s/:\([^:]+\):/\1/'''
        \ .. '| sed ''s/\(\[\[[^|]*\)|.*/\1]]/'''
        \ .. '| sed ''s/\[\[\(.*\)\]\]/\1/'' | sed ''s/\[.*\](\(.*\))/\1/'' | sed ''s/\.md$//i'''
        \ .. '| grep -vE ''https?://'''
        \ .. '| grep -vE ''^#'''
        \ .. '| grep -vE ''^[[:digit:]][[:digit:]][[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]'''
        \ .. '| sort | uniq'
        \ .. '| sed ''s/\(.*\)/[[\1]]/''')
        \ ->split('\r*\n')->map({i, v -> v .. ' :link:'})->append(0)
endfunction
command! VwTags call VwTags()

function! VwItcrrList()
  lcd $n/hl
  e itcrr-list.md
  %d
  call system('find . -type f -name ''ITCRR-*.md'' | sort | while read f; do head -n 1 "$f" | grep -E ''^# '' | sed -e ''s/..\(.*\)$/\1/''; done')
        \ ->split('\r*\n')->map({i, v -> v..' :link:'})->append(0)
  w
endfunction
command! ITCRRs call VwItcrrList()

if PluginExists('fzf.vim') && executable('rg')
  command! VwRg :lcd ~/notes|RG
  nmap <leader> :VwRg<cr>
endif
if PluginExists('fzf.vim')
  command! VwFiles :lcd ~/notes|Files
  nmap <leader> :VwFiles<cr>
endif

"function! VwFiles()
  "Scratch
  "lcd $n
  "call append(0, 'find . -type f | grep -i ')
  "normal ggA
"endfunction
"nmap <leader> :call VwFiles()<cr>
"nmap <leader> :tabe<cr>:call VwFiles()<cr>

"function! VwSearch()
  "Scratch
  "lcd $n
  "call append(0, "rg -g '**' -g '!.*' --path-separator=// -n . -e ")
  "normal ggA
"endfunction
"nmap <leader> :call VwSearch()<cr>
"nmap <leader> :tabe<cr>:call VwSearch()<cr>

" fancy checkboxes
au filetype vimwiki sy match todoCheckboxOpen '^\s*\(-\|[0-9]\+\.\|\*\) \[ \]' contains=todoCheckboxOpenConceal
au filetype vimwiki sy match todoCheckboxDone '^\s*\(-\|[0-9]\+\.\|\*\) \[[Xx]\]' contains=todoCheckboxDoneConceal
au filetype vimwiki sy match todoCheckboxCancel '^\s*\(-\|[0-9]\+\.\|\*\) \[c\]' contains=todoCheckboxCancelConceal
au filetype vimwiki sy match todoCheckboxMoved '^\s*\(-\|[0-9]\+\.\|\*\) \[m\]' contains=todoCheckboxMovedConceal
au filetype vimwiki hi todoCheckboxOpen ctermfg=red guifg=red
au filetype vimwiki hi todoCheckboxDone ctermfg=green guifg=green
au filetype vimwiki hi todoCheckboxMoved ctermfg=green guifg=darkyellow
au filetype vimwiki hi todoCheckboxCancel ctermfg=darkyellow guifg=darkyellow
au filetype vimwiki sy match todoCheckboxOpenConceal '\[ \]' transparent contained conceal cchar=☐
au filetype vimwiki sy match todoCheckboxMovedConceal '\[m\]' transparent contained conceal cchar=↷
au filetype vimwiki sy match todoCheckboxDoneConceal '\[[xX]\]' transparent contained conceal cchar=☒
au filetype vimwiki sy match todoCheckboxCancelConceal '\[c\]' transparent contained conceal cchar=🗙
au filetype vimwiki hi Conceal ctermfg=lightblue ctermbg=NONE guifg=lightblue guibg=NONE

if executable('rg')
  function! s:RgBacklinks()
    " find backlinks using rg
    const vw_path = g:vimwiki_list[v:count1-1].path->expand()
    exe 'lcd' expand(vw_path)

    " delete previous section if exists
    call cursor(1, 1)
    if search('^# backlinks$') != 0
      normal dah
    endif

    if getline('$') !~ '^\s*$' | call append('$', '') | endif
    call append('$', '# backlinks')
    call cursor('$', 0)

    const filename = expand('%:t')
    const target_ptn = expand('%:t:r') .. '(\.md)?'
    const wiki_ptn = '\[\[([^\]]*/)?'.target_ptn.'(#[^\]]*)?\]\]'
    const md_ptn = '\[.*\]\(([^\]]*/)?'.target_ptn.'(#[^\)]*)?\)'
    const tag_ptn = ':'.target_ptn.':'
    const search_ptn = '('.wiki_ptn.'|'.md_ptn.'|'.tag_ptn.')'
    const cmd = 'rg --path-separator="//" -in -g ''**'' -g ''!.git'' -g ''!.vimwiki_tags'' -g ''!'.filename.''' '''.search_ptn.''' | grep -v :link: | sort'
    let lines = system(cmd)
          \ ->split('\r*\n')
          \ ->map({i, v -> matchlist(v, '\([^:]\+\):\(\d\+\):\(.*\)')})
          \ ->map({i, v -> v[3]..' | ['..v[1]..':'..v[2]..']('..v[1]..') :link:'})
          \ ->filter({i, v -> v !~ '^\s*[-*] \[m\]\s'})
    call append('$', lines->map({i, v -> substitute(v, '^\s*#\+\s\+', '- ', '')}))
  endfunction
  command! VwBl :call <SID>RgBacklinks()
  au filetype vimwiki command! VWB :call <SID>RgBacklinks()

  function! s:RgTodos()
    let cmd = printf('rg -in -g ''**'' -g ''!.git'' -g ''!%s'' ''^\s*[-*] \[ \]\s.*[\[\(:]([\w\d/_\-]*/)?%s(\.md)?[\]\):]'' | sort', expand('%:t'), expand('%:t:r'))
    let lines = system(cmd)->split('\r*\n')->map({i, v -> matchlist(v, '\([^:]\+\):\(\d\+\):\(.*\)')}) ->map({i, v -> v[3]..' | ['..v[1]..':'..v[2]..']('..v[1]..')'})
    call append(line('.'), lines)
  endfunction
  command! VwTodos :call <SID>RgTodos()
endif

function s:VwUpd()
  VwSync
  VWC
  VwD
endfunction
command! VwUpdate :call <SID>VwUpd()

