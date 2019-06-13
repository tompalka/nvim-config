" Prerequisites:
" 1. basic unix tools are available in terminal (git-bash installed and
" configured)
" 2. vim-plug is installed:
"     curl -fLo ~\AppData\Local\nvim\autoload\plug.vim --create-dirs
"       \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" 3. Python2 & Python3 are installed with pip, virtualenv and pynvim
"     python -m pip install virtualenv
"     python -m virtualenv -p <python2path> ~\AppData\Local\nvim\pyenv\py2nvim
"     python -m virtualenv -p <python3path> ~\AppData\Local\nvim\pyenv\py3nvim
"     pyenv\py2nvim\Scripts\activate.bat
"     pip install pynvim
"     pyenv\py3nvim\Scripts\activate.bat
"     pip install pynvim
"     checkhealth
let s:vim_home = fnamemodify($MYVIMRC, ":h")

let mapleader = " "
let maplocalleader = " "
filetype plugin indent on

" Setup python {{{
let s:pyenv_directory = expand(s:vim_home.'/'.'pyenv')
let g:python_host_prog = expand(s:pyenv_directory.'/'.'py2nvim/Scripts/python.exe')
let g:python3_host_prog = expand(s:pyenv_directory.'/'.'py3nvim/Scripts/python.exe')
" }}}

" Plugins {{{
call plug#begin()
  " Helpers {{{
    function! s:get_latest_version(repo)
      return trim(system('curl --silent https://api.github.com/repos/'.
        \ a:repo.'/releases/latest | grep -Po ''\"tag_name\": \"\K.*?(?=\")'''))
    endfunction
    function! s:download_binary(repo, prefix, suffix, dest_dir, post_action)
      let l:latest_version = s:get_latest_version(a:repo)
      let l:download_script = 'curl -fLo '.expand(a:dest_dir).
        \ ' https://github.com/'.a:repo.'/releases/download/'.l:latest_version.
        \ '/'.a:prefix.l:latest_version.a:suffix
      if !empty(a:post_action)
        let l:download_script .= ' && '.a:post_action
      endif
      return l:download_script
    endfunction
  " }}}

  " General {{{
    Plug 'tpope/vim-surround'

    Plug 'sheerun/vim-polyglot'

    Plug 'jiangmiao/auto-pairs' " {{{
    augroup disable_autopairs_in_vim_ft
      autocmd!
      autocmd FileType vim let b:autopairs_enabled = 0
    augroup end
    " }}}

    Plug 'junegunn/vim-easy-align' " {{{
    nmap <leader>= <Plug>(EasyAlign)
    vmap <leader>= <Plug>(EasyAlign)
    " }}}

    Plug 'justinmk/vim-sneak' " {{{
    let g:sneak#label = 1
    " }}}

    Plug 'tpope/vim-unimpaired' " {{{
    augroup override_unimpaired_mappings
      autocmd!
      autocmd VimEnter * nnoremap <silent> [t :tabprevious<cr>
      autocmd VimEnter * nnoremap <silent> ]t :tabnext<cr>
      autocmd VimEnter * nnoremap <silent> [T :tabfirst<cr>
      autocmd VimEnter * nnoremap <silent> ]T :tablast<cr>
    augroup end
    " }}}

    Plug 'tpope/vim-commentary'
   
    Plug 'tpope/vim-vinegar'
  " }}}

  " Sessions {{{
    Plug 'xolox/vim-misc'
    Plug 'xolox/vim-session'
    let g:session_command_aliases = 1
    let g:session_directory = expand(s:vim_home.'/'.'sessions')
    set sessionoptions+=resize
    let g:session_autoload = "no"
    let g:session_autosave = "yes"
    let g:session_default_to_last = 1
  " }}}

  " Fuzzy finder {{{
    Plug 'junegunn/fzf', {
      \ 'do': <SNR>1_download_binary('junegunn/fzf-bin', 'fzf-', '-windows_amd64.zip',
      \   'bin/fzf.zip', 'unzip bin/fzf.zip -d bin')
    \ }
    let g:fzf_layout = {'window': 'botright 12 split enew'}

    Plug 'junegunn/fzf.vim'
    function! s:search_git_files_first(failover_command)
      let l:git_dir = <SNR>1_get_git_root_dir()
      if !empty(l:git_dir)
        execute "GitFiles"
      else
        execute a:failover_command
      endif
    endfunction
    function! s:fzf_git_branches()
      let l:dict = {'source': 'git branch -a'}
      function! l:dict.sink(files)
        " Current branch is marked with '*'
        if a:lines !~ '\v^\s*\*'
          let l:remote_branch_pattern = '\v^\s*remotes/[^/]*/\zs.*\ze$'
          if a:lines =~# l:remote_branch_pattern
            let l:branch_name = matchstr(a:lines, l:remote_branch_pattern)
          else
            let l:branch_name = a:lines
          endif
          execute "!git checkout ".l:branch_name
        endif
      endfunction
      call fzf#run(fzf#wrap(l:dict))
    endfunction
    nnoremap <silent> <c-p>f :call <SNR>1_search_git_files_first("Files")<cr>
    nnoremap <silent> <c-p>b :Buffers<cr>
    command! -nargs=0 Branches call <SNR>1_fzf_git_branches()
    nnoremap <silent> <c-p>gb :Branches<cr>
  " }}}

  " Git support {{{
    Plug 'tpope/vim-fugitive' " {{{
    function! s:is_fugitive_buffer()
      return expand("%:p") =~# '\v^fugitive:[\\/]{2}'
    endfunction
    function! s:get_git_root_dir()
      let l:git_dir = fugitive#extract_git_dir(getcwd())
      if !empty(l:git_dir)
        let l:git_dir = fnamemodify(l:git_dir, ":h")
      endif
      return expand(l:git_dir)
    endfunction
    augroup fugitive_status_auto_refresh
      autocmd!
      autocmd BufEnter index if &filetype ==# 'fugitive' | execute "normal R" | endif
    augroup end
    " }}}

    Plug 'airblade/vim-gitgutter' " {{{
    set updatetime=100
    set signcolumn=yes
    " }}}
  " }}}

  " Snippets {{{
    Plug 'sirver/ultisnips'
    let g:UltiSnipsJumpForwardTrigger = "<tab>"
    let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
    let g:UltiSnipsRemoveSelectModeMappings = 0
  " }}}

  " Terminal {{{
    Plug 'kassio/neoterm'
    let g:neoterm_default_mod = 'botright'
    let g:neoterm_autoscroll = 1
    let g:neoterm_term_per_tab = 1
    let s:crlf = "\u000d\u0020"
    function! s:terminal_start(mods)
      " Start in git root dir or current file's directory or current working
      " directory
      let l:working_dir = ''
      if empty(l:working_dir)
        let l:working_dir = <SNR>1_get_project_root()
      endif
      if empty(l:working_dir)
        let l:working_dir = <SNR>1_get_git_root_dir()
      endif
      if empty(l:working_dir)
        let l:working_dir = expand("%:p:h")
      endif
      if empty(l:working_dir) " should never happen
        let l:working_dir = expand(getcwd())
      endif
      call neoterm#new({'mod': a:mods})
      call neoterm#do({'cmd': 'cd /d '.l:working_dir.s:crlf, 'target': 0})
      " Python's virtualenv activation
      let l:virtualenv_name = <SNR>1_get_venv_name()
      if !empty(l:virtualenv_name)
        let l:venv_activation_script = expand(<SNR>1_get_venv_directory().'/Scripts/activate.bat')
        call neoterm#do({'cmd': l:venv_activation_script.s:crlf, 'target': 0, 'mod': ''})
      endif
    endfunction
    augroup override_neoterm_commands
      autocmd!
      autocmd VimEnter * command! -bar Tnew call <SNR>1_terminal_start(<q-mods>)
      autocmd VimEnter * command! -range=0 -complete=shellcmd -nargs=+ T call neoterm#do({
        \ 'cmd': <q-args>.s:crlf, 'target': <count>, 'mod': <q-mods> })
    augroup end
    function! s:is_terminal_buffer(bufnr)
      if a:bufnr == 0
        let l:bufname = expand("%:p")
      else
        let l:bufname = bufname(a:bufnr)
      endif
      return l:bufname =~# '\v^term:'
    endfunction
  " }}}

  " Programming support {{{
    " LSP support {{{
    Plug 'autozimu/LanguageClient-neovim', {
      \ 'branch': 'next',
      \ 'do': <SNR>1_download_binary('autozimu/LanguageClient-neovim',
      \   'languageclient-', '-x86_64-pc-windows-gnu.exe', 'bin/languageclient.exe', '')
    \ }
    set hidden
    " scala, java
    let g:LanguageClient_serverCommands = {
      \ 'python': ['python', '-m', 'pyls'],
    \ }
    let g:LanguageClient_autoStart = 1
    augroup languageclient_mappings
      let s:lc_file_types = join(keys(g:LanguageClient_serverCommands), ',')
      autocmd!
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lm  :call LanguageClient_contextMenu()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lh  :call LanguageClient#textDocument_hover()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lgd :call LanguageClient#textDocument_definition()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lgt :call LanguageClient#textDocument_typeDefinition()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lgi :call LanguageClient#textDocument_implementation()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lr  :call LanguageClient#textDocument_rename()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>ls  :call LanguageClient#textDocument_documentSymbol()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lS  :call LanguageClient#workspaceSymbol()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lu  :call LanguageClient#textDocument_references()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>la  :call LanguageClient#textDocument_codeAction()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lf  :call LanguageClient#textDocument_formatting()<cr>"
      execute "autocmd FileType ".s:lc_file_types." vnoremap <buffer> <localleader>lf  :call LanguageClient#textDocument_rangeFormatting()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lv  :call LanguageClient#textDocument_documentHighlight()<cr>"
      execute "autocmd FileType ".s:lc_file_types." nnoremap <buffer> <localleader>lV  :call LanguageClient#clearDocumentHighlight()<cr>"
    augroup end
    " }}}
    " Completion & snippets support {{{
    Plug 'ncm2/ncm2'
    augroup ncm2_enable_for_all_buffers
      autocmd!
      autocmd BufEnter * call ncm2#enable_for_buffer()
    augroup end
    Plug 'roxma/nvim-yarp'
    Plug 'ncm2/ncm2-ultisnips'
    " IMPORTANT: :help Ncm2PopupOpen for more information
    set completeopt=noinsert,menuone,noselect
    inoremap <silent> <buffer> <expr> <tab> (pumvisible() ? ncm2_ultisnips#expand_or("\<tab>", 'n') : "\<tab>")
    set shortmess+=c
    " }}}
    " Project structure support {{{
    Plug 'tpope/vim-projectionist'
    function! s:projectionist_init() abort " Experimental {{{
      for [root, init_script] in projectionist#query('init')
        silent! execute init_script
        break
      endfor
    endfunction
    augroup projectionist_init
      autocmd!
      autocmd User ProjectionistActivate call s:projectionist_init()
    augroup end
    " }}}
    function! s:get_project_root()
      return projectionist#path()
    endfunction
    " }}}
    " Python virtualenv support {{{
    Plug 'jmcantrell/vim-virtualenv'
    let g:virtualenv_directory = expand("$HOME/venvs")
    function! s:get_venv_name()
      return VirtualEnvStatusline()
    endfunction
    function! s:get_venv_directory()
      return expand(g:virtualenv_directory.'/'.s:get_venv_name())
    endfunction
    function! s:get_python() " not used
      if empty(s:get_venv_name())
        return 'python'
      endif
      return expand(s:get_venv_directory().'/Scripts/python')
    endfunction
    augroup update_pyls_python_executable
      autocmd!
      autocmd CmdlineLeave : if getcmdline() =~# 'VirtualEnvActivate' && !v:event.abort |
        \ execute(getcmdline()) |
        \ let g:LanguageClient_serverCommands['python'][0] = expand(s:get_venv_directory().'/Scripts/python') |
        \ let v:event.abort = 1 |
        \ endif
      autocmd CmdlineLeave : if getcmdline() =~# 'VirtualEnvDeactivate' && !v:event.abort |
        \ execute(getcmdline()) |
        \ let g:LanguageClient_serverCommands['python'][0] = 'python' |
        \ let v:event.abort = 1 |
        \ endif
    augroup end
    " }}}
    " Tests running {{{
    Plug 'janko-m/vim-test'
    let g:test#strategy = 'neoterm'
    " }}}
  " }}}

  " Theme & visual {{{
    Plug 'rakr/vim-one' " {{{
    let g:one_allow_italics = 1
    " }}}

    Plug 'itchyny/lightline.vim' " {{{
    set noshowmode
    let g:lightline = {} " {{{
    let g:lightline = {
      \ 'colorscheme': 'one',
      \ 'active': {
      \   'left': [['mode'],
      \            ['branch'],
      \            ['trunc', 'filename_info']],
      \   'right': [['session', 'location'],
      \             [],
      \             ['venv', 'file_info']],
      \ },
      \ 'inactive': {
      \   'left': [['branch', 'filename_info'],
      \            []],
      \   'right': [['session'],
      \             []],
      \ },
      \ 'tab': {
      \   'active': ['tabinfo', 'tabfile', 'modified'],
      \   'inactive': ['tabinfo', 'tabfile', 'modified']
      \ },
      \ 'component': {
      \   'trunc': '%<',
      \ },
      \ 'component_visible_condition': {
      \   'trunc': 0,
      \ },
      \ 'component_type': {
      \   'trunc': 'raw',
      \ },
      \ 'component_function': {
      \   'branch': '<SNR>1_statusline_branch',
      \   'filename_info': '<SNR>1_statusline_filename_info',
      \   'session': '<SNR>1_statusline_session',
      \   'file_info': '<SNR>1_statusline_file_info',
      \   'location': '<SNR>1_statusline_location',
      \   'venv': '<SNR>1_statusline_venv_name',
      \ },
      \ 'tab_component_function': {
      \   'tabinfo': '<SNR>1_tabline_tabinfo',
      \   'tabfile': '<SNR>1_tabline_tabfile',
      \ },
    \ } " }}}
    function! s:statusline_branch() " {{{
      let l:branch_name = fugitive#head(8)
      if !empty(l:branch_name)
        let l:branch_name = pathshorten(l:branch_name)
        if len(l:branch_name) > 15
          let l:branch_name = l:branch_name[:13]."\u2026"
        endif
        return "\u16a0 ".l:branch_name
      endif
      return ''
    endfunction " }}}
    function! s:statusline_filename_info() " {{{
      " Special handling of terminal buffer
      if s:is_terminal_buffer(0)
        let l:term_name = matchstr(split(expand("%:p"), '')[0], '\v\/\zs[^/]*$')
        return 'term:'.l:term_name
      endif
      " Special handling of Plugins and help buffers
      if index(['vim-plug', 'help'], &filetype) >= 0
        return expand("%:t")
      endif
      " Special handling of fugitive (diff) buffers
      if s:is_fugitive_buffer()
        let l:git_buf_type = matchstr(expand("%:p"), '\v\.git[\\/]{2}\zs\c[0-9a-f]+\ze[\\/]')
        if l:git_buf_type ==# '0'
          let l:type = 'index'
        elseif l:git_buf_type ==# '2'
          let l:type = 'current''
        elseif l:git_buf_type ==# '3'
          let l:type = 'incoming'
        else
          let l:type = '('.l:git_buf_type[:7].')'
        endif
        return expand("%:t").'@'.l:type
      endif
      let l:short_dir = pathshorten(expand("%:p:h"))
      let l:filename = expand("%:t")
      if empty(l:filename)
        return '[No Name]'
      endif
      let l:filepath = expand(l:short_dir.'/'.l:filename)
      let l:mod_flag = !&modifiable ? '[-]' :
        \ &modified ? '[+]' : ''
      let l:ro_flag = &readonly ? '[RO]' : ''
      return l:filepath.l:ro_flag.l:mod_flag
    endfunction " }}}
    function! s:statusline_session() " {{{
      let l:session_name = xolox#session#find_current_session()
      if empty(l:session_name)
        return '$[]'
      else
        return '$['.l:session_name.']'
      endif
    endfunction " }}}
    function! s:statusline_venv_name() " {{{
      let l:venv = s:get_venv_name()
      if !empty(l:venv)
        return '<'.l:venv.'>'
      endif
      return ''
    endfunction " }}}
    function! s:statusline_file_info() " {{{
      let l:filetype = '['.&filetype.']'
      if &filetype ==# 'help'
        return l:filetype
      endif
      if s:is_terminal_buffer(0)
        return ''
      endif
      if winwidth(0) < 100
        return ''
      endif
      let l:fileformat = &fileformat ==? 'dos' ? 'CRLF' : 'LF'
      let l:fileencoding = &fileencoding
      return l:filetype.l:fileformat.'/'.l:fileencoding
    endfunction " }}}
    function! s:statusline_location() " {{{
      if winwidth(0) < 75
        return ''
      endif
      let l:line = line('.')
      let l:column = col('.')
      let l:percentage = float2nr(round(100.0*l:line/line('$')))
      return printf('%4d:%03d|%3d%%', l:line, l:column, l:percentage)
    endfunction " }}}
    function! s:tabline_tabinfo(tabnum) " {{{
      return '['.a:tabnum.']('.tabpagewinnr(a:tabnum, '$').')'
    endfunction " }}}
    function! s:tabline_tabfile(tabnum) " {{{
      let l:winnr = tabpagewinnr(a:tabnum)
      let l:bufnr = tabpagebuflist(a:tabnum)[l:winnr-1]
      if s:is_terminal_buffer(l:bufnr)
        let l:term_name = matchstr(split(bufname(l:bufnr), '')[0], '\v\/\zs[^/]*$')
        return 'term:'.l:term_name
      endif
      let l:filename = fnamemodify(bufname(l:bufnr), ":t")
      if empty(l:filename)
        return '[No Name]'
      endif
      return l:filename
    endfunction " }}}
    " }}}
  " }}}
call plug#end()
" }}}

" Settings {{{
  " Visual {{{
    set number relativenumber numberwidth=5 signcolumn=yes
    set list
    let &listchars = "tab:\u00bb\ ,trail:\u2423"
    set nowrap sidescroll=35
    let &listchars .= ",precedes:\u27ea,extends:\u27eb"

    augroup colorcolumn_in_active_window
      autocmd!
      autocmd BufNewFile,BufRead,BufWinEnter,WinEnter * let &l:colorcolumn = "80,".join(range(120, 999), ',')
      autocmd WinLeave * let &l:colorcolumn = join(range(1, 999), ',')
    augroup end
    augroup cursorline_in_active_window
      autocmd!
      autocmd BufNewFile,BufRead,BufWinEnter,WinEnter * if !&diff | setlocal cursorline | else | setlocal nocursorline | endif
      autocmd WinLeave * setlocal nocursorline
      autocmd VimEnter * setlocal cursorline
    augroup end
    " Handle cursorline in diff windows
    function! s:disable_cursorline_in_diff(new_option_value)
      if a:new_option_value
        setlocal nocursorline
      else
        setlocal cursorline
      endif
    endfunction
    augroup cursorline_in_diff_windows
      autocmd!
      autocmd OptionSet diff call <SNR>1_disable_cursorline_in_diff(v:option_new)
    augroup end

    set scrolloff=2
  " }}}

  " Theme {{{
    syntax on
    set background=light
    colorscheme one
    let s:fold_guifg = matchstr(execute("highlight FoldColumn"), '\v<guifg\=\#\c[0-9a-f]{6}>')
    let s:fold_guibg = matchstr(execute("highlight FoldColumn"), '\v<guibg\=\#\c[0-9a-f]{6}>')
    execute "highlight Folded ".s:fold_guifg.' '.s:fold_guibg
  " }}}

  " Formatting {{{
    set expandtab softtabstop=4 tabstop=4 shiftwidth=4 shiftround
    set autoindent smartindent
    augroup format_whitespaces
      autocmd!
      autocmd BufWrite * retab
      autocmd BufWrite * %s/\v\s+$//e
    augroup end
  " }}}

  " Searching {{{
    set ignorecase smartcase
    set nohlsearch incsearch
    augroup highlight_searches
      autocmd!
      autocmd CmdLineEnter /,\? set hlsearch
      autocmd CmdLineLeave /,\? set nohlsearch
    augroup end
    vnoremap g/ y/<c-r>"<cr>
  " }}}

  " Moving around {{{
    nnoremap <a-h> <c-w>h
    nnoremap <a-j> <c-w>j
    nnoremap <a-k> <c-w>k
    nnoremap <a-l> <c-w>l
    inoremap <a-h> <c-\><c-n><c-w>h
    inoremap <a-j> <c-\><c-n><c-w>j
    inoremap <a-k> <c-\><c-n><c-w>k
    inoremap <a-l> <c-\><c-n><c-w>l
    tnoremap <c-w> <c-\><c-n>
    tnoremap <a-h> <c-\><c-n><c-w>h
    tnoremap <a-j> <c-\><c-n><c-w>j
    tnoremap <a-k> <c-\><c-n><c-w>k
    tnoremap <a-l> <c-\><c-n><c-w>l
    noremap H ^
    noremap L $

    inoremap <c-j> <c-n>
    inoremap <c-k> <c-p>
  " }}}

  " Yanking/pasting {{{
    nnoremap gy "+y
    nnoremap gY "+Y
    nnoremap gp "+p
    nnoremap gP "+P
    nnoremap gop o<esc>"+p
    nnoremap goP o<esc>"+P
    nnoremap gOp O<esc>"+p
    nnoremap gOP O<esc>"+P
    inoremap <c-v> <esc>"+gpa
    inoremap <c-g><c-v> <c-v>
    vnoremap <c-v> "+p
  " }}}
" }}}
" vim: foldmethod=marker
