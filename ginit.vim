" Clipboard support
call GuiClipboard()
" Visual settings
GuiTabline 0
GuiPopupmenu 0
GuiFont! Consolas:h10

" Maximize on start
call rpcnotify(0, 'Gui', 'WindowMaximized', 1)
execute "cd ".expand("$HOME")
