let s:cpoptions_save = &cpoptions
set cpoptions&vim

if !exists('s:color_properties')
  let s:color_properties = [
        \'gui', 'guifg', 'guibg', 'guisp',
        \'cterm', 'ctermfg', 'ctermbg', 'ctermul', 'term'
        \]
  lockvar! s:color_properties
endif

function! colorfulindent#enable() abort
  augroup plugin-colorful-indent
    autocmd!
    autocmd WinEnter * call colorfulindent#colorize()
    autocmd OptionSet shiftwidth call colorfulindent#colorize()
    autocmd ColorScheme * call s:define_highlight_groups()
  augroup END

  if has('vim_starting')
    autocmd plugin-colorful-indent VimEnter * ++once call colorfulindent#colorize()
  else
    call colorfulindent#colorize()
  endif
endfunction

function! colorfulindent#disable() abort
  augroup plugin-colorful-indent
    autocmd!
  augroup END
  for tabID in range(1, tabpagenr('$'))
    for bufnr in tabpagebuflist(tabID)
      let winID = getbufinfo(bufnr)[0].windows[0]
      call win_execute(winID, 'call colorfulindent#uncolorize()')
    endfor
  endfor
endfunction

function! colorfulindent#colorize() abort
  if exists('w:colorfulindent_matchID')
    call colorfulindent#uncolorize()
  else
    let w:colorfulindent_matchID = []
  endif

  let mod = len(s:indent_colors)
  let indent_one = s:get_one_indent_regexp()
  let indent_mod = '^\%(' . indent_one . '\{' . mod . '}\)*'
  for id in range(mod)
    let regex = '\%(' . indent_mod . indent_one . '\{' . id . '}\)\@<=' . indent_one
    " let regex = '\%(' . indent_mod . indent_one . '\{' . id . '}\)\@<=\%(' . indent_one . '\|\S.*$\)'
    let group = 'ColorfulIndent' . id
    let matchID = matchadd(group, regex)
    call add(w:colorfulindent_matchID, matchID)
  endfor
endfunction

function! colorfulindent#uncolorize() abort
  if exists('w:colorfulindent_matchID')
    for id in w:colorfulindent_matchID
      try
        call matchdelete(id)
        " TODO: catch E802, E803
      catch
        echohl Error
        echomsg v:throwpoint
        echomsg v:exception
        echohl NONE
      endtry
    endfor
    let w:colorfulindent_matchID = []
  endif
endfunction

function! colorfulindent#set_indent_colors(colors) abort
  call s:clear_highlight_groups()

  let default_color = {}
  for key in s:color_properties
    let default_color[key] = 'NONE'
  endfor

  let s:indent_colors = []
  for color in a:colors
    call extend(color, default_color, 'keep')
    call add(s:indent_colors, color)
  endfor

  call s:define_highlight_groups()
endfunction

function! s:clear_highlight_groups() abort
  for id in range(len(s:indent_colors))
    execute 'highlight clear ColorfulIndent' . id
  endfor
endfunction

function! s:define_highlight_groups() abort
  let id = 0
  for color in s:indent_colors
    let cmd = 'highlight ColorfulIndent' . id
    for property in s:color_properties
      let cmd .= ' ' . property . '=' . color[property]
    endfor
    execute cmd
    let id += 1
  endfor
endfunction

function! s:get_one_indent_regexp() abort
  return '\%(\t\|' . repeat(' ', shiftwidth()) . '\)'
endfunction

if !exists('s:indent_colors')
  let s:indent_colors = []
  if &background ==# 'dark'
    call colorfulindent#set_indent_colors([
          \ {'guibg': 'black', 'ctermbg': 'black'},
          \ {},
          \])
  else
    call colorfulindent#set_indent_colors([
          \ {'guibg': 'lightgray', 'ctermbg': 'lightgray'},
          \ {},
          \])
  endif
endif


let &cpoptions = s:cpoptions_save
unlet s:cpoptions_save
