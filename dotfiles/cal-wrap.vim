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
