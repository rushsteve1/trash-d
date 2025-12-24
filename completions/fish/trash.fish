# trash-d completions for fish

## if coreutils are installed, this version can be used instead
# function __fish_complete_trash_contents
#     # convenience: sort by recency & use path as hint
#     set -f contents (trash --list | tail -n+2 | sort -r -t\t -k3)
#     printf '%s\n' $contents | cut -f1-2 | string replace -r '\s+\t' '\t' | path dirname
# end

function __fish_complete_trash_contents
    set -f data_home $XDG_DATA_HOME
    test -z $data_home; and set -f data_home "$HOME/.local/share"
    set -f data_home $data_home/Trash/files/
    __fish_complete_path $data_home | string replace $data_home ""
end

complete -c trash -l dir           -s d  -d "Remove empty directories."
complete -c trash -l recursive     -s r  -d "Delete directories and their contents."
complete -c trash -l verbose       -s v  -d "Print more information."
complete -c trash -l interactive   -s i  -d "Ask before each deletion."
complete -c trash -l interact-once -s I  -d "Ask once if deleting 3 or more, or deleting recursively"
complete -c trash -l force         -s f  -d "Don't prompt and ignore errors."
complete -c trash -l version             -d "Output the version and exit."
complete -c trash -l list                -d "List out the files in the trash."
complete -c trash -l orphans             -d "List orphaned files in the trash."
complete -c trash -l delete              -d "Delete a file from the trash." -x -k -a '(__fish_complete_trash_contents)'
complete -c trash -l restore             -d "Restore a file from the trash." -x -k -a '(__fish_complete_trash_contents)'
complete -c trash -l empty               -d "Empty the trash bin."
complete -c trash -l rm                  -d "Escape hatch to permanently delete a file."
complete -c trash -l help          -s h  -d "This help information."

