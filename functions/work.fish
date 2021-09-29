#!/usr/bin/env fish

set -x WORK_VERSION "0.6.1"
set -x CMD_NAME "work"
set -x WORK_CONFIG_DIR "$HOME/.config/work"
set -x WORK_LIST "$WORK_CONFIG_DIR/worklist"

alias normal "set_color normal"
alias yellow "set_color yellow"
alias red "set_color red"
alias blue "set_color blue"
alias purple "set_color purple"
alias green "set_color green"

set -x normal (normal)
set -x yellow (yellow)
set -x red (red)
set -x blue (blue)
set -x purple (purple)
set -x green (green)

### UTILS ###
function prepare_worklist
  mkdir -p $WORK_CONFIG_DIR
  touch $WORK_LIST
end

### HELP AND USAGE ###

set list_usage "list" "[--raw/-r]" "			" "List all available workspaces"
set go_usage "go" "<workspace>" "			" "Change directory to a given workspace (use 'list' command)"
set create_usage "create" "[--force/-f] <dir> [name]" "	" "Create a workspace with the given directory"
set remove_usage "remove" "<workspace> [others...]" "	" "Remove a workspace"
set help_usage "help" "[command]" "			" "Print help page about a command"
set version_usage "version" "" "				" "Print the client version"

function print_cmd_name
  red
  echo -en $CMD_NAME
  normal
end

function print_description
  print_cmd_name
  echo ": a simple tool that help you to change current directory"
end

function print_command
  yellow
    echo -en "  $argv[1] "
  normal
  blue
    echo -en "$argv[2]"
  normal
  echo "$argv[3]$argv[4]"
end

function print_alias
  yellow
    echo -en "  $argv[5]"
    echo "$argv[6]$argv[1]"
  normal
end

function print_error
  red
  echo "work error: $argv"
  normal
end

function print_help
  print_description
  echo ""
  print_all_help_commands
  echo ""
  echo "Usage:"
  echo -en "  " ; print_cmd_name ;
  yellow ; echo -en " <command> " ; normal
  blue; echo "[options]"; normal
  echo ""
  echo -en "Use \""
  print_cmd_name
  yellow; echo -en " <command>"; normal
  blue ; echo -en " --help" ; normal
  echo -en '" '
  echo "for more information  about a given command."
end

function print_help_command
  echo -en "Usage: "
  print_cmd_name
  yellow
    echo -en " $argv[5] "
  normal
  blue
    echo -en "$argv[2]"
  normal
  echo ""
  echo "  $argv[4]"
end

function print_all_help_commands
  echo "Commands:"
  print_command $list_usage
  print_command $go_usage
  print_command $create_usage
  print_command $remove_usage
  print_command $help_usage
  print_command $version_usage
  echo
  echo "Aliases:"
  print_alias $list_usage ls "					"
  print_alias $create_usage add "					"
  print_alias $remove_usage rm "					"
end

function print_special_help
  set cmd_name "$argv[1]"

  # TODO: use printf %-30s instead of tabs (for better columns alignment)

  if test "$cmd_name" = "list"; or test "$cmd_name" = "ls"
    print_help_command $list_usage $cmd_name
    echo
    echo "Options:"
    echo "  $blue-r$normal, $blue--raw$normal			Print the raw list (no format, no color)"
  else if test "$cmd_name" = "go"
    print_help_command $go_usage $cmd_name
    echo
    echo "Options:"
    echo "  $blue-i$normal, $blue--interactive$normal		Interactive mode (use fzf)"
  else if test "$cmd_name" = "create"; or test "$cmd_name" = "add"
    print_help_command $create_usage $cmd_name
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
    print_help_command $remove_usage $cmd_name
    echo
    echo 'Parameters:'
    echo "  $blue<workspace>$normal					Workspace name to remove"
    echo " $blue [others...]$normal					Other workspaces to remove"
    echo
    echo "Examples:"
    echo "  $purple$CMD_NAME $cmd_name mywork $normal				Remove the \"mywork\" workspace"
    echo "  $purple$CMD_NAME $cmd_name mywork1 mywork2 test $normal	 	Remove \"mywork1\", \"mywork2\" and \"test\" workspaces"
  else if test "$cmd_name" = "help"
    print_help_command $help_usage $cmd_name
  else if test "$cmd_name" = "version"
    print_help_command $version_usage $cmd_name
  else
    print_error "help not found for \"$cmd_name\" command."
  end
end


######### COMMANDS #############
function ws_name
  echo (string split ':' $argv)[1]
end

function ws_path
  echo (string split ':' $argv)[2]
end

function exec_version
  print_description
  #print_cmd_name
  echo "  work version: $WORK_VERSION"
  echo "  fish version: $FISH_VERSION"
end

function exec_list -a raw_flag
  prepare_worklist

  if test -n "$raw_flag"
    cat $WORK_LIST
    return 0
  end

  printf "%-30s%s\n" "NAME" "PATH"

  set worklist (cat $WORK_LIST)
  for elem in (cat $WORK_LIST)
    blue
      printf "%-30s" (ws_name $elem)
    purple
      printf "%s\n" (ws_path $elem)
    normal
  end
end


function exec_go_interactive
  for e in (cat $WORK_LIST)
    # TODO: check fzf presence at start (display a warning if not)
    printf "%-30s:%s\n" (ws_name $e) (ws_path $e)
  end | fzf
end

function exec_go
  if test "$argv[1]" = "-"; or test "$argv[2]" = "-"
     cd -
     return
  end

  set target "$argv[1]"

  ### check for interactive mode
  if test -z "$target"; and test -n "$argv[3]" 
    set target (ws_name (exec_go_interactive) | xargs)

    test -z "$target"; and return 130 # here we assume it's a ctrl+C
  end

  if test -z "$target"
    print_special_help go; return $status
  end


  for elem in (cat $WORK_LIST)
    set workspace_to_go (ws_name $elem)

    if test "$target" = "$workspace_to_go"
      set path_to_go (ws_path $elem)
      break
    end
  end

  if test -n "$path_to_go"
    # GO TO workspace
    set cd_result (cd "$path_to_go" 2>&1)
    # in case of cd error
    if test -n "$cd_result"
      print_error "$cd_result"
      return 2
    end
    # noop
    # because 'cd' was correctly executed at this point
  else
    print_error "Unknown workspace \"$target\""
    return 2
  end
end

function exist_workspace -a name
  for elem in (cat $WORK_LIST)
    if test "$name" = (ws_name $elem)
      return 0
    end
  end
  return 1
end

function exec_create -a path -a name -a force_flag -a cmd
  test -z "$path"; and print_special_help $cmd; and return $status

  set path (realpath $path)
  test -z "$name"; and set name (basename $path)

  ### workspace exist
  if test -z "$force_flag"; and exist_workspace $name
    print_error "Workspace \"$name\" already exist"
    return 1
  end

  ### check if path is a valid directory
  not test -e "$path";
  and print_error "directory does not exist: \"$path\""; and return $status

  not test -d "$path";
  and print_error "not a directory: \"$path\""; and return $status

  ### get workspaces
  set --erase workspaces
  for elem in (cat $WORK_LIST)
    if test (ws_name $elem) != "$name"
      set workspaces $workspaces $elem
    end
  end
  set workspaces $workspaces "$name:$path"

  ### write workspaces
  prepare_worklist
  string join \n $workspaces > $WORK_LIST
  green ; echo "> created \"$name\"" workspace ; normal
end

function exec_remove -a cmd
  set argv $argv[2..-1]
  test -z "$argv[1]"; and print_special_help $cmd; and return $status

  for arg in $argv
    exec_simple_remove $arg
  end
end

function exec_simple_remove -a name
  if not exist_workspace $name
    print_error "Workspace \"$name\" does not exist"
    return 1
  end

  ### get filtered workspaces
  set --erase workspaces
  for elem in (cat $WORK_LIST)
    if test (ws_name $elem) != "$name"
      set workspaces $workspaces $elem
    end
  end
   
  ### write workspaces
  prepare_worklist
  string join \n $workspaces > $WORK_LIST

  yellow ; echo "- removed \"$name\"" workspace ; normal
end

######### MAIN FUNCTION #############

function work
  # TODO: parse arguments at different comand layers
  argparse --name=$CMD_NAME 'h/help' 'f/force' 'i/interactive' 'r/raw' -- $argv
  or return

  ### SPECIFIC HELP PAGES
  if test -n "$_flag_help"
    print_special_help $argv[1]; return $status
  else if  test "$argv[1]" = "help"; and test -n "$argv[2]"
    print_special_help $argv[2]; return $status
  end

  ### COMMANDS
  if test "$argv[1]" = "list"; or test "$argv[1]" = "ls"
   exec_list $_flag_raw; return $status
  else if test "$argv[1]" = "go"
    exec_go "$argv[2]" "$argv[3]" "$_flag_interactive"; return $status
  else if test "$argv[1]" = "create"; or test "$argv[1]" = "add"
   exec_create "$argv[2]" "$argv[3]" "$_flag_force" "$argv[1]"; return $status
  else if test "$argv[1]" = "remove"; or test "$argv[1]" = "rm"
   exec_remove $argv; return $status
  else if test "$argv[1]" = "version"
    exec_version; return $status
  end

  ### GENERIC HELP PAGE
  if test -n "$_flag_help"; or test (count $argv) -eq 0; or test "$argv[1]" = "help"
    print_help; return $status
  end

  print_error "Unknown command \"$argv[1]\"."
  return 127
end
