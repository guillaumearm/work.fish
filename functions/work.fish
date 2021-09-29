#!/usr/bin/env fish

set -l WORK_VERSION "0.6.2"
set -l CMD_NAME "work"
set -l WORK_CONFIG_DIR "$HOME/.config/work"
set -l WORK_LIST "$WORK_CONFIG_DIR/worklist"

alias _normal "set_color normal"
alias _yellow "set_color yellow"
alias _red "set_color red"
alias _blue "set_color blue"
alias _purple "set_color purple"
alias _green "set_color green"

set -l normal (normal)
set -l yellow (yellow)
set -l red (red)
set -l blue (blue)
set -l purple (purple)
set -l green (green)

### UTILS ###
function _prepare_worklist -V WORK_CONFIG_DIR -V WORK_LIST
  mkdir -p $WORK_CONFIG_DIR
  touch $WORK_LIST
end

### HELP AND USAGE ###

set -l list_usage "list" "[--raw/-r]" "			" "List all available workspaces"
set -l go_usage "go" "<workspace>" "			" "Change directory to a given workspace"
set -l create_usage "create" "[--force/-f] <dir> [name]" "	" "Create a workspace with the given directory"
set -l remove_usage "remove" "<workspace> [others...]" "	" "Remove a workspace"
set -l help_usage "help" "[command]" "			" "Print help page about a command"
set -l version_usage "version" "" "				" "Print the client version"

function _print_cmd_name -V CMD_NAME
  _red
  echo -en $CMD_NAME
  _normal
end

function _print_description
  _print_cmd_name
  echo ": a simple tool that help you to change current directory"
end

function _print_command
  _yellow
    echo -en "  $argv[1] "
  _normal
  _blue
    echo -en "$argv[2]"
  _normal
  echo "$argv[3]$argv[4]"
end

function _print_alias
  _yellow
    echo -en "  $argv[5]"
    echo "$argv[6]$argv[1]"
  _normal
end

function _print_error
  _red
  echo "work error: $argv"
  _normal
end

function _print_help
  _print_description
  echo ""
  _print_all_help_commands
  echo ""
  echo "Usage:"
  echo -en "  " ; _print_cmd_name ;
  _yellow ; echo -en " <command> " ; _normal
  _blue; echo "[options]"; _normal
  echo ""
  echo -en "Use \""
  _print_cmd_name
  _yellow; echo -en " <command>"; _normal
  _blue ; echo -en " --help" ; _normal
  echo -en '" '
  echo "for more information  about a given command."
end

function _print_help_command
  echo -en "Usage: "
  _print_cmd_name
  _yellow
    echo -en " $argv[5] "
  _normal
  _blue
    echo -en "$argv[2]"
  _normal
  echo ""
  echo "  $argv[4]"
end

function _print_all_help_commands -V list_usage -V go_usage -V create_usage -V remove_usage -V help_usage -V version_usage
  echo "Commands:"
  _print_command $go_usage
  _print_command $create_usage
  _print_command $remove_usage
  _print_command $list_usage
  _print_command $help_usage
  _print_command $version_usage
  echo
  echo "Aliases:"
  _print_alias $create_usage add "					"
  _print_alias $remove_usage rm "					"
  _print_alias $list_usage ls "					"
end

function _print_special_help -V CMD_NAME -V normal -V blue -V purple -V list_usage -V go_usage -V create_usage -V remove_usage -V help_usage -V version_usage
  set cmd_name "$argv[1]"

  # TODO: use printf %-30s instead of tabs (for better columns alignment)

  if test "$cmd_name" = "list"; or test "$cmd_name" = "ls"
    _print_help_command $list_usage $cmd_name
    echo
    echo "Options:"
    echo "  $blue-r$normal, $blue--raw$normal			Print the raw list (no format, no color)"
  else if test "$cmd_name" = "go"
    _print_help_command $go_usage $cmd_name
    echo
    echo "Options:"
    echo "  $blue-i$normal, $blue--interactive$normal		Interactive mode (use fzf)"
    echo
    echo "Tips:"
    echo "  - try 'work ls' to get available workspaces"
    echo "  - try 'work create .' to create a workspace with the current working directory"
  else if test "$cmd_name" = "create"; or test "$cmd_name" = "add"
    _print_help_command $create_usage $cmd_name
    echo
    echo 'Parameters:'
    echo "  $blue<dir>$normal				Workspace directory path"
    echo " $blue [name]$normal			Workspace name"
    echo
    echo "Options:"
    echo "  $blue-f$normal, $blue--force$normal			Force workspace path replacement"
    echo
    echo "Examples:"
    echo "  $purple$CMD_NAME $cmd_name . $normal   		Create a workspace using the current directory (the directory name is used as default workspace name)"
    echo "  $purple$CMD_NAME $cmd_name ~ mywork $normal		Create a workspace named \"mywork\" which point to the home directory"
    echo "  $purple$CMD_NAME $cmd_name -f . mywork $normal 	Replace the workspace \"mywork\" path by the current directory"
  else if test "$cmd_name" = "remove"; or test "$cmd_name" = "rm"
    _print_help_command $remove_usage $cmd_name
    echo
    echo 'Parameters:'
    echo "  $blue<workspace>$normal					Workspace name to remove"
    echo " $blue [others...]$normal					Other workspaces to remove"
    echo
    echo "Examples:"
    echo "  $purple$CMD_NAME $cmd_name mywork $normal				Remove the \"mywork\" workspace"
    echo "  $purple$CMD_NAME $cmd_name mywork1 mywork2 test $normal	 	Remove \"mywork1\", \"mywork2\" and \"test\" workspaces"
  else if test "$cmd_name" = "help"
    _print_help_command $help_usage $cmd_name
  else if test "$cmd_name" = "version"
    _print_help_command $version_usage $cmd_name
  else
    _print_error "help not found for \"$cmd_name\" command."
  end
end


######### COMMANDS #############
function _ws_name
  echo (string split ':' $argv)[1]
end

function _ws_path
  echo (string split ':' $argv)[2]
end

function  _exec_version -V WORK_VERSION 
  _print_description
  echo "  work version: $WORK_VERSION"
  echo "  fish version: $FISH_VERSION"
end

function _exec_list -a raw_flag -V WORK_LIST
  _prepare_worklist

  if test -n "$raw_flag"
    cat $WORK_LIST
    return 0
  end

  printf "%-30s%s\n" "NAME" "PATH"

  set worklist (cat $WORK_LIST)
  for elem in (cat $WORK_LIST)
    _blue
      printf "%-30s" (_ws_name $elem)
    _purple
      printf "%s\n" (_ws_path $elem)
    _normal
  end
end


function _exec_go_interactive -V WORK_LIST
  for e in (cat $WORK_LIST)
    # TODO: check fzf presence at start (display a warning if not)
    printf "%-30s:%s\n" (_ws_name $e) (_ws_path $e)
  end | fzf
end

function _exec_go -V WORK_LIST
  if test "$argv[1]" = "-"; or test "$argv[2]" = "-"
     cd -
     return
  end

  set target "$argv[1]"

  ### check for interactive mode
  if test -z "$target"; and test -n "$argv[3]" 
    set target (_ws_name (_exec_go_interactive) | xargs)

    test -z "$target"; and return 130 # here we assume it's a ctrl+C
  end

  if test -z "$target"
    _print_special_help go; return $status
  end


  for elem in (cat $WORK_LIST)
    set workspace_to_go (_ws_name $elem)

    if test "$target" = "$workspace_to_go"
      set path_to_go (_ws_path $elem)
      break
    end
  end

  if test -n "$path_to_go"
    # GO TO workspace
    set cd_result (cd "$path_to_go" 2>&1)
    # in case of cd error
    if test -n "$cd_result"
      _print_error "$cd_result"
      return 2
    end
    # noop
    # because 'cd' was correctly executed at this point
  else
    _print_error "Unknown workspace \"$target\""
    return 2
  end
end

function _exist_workspace -a name -V WORK_LIST
  for elem in (cat $WORK_LIST)
    if test "$name" = (_ws_name $elem)
      return 0
    end
  end
  return 1
end

function _exec_create -a path -a name -a force_flag -a cmd -V WORK_LIST
  test -z "$path"; and _print_special_help $cmd; and return $status

  set path (realpath $path)
  test -z "$name"; and set name (basename $path)

  ### workspace exist
  if test -z "$force_flag"; and _exist_workspace $name
    _print_error "Workspace \"$name\" already exist"
    return 1
  end

  ### check if path is a valid directory
  not test -e "$path";
  and _print_error "directory does not exist: \"$path\""; and return $status

  not test -d "$path";
  and _print_error "not a directory: \"$path\""; and return $status

  ### get workspaces
  set --erase workspaces
  for elem in (cat $WORK_LIST)
    if test (_ws_name $elem) != "$name"
      set workspaces $workspaces $elem
    end
  end
  set workspaces $workspaces "$name:$path"

  ### write workspaces
  _prepare_worklist
  string join \n $workspaces > $WORK_LIST
  _green ; echo "> created \"$name\"" workspace ; _normal
end

function _exec_remove -a cmd
  set argv $argv[2..-1]
  test -z "$argv[1]"; and _print_special_help $cmd; and return $status

  for arg in $argv
    _exec_simple_remove $arg
  end
end

function _exec_simple_remove -a name -V WORK_LIST
  if not _exist_workspace $name
    _print_error "Workspace \"$name\" does not exist"
    return 1
  end

  ### get filtered workspaces
  set --erase workspaces
  for elem in (cat $WORK_LIST)
    if test (_ws_name $elem) != "$name"
      set workspaces $workspaces $elem
    end
  end
   
  ### write workspaces
  _prepare_worklist
  string join \n $workspaces > $WORK_LIST

  _yellow ; echo "- removed \"$name\"" workspace ; _normal
end

######### MAIN FUNCTION #############

function work -V CMD_NAME
  # TODO: parse arguments at different comand layers
  argparse --name=$CMD_NAME 'h/help' 'f/force' 'i/interactive' 'r/raw' -- $argv
  or return

  ### SPECIFIC HELP PAGES
  if test -n "$_flag_help"
    _print_special_help $argv[1]; return $status
  else if  test "$argv[1]" = "help"; and test -n "$argv[2]"
    _print_special_help $argv[2]; return $status
  end

  ### COMMANDS
  if test "$argv[1]" = "list"; or test "$argv[1]" = "ls"
   _exec_list $_flag_raw; return $status
  else if test "$argv[1]" = "go"
    _exec_go "$argv[2]" "$argv[3]" "$_flag_interactive"; return $status
  else if test "$argv[1]" = "create"; or test "$argv[1]" = "add"
   _exec_create "$argv[2]" "$argv[3]" "$_flag_force" "$argv[1]"; return $status
  else if test "$argv[1]" = "remove"; or test "$argv[1]" = "rm"
   _exec_remove $argv; return $status
  else if test "$argv[1]" = "version"
    _exec_version; return $status
  end

  ### GENERIC HELP PAGE
  if test -n "$_flag_help"; or test (count $argv) -eq 0; or test "$argv[1]" = "help"
    _print_help; return $status
  end

  _print_error "Unknown command \"$argv[1]\"."
  return 127
end
