function cat -d 'cat alias for bat'
    bat --pager=never $argv
end

function ls -d 'ls alias for lsd'
    lsd --group-dirs first $argv
end

function vim -d 'vim alias for nvim'
    nvim $argv
end

function cursor -d 'open Cursor'
    open -a Cursor .
end
