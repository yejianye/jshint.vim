if exists("b:did_jshint_plugin")
    finish
else
    let b:did_jshint_plugin = 1
endif

if has("win32")
	let s:install_dir = '"' . expand("~/vimfiles/ftplugin/javascript") . '"'
else
	let s:install_dir = expand("<sfile>:p:h")
endif

nmap <buffer> <leader>li :JSHintUpdate<CR>

if !exists(":JSHintUpdate")
    command JSHintUpdate :call s:JSHint()
endif

" Set up command and parameters
if has("win32")
  let s:cmd = 'cscript /NoLogo '
  let s:runjshint_ext = 'wsf'
else
  let s:runjshint_ext = 'js'
  if exists("$JS_CMD")
    let s:cmd = "$JS_CMD"
  elseif executable('/System/Library/Frameworks/JavaScriptCore.framework/Resources/jsc')
    let s:cmd = '/System/Library/Frameworks/JavaScriptCore.framework/Resources/jsc'
  elseif executable('node')
    let s:cmd = 'node'
  elseif executable('js')
    let s:cmd = 'js'
  elseif executable('d8')
	let s:cmd = 'd8'
  else
    echoerr('No JS interpreter found. Checked for jsc, js (spidermonkey), and node')
  endif
endif
let s:plugin_path = s:install_dir . "/jshint/"
let s:cmd = "cd " . s:plugin_path . " && " . s:cmd . " " . s:plugin_path . "runjshint." . s:runjshint_ext

let s:jshintrc_file = expand('~/.jshintrc')
if filereadable(s:jshintrc_file)
  let s:jshintrc = readfile(s:jshintrc_file)
else
  let s:jshintrc = []
end

function! s:JSHint()
  let b:matched = []

  " Detect range
  if a:firstline == a:lastline
    let b:firstline = 1
    let b:lastline = '$'
  else 
    let b:firstline = a:firstline
    let b:lastline = a:lastline
  endif

  let b:jshint_output = system(s:cmd, join(s:jshintrc + getline(b:firstline, b:lastline), "\n") . "\n")
  if v:shell_error
     echoerr 'could not invoke JSHint!'
  end

  let curBuffer = bufnr('%')
  for error in split(b:jshint_output, "\n")
    " Match {line}:{char}:{message}
    let b:parts = matchlist(error, "\\(\\d\\+\\):\\(\\d\\+\\):\\(.*\\)")
    if !empty(b:parts)
      let l:line = b:parts[1] + (b:firstline - 1 - len(s:jshintrc)) " Get line relative to selection

        " Store the error for an error under the cursor
      let s:matchDict = {'type' : 'E', 'bufnr': curBuffer}
      let s:matchDict['lnum'] = l:line
	  let s:matchDict['col'] = b:parts[2]
      let s:matchDict['text'] = b:parts[3]
      " Add line to match list
      call add(b:matched, s:matchDict)
    endif
  endfor
  call setqflist(b:matched, 'r')
  botright cwindow
endfunction
