#!/usr/bin/env bash

# @file pfb.sh
# Pretty feedback (pfb) utility functions
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
# @ref https://github.com/dylanaraps/writing-a-tui-in-bash
# @ref https://www2.ccs.neu.edu/research/gpc/VonaUtils/vona/terminal/vtansi.htm
# @ref https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu

export PFB_VERSION="1.0.0"
export PFB_DEFAULT_LOG_DIR="${HOME}/logs"
export PFB_DEFAULT_LOG="scripts"
export PFB_SPINNER_STYLE="2"
export PFB_SPINNER_PID=""
export PFB_SPINNER_FLAG=""

# Print pretty feedback
# @param message type
# @param message string
# @param message
pfb() {
    local mtype message level icon

    _set_ansi_vars() {
        # Respect NO_COLOR environment variable (https://no-color.org/)
        # Also check PFB_NO_COLOR for pfb-specific override
        if [[ -n ${NO_COLOR:-} ]] || [[ ${PFB_NO_COLOR:-0} == "1" ]]; then
            # Set all color and formatting variables to empty
            export BLACK="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE=""
            export BBLACK="" BRED="" BGREEN="" BYELLOW="" BBLUE="" BMAGENTA="" BCYAN="" BWHITE=""
            export BOLD="" DIM="" REV="" RESET="" ESC=""
            export INFO_COLOR="" WARN_COLOR="" ERROR_COLOR="" SUCCESS_COLOR=""
            export SPINNER_COLOR="" PROMPT_COLOR=""
            return 0
        fi

        # Auto-disable colors if not outputting to a terminal
        # Allow PFB_FORCE_COLOR to override (for tests or specific use cases)
        if [[ ! -t 1 ]] && [[ -z ${PFB_FORCE_COLOR:-} ]]; then
            export BLACK="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE=""
            export BBLACK="" BRED="" BGREEN="" BYELLOW="" BBLUE="" BMAGENTA="" BCYAN="" BWHITE=""
            export BOLD="" DIM="" REV="" RESET="" ESC=""
            export INFO_COLOR="" WARN_COLOR="" ERROR_COLOR="" SUCCESS_COLOR=""
            export SPINNER_COLOR="" PROMPT_COLOR=""
            return 0
        fi

        local e=$'\033'
        
        # Basic 8 colors - foreground (30-37)
        export BLACK="${e}[30m"
        export RED="${e}[31m"
        export GREEN="${e}[32m"
        export YELLOW="${e}[33m"
        export BLUE="${e}[34m"
        export MAGENTA="${e}[35m"
        export CYAN="${e}[36m"
        export WHITE="${e}[37m"
        
        # Basic 8 colors - background (40-47)
        export BBLACK="${e}[40m"
        export BRED="${e}[41m"
        export BGREEN="${e}[42m"
        export BYELLOW="${e}[43m"
        export BBLUE="${e}[44m"
        export BMAGENTA="${e}[45m"
        export BCYAN="${e}[46m"
        export BWHITE="${e}[47m"
        
        # Text attributes
        export BOLD="${e}[1m"
        export DIM="${e}[2m"
        export REV="${e}[7m"
        export RESET="${e}[0m"
        export ESC="$e"
        
        # RGB color palette (24-bit true color)
        export INFO_COLOR="${e}[38;2;100;180;220m"       # Soft blue-cyan
        export WARN_COLOR="${e}[38;2;255;180;80m"        # Warm amber
        export ERROR_COLOR="${e}[38;2;240;90;90m"        # Clear red
        export SUCCESS_COLOR="${e}[38;2;90;200;120m"     # Fresh green
        export SPINNER_COLOR="${e}[38;2;215;119;87m"     # Claude orange
        export PROMPT_COLOR="${e}[38;2;120;220;240m"     # Bright cyan
    }
    _set_ansi_vars

    # shellcheck disable=SC2059
    cursor_on()   { printf "${ESC}[?25h"; }
    # shellcheck disable=SC2059
    cursor_off()  { printf "${ESC}[?25l"; }
    get_cursor_row() {
        local ROW COL
        # shellcheck disable=SC2034
        IFS=';' read -srdR -p $'\E[6n' ROW COL
        echo "${ROW#*[}"
    }
    # shellcheck disable=SC2329
    get_cursor_col() {
        local ROW COL
        # shellcheck disable=SC2034
        IFS=';' read -srdR -p $'\E[6n' ROW COL
        echo "${COL}"
    }
    # shellcheck disable=SC2059
    cursor_to()         { printf "${ESC}[$1;${2:-1}H"; }
    # shellcheck disable=SC2059
    cursor_up()         { printf "${ESC}[A"; }
    # shellcheck disable=SC2059
    # shellcheck disable=SC2329
    cursor_down()       { printf "${ESC}[B"; }
    # shellcheck disable=SC2059
    cursor_sol()        { printf "\r"; }
    # shellcheck disable=SC2059
    erase_down()        { printf "${ESC}[J"; }
    # shellcheck disable=SC2059
    # shellcheck disable=SC2329
    erase_up()        { printf "${ESC}[1J"; }
    # shellcheck disable=SC2059
    # shellcheck disable=SC2329
    erase_screen()        { printf "${ESC}[2J"; }
    # shellcheck disable=SC2059
    # shellcheck disable=SC2329
    erase_eol()        { printf "${ESC}[K"; }
    # shellcheck disable=SC2059
    erase_sol()        { printf "${ESC}[1K"; }
    # shellcheck disable=SC2059
    erase_line()        { printf "${ESC}[2K"; }
    # shellcheck disable=SC2059
    save_pos()          { printf "${ESC}7"; }
    # shellcheck disable=SC2059
    restore_pos()       { printf "${ESC}8"; }
    # shellcheck disable=SC2059
    # shellcheck disable=SC2329
    rgb_fg()            { printf "${ESC}[38;2;${1};${2};${3}m"; }
    # shellcheck disable=SC2059
    # shellcheck disable=SC2329
    rgb_bg()            { printf "${ESC}[48;2;${1};${2};${3}m"; }

    _print_message() {
        # TODO: Consider using logger for datestamping and redirection to syslog
        printf "${BOLD}%s${RESET}${BOLD}%s${RESET} %s${RESET}" "$level" "$icon" "$message"
    }

    # Print pretty selection prompt for list of options
    # @param options array of options to select from
    # @return selected index of option in the given array
    _select_option() {
        local message options i last_row start_row selected
        options=("$@")

        # shellcheck disable=SC2059
        print_option()      { printf "  $1\n"; }
        # shellcheck disable=SC2059
        print_selected()    { printf "${BOLD}${PROMPT_COLOR}> $1${RESET}\n"; }

        key_input() { 
            read -rs -n3 key 2>/dev/null >&2
            if [[ $key = ${ESC}[A ]]; then echo 'up';    fi
            if [[ $key = ${ESC}[B ]]; then echo 'down';  fi
            if [[ $key = ''       ]]; then echo 'enter'; fi; 
        }

        # shellcheck disable=SC2059
        printf "   ${INFO_COLOR}[Use arrows to move]${RESET}\n"

        for (( i=0; i<${#options[@]}; i++ )); do echo; done
        last_row="$(get_cursor_row)"
        start_row=$((last_row - ${#options[@]}))
        trap "cursor_on; stty echo; printf '\n'; exit" 2
        cursor_off
        selected=0

        while true; do
            local i=0
            for (( i=0; i<${#options[@]}; i++ )); do
                cursor_to $((start_row + i))
                if [[ $i -eq $selected ]]; then
                    print_selected "${options[$i]}"
                else
                    print_option "${options[$i]}"
                fi
            done

            case $(key_input) in
                enter) break;;
                up)    ((selected--));
                    if [[ $selected -lt 0 ]]; then selected=$((${#options[@]} - 1)); fi;;
                down)  ((selected++));
                    if [[ $selected -ge $# ]]; then selected=0; fi;;
            esac
        done

        cursor_to $start_row
        erase_down
        cursor_on

        return "$selected"
    }

    # Echo the filename of the log file
    _logfile() {
        [[ -d $PFB_DEFAULT_LOG_DIR ]] || mkdir -p "$PFB_DEFAULT_LOG_DIR"
        echo "${PFB_DEFAULT_LOG_DIR}/${PFB_DEFAULT_LOG}.log"
    }

    # Print confirmation prompt with yes/no selection
    # @param message to show
    # @return 0 for yes, 1 for no
    _confirm() {
        local message selected
        message="$1"

        print_option()      { printf "  %-3s" "$1"; }
        print_selected()    { printf "${BOLD}${PROMPT_COLOR}> %-3s${RESET}" "$1"; }

        key_input() {
            read -rs -n1 key 2>/dev/null >&2
            case "$key" in
                $'\x1b')
                    read -rs -n2 key 2>/dev/null >&2
                    if [[ $key = "[D" ]]; then echo 'left';  fi
                    if [[ $key = "[C" ]]; then echo 'right'; fi
                    ;;
                "y"|"Y") echo 'yes';;
                "n"|"N") echo 'no';;
                "") echo 'enter';;
            esac
        }

        trap "cursor_on; stty echo; printf '\n'; exit" 2

        cursor_off
        selected=0

        while true; do
            cursor_sol
            erase_line
            printf "${BOLD}${PROMPT_COLOR}?${RESET}${BOLD} %s${RESET} ${DIM}(y/n)${RESET} " "$message"
            if [[ $selected -eq 0 ]]; then
                print_selected "Yes"
                printf " / "
                print_option "No"
            else
                print_option "Yes"
                printf " / "
                print_selected "No"
            fi

            case $(key_input) in
                enter) break;;
                yes)   selected=0; break;;
                no)    selected=1; break;;
                left|right)
                    if [[ $selected -eq 0 ]]; then
                        selected=1
                    else
                        selected=0
                    fi
                    ;;
            esac
        done

        cursor_sol
        erase_line
        cursor_on
        printf "${BOLD}${PROMPT_COLOR}?${RESET}${BOLD} %s${RESET} " "$message"
        if [[ $selected -eq 0 ]]; then
            # shellcheck disable=SC2059
            printf "${SUCCESS_COLOR}Yes${RESET}\n"
        else
            # shellcheck disable=SC2059
            printf "${DIM}No${RESET}\n"
        fi

        return "$selected"
    }

    # Print styled input prompt and collect text
    # @param message to show as prompt
    # @param default value (optional)
    # @return user input via echo
    _input() {
        local message default value
        message="$1"
        default="${2:-}"

        if [[ -n $default ]]; then
            printf "${BOLD}${PROMPT_COLOR}?${RESET}${BOLD} ${message}${RESET} ${DIM}[$default]${RESET} " >&2
        else
            printf "${BOLD}${PROMPT_COLOR}?${RESET}${BOLD} ${message}${RESET} " >&2
        fi

        read -r value

        if [[ -z $value && -n $default ]]; then
            value="$default"
        fi

        echo "$value"
    }

    # Get spinner frames for the selected style
    _get_spinner_frames() {
        # shellcheck disable=SC2034
        local spinner_0=( "|" "/" "-" "\\" )
        # shellcheck disable=SC2034
        local spinner_1=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
        # shellcheck disable=SC2034
        local spinner_2=( "⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷" )
        # shellcheck disable=SC2034
        local spinner_3=( "⢄" "⢂" "⢁" "⡁" "⡈" "⡐" "⡠" )
        # shellcheck disable=SC2034
        local spinner_4=( "█" "▓" "▒" "░" )
        # shellcheck disable=SC2034
        local spinner_5=( "⠁" "⠂" "⠄" "⡀" "⢀" "⠠" "⠐" "⠈" )
        # shellcheck disable=SC2034
        local spinner_6=( "🌍" "🌎" "🌏" )
        # shellcheck disable=SC2034
        local spinner_7=( "🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘" )
        # shellcheck disable=SC2034
        local spinner_8=( "∙" "●" )
        # shellcheck disable=SC2034
        local spinner_9=( "🙈" "🙉" "🙊" )
        # shellcheck disable=SC2034
        local spinner_10=( "◐" "◓" "◑" "◒" )
        # shellcheck disable=SC2034
        local spinner_11=( "▁" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" )
        # shellcheck disable=SC2034
        local spinner_12=( "←" "↖" "↑" "↗" "→" "↘" "↓" "↙" )
        # shellcheck disable=SC2034
        local spinner_13=( "·" "✢" "✳" "✶" "✻" "✽" )
        # shellcheck disable=SC2034
        local spinner_14=( "▏" "▎" "▍" "▌" "▋" "▊" "▉" "█" "▉" "▊" "▋" "▌" "▍" "▎" )
        # shellcheck disable=SC2034
        local spinner_15=( "◴" "◷" "◶" "◵" )
        # shellcheck disable=SC2034
        local spinner_16=( "🕛" "🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" )

        local style=${PFB_SPINNER_STYLE:-2}

        # Validate spinner style range
        if ! [[ "$style" =~ ^[0-9]+$ ]] || [[ $style -lt 0 ]] || [[ $style -gt 16 ]]; then
            echo "pfb: invalid spinner style '$style' (valid range: 0-16)" >&2
            echo "Using default spinner style 2" >&2
            style=2
        fi

        local -n frames_ref="spinner_${style}"
        printf '%s\n' "${frames_ref[@]}"
    }

    # List available spinner styles
    _list_spinner_styles() {
        echo " 0: Classic"
        echo " 1: Braille dots"
        echo " 2: Braille wave (default)"
        echo " 3: Braille sweep"
        echo " 4: Blocks"
        echo " 5: Braille pulse"
        echo " 6: Earth"
        echo " 7: Moon phases"
        echo " 8: Pulsing dot"
        echo " 9: Monkeys"
        echo "10: Quadrants"
        echo "11: Growing bar"
        echo "12: Arrows"
        echo "13: Claude"
        echo "14: Pulsing bar"
        echo "15: Segments"
        echo "16: Clock faces"
    }

    # Start spinner in background without running a command
    # @param message to show
    _wait_start() {
        local message="$1"
        local -a frames
        local step=0

        # Stop any existing spinner first
        _wait_stop 2>/dev/null
        
        mapfile -t frames < <(_get_spinner_frames)
        
        # Create unique flag file  
        PFB_SPINNER_FLAG="/tmp/pfb_spinner_$$_${RANDOM}"
        touch "$PFB_SPINNER_FLAG"
        
        cursor_off
        
        # Run spinner in background - capture flag in local var
        {
            local flag_file="$PFB_SPINNER_FLAG"
            local step=0
            while [[ -f "$flag_file" ]]; do
                erase_sol
                cursor_sol
                printf "${BOLD}${INFO_COLOR}[wait]${RESET} ${BOLD}${SPINNER_COLOR}${frames[step++ % ${#frames[@]}]}${RESET} ${message}${RESET}"
                sleep 0.08
            done
            # Clean up on exit
            erase_sol
            cursor_sol
            cursor_on
        } 2>/dev/null &
        
        PFB_SPINNER_PID=$!
        disown 2>/dev/null

        # Since there's no way to suspend the inital job control message
        # because `set +m`, using a subshell, and piping to /dev/null do
        # not work, move the cursor up to the initial job control message
        # line, clear it, and move the cursor to the start of the line.
        # sleep 0.01 # Give bash time to echo the job control message
        cursor_up
        erase_sol
        cursor_sol
    }

    # Stop active spinner - MUST be synchronous
    _wait_stop() {
        # Early exit if no spinner
        [[ -z $PFB_SPINNER_PID ]] && return 0
        
        # Remove flag file to signal stop
        [[ -n $PFB_SPINNER_FLAG ]] && rm -f "$PFB_SPINNER_FLAG" 2>/dev/null
        
        # Wait for graceful exit (up to 0.5 seconds)
        local count=0
        while kill -0 "$PFB_SPINNER_PID" 2>/dev/null && [[ $count -lt 10 ]]; do
            sleep 0.05
            count=$((count + 1))
        done
        
        # Force kill if still running
        if kill -0 "$PFB_SPINNER_PID" 2>/dev/null; then
            kill -9 "$PFB_SPINNER_PID" 2>/dev/null
            wait "$PFB_SPINNER_PID" 2>/dev/null
        fi
        
        # Ensure line is cleared and cursor is on
        erase_sol
        cursor_sol
        cursor_on

        # Clear state
        PFB_SPINNER_PID=""
        PFB_SPINNER_FLAG=""

        # Always return success
        return 0
    }

    # Print pretty spinner prompt
    # @param message to show
    # @param command to be performed (optional)
    _wait() {
        local message logfile pid command exit_code

        message="$1" && shift
        command="$*"
        
        # No command provided - just start spinner
        if [[ -z $command ]]; then
            _wait_start "$message"
            return 0
        fi
        
        # Command provided - run with spinner
        logfile="$(_logfile)"
        printf '\n$ %s\n' "$command" >>"$logfile"
        
        { eval "$command" >>"$logfile" 2>&1 & } 2>/dev/null
        pid=$!
        disown 2>/dev/null
        
        trap "_wait_stop; cursor_on; stty echo; printf '\n'; exit" INT TERM

        _wait_start "$message"
        
        # Poll for command completion
        while kill -0 "$pid" 2>/dev/null; do
            sleep 0.1
        done
        
        wait "$pid" 2>/dev/null
        exit_code=$?
        
        _wait_stop

        return $exit_code
    }

    _test() {
        PFB_DEFAULT_LOG="pfb_test"
        
        clear

        pfb heading "Log levels:"
        echo
        pfb info "There are only 24 hours in the day. Play hard, work hard."
        pfb warn "It's hard to be green! Deal with it!"
        pfb err "Going... going... gone... BOOM!"
        pfb success "That's all folks."

        sleep 2 && clear

        pfb heading "Headings:"
        pfb heading "Some wisdom from Dr. Seuss" "🐸"
        pfb subheading "Be who you are and say what you feel,"
        pfb subheading "because those who mind don't matter and,"
        pfb subheading "those who matter don't mind."
        pfb suggestion "This suggests some wise words to live by"

        sleep 2 && clear

        pfb heading "Long running commands:"
        echo
        pfb spinner start "Having a five second snooze..." 'sleep 5 && date'
        pfb success "Five second snooze successful... that feels better!"
        pfb subheading "Commands are written to ${BOLD}$(pfb logfile)${RESET}"

        sleep 2 && clear

        pfb heading "Spinner styles:"
        pfb subheading "Available spinner styles (set PFB_SPINNER_STYLE=N):"
        mapfile -t spinner_names < <(_list_spinner_styles)
        echo
        for i in "${!spinner_names[@]}"; do
            PFB_SPINNER_STYLE=$i
            pfb spinner start "${spinner_names[$i]}" 'sleep 2'
        done
        unset PFB_SPINNER_STYLE

        sleep 2 && clear

        pfb heading "Text input:"
        pfb subheading "Supports default values shown in [brackets]."
        echo
        local answer
        answer=$(pfb input "What's your name?" "Anonymous")
        pfb success "Nice to meet you, $answer!"

        command -v fzf 1>/dev/null 2>&1 && {
            sleep 2 && clear
            pfb heading "Prompt and answer (for external tools):"
            pfb subheading "The prompt/answer pattern works with external tools like fzf."
            echo
            pfb prompt "Pick a word..."
            # shellcheck disable=SC2155
            local word=$(fzf --height=40% --layout=reverse --info=inline --border < /usr/share/dict/words)
            erase_line
            pfb prompt "Pick a word..."
            pfb answer "You chose $word"
        }

        sleep 2 && clear

        pfb heading "Selection from a set of options:"
        pfb subheading "Use up/down arrows to navigate, enter to select."
        echo
        local options=("Four in Hand Necktie" "The Seven Fold Tie" "Skinny Necktie" "Bowtie" "Western Bowtie" "Bolo Tie" "Cravat" "Neckerchief" "Nothing. Can't stand anything round my neck")
        pfb prompt "Select a particular type of tie you prefer to adorn yourself with?"
        pfb select "${options[@]}"
        selected=$?
        cursor_up
        erase_line
        pfb prompt "Select a particular type of tie you prefer to adorn yourself with?"
        pfb answer "${options[$selected]}"

        sleep 2 && clear

        pfb heading "Confirm prompts:"
        pfb subheading "Use left/right arrows, y/n, or enter to select. Returns 0 for yes, 1 for no."
        echo
        # shellcheck disable=SC2015
        pfb confirm "Do you enjoy using pfb?" && \
            pfb success "Wonderful! We're glad you like it." || \
            pfb info "That's okay, we'll keep improving."
    }

    # Calculate Levenshtein distance between two strings
    _levenshtein_distance() {
        local s1="$1" s2="$2"
        local len1=${#s1} len2=${#s2}
        local -A matrix
        local i j cost

        # Initialize matrix
        for ((i=0; i<=len1; i++)); do
            matrix[$i,0]=$i
        done
        for ((j=0; j<=len2; j++)); do
            matrix[0,$j]=$j
        done

        # Fill matrix
        for ((i=1; i<=len1; i++)); do
            for ((j=1; j<=len2; j++)); do
                if [[ "${s1:i-1:1}" == "${s2:j-1:1}" ]]; then
                    cost=0
                else
                    cost=1
                fi

                local a=$((matrix[$((i-1)),$j] + 1))
                local b=$((matrix[$i,$((j-1))] + 1))
                local c=$((matrix[$((i-1)),$((j-1))] + cost))

                # Find minimum
                matrix[$i,$j]=$a
                [[ $b -lt ${matrix[$i,$j]} ]] && matrix[$i,$j]=$b
                [[ $c -lt ${matrix[$i,$j]} ]] && matrix[$i,$j]=$c
            done
        done

        echo "${matrix[$len1,$len2]}"
    }

    # Suggest similar command for typos
    _suggest_command() {
        local input="$1"
        local commands=(
            "info" "warn" "error" "success" "err"
            "heading" "subheading" "suggestion"
            "spinner" "wait" "wait-stop"
            "confirm" "input" "select" "select-from"
            "prompt" "answer"
            "test" "list-spinner-styles" "logfile"
            "help" "version"
        )

        local min_distance=999
        local suggestion=""
        local distance

        # Find command with minimum distance
        for cmd in "${commands[@]}"; do
            distance=$(_levenshtein_distance "$input" "$cmd")
            if [[ $distance -lt $min_distance ]]; then
                min_distance=$distance
                suggestion="$cmd"
            fi
        done

        # Only suggest if distance is small (within 2 character changes)
        # and input is at least 3 characters (avoid false positives)
        if [[ $min_distance -le 2 ]] && [[ ${#input} -ge 3 ]]; then
            echo "$suggestion"
        fi
    }

    _print_help() {
        cat <<'EOF'
 pfb - Pretty feedback for bash scripts

 Usage: pfb <command> [args...]

 Quick Start Examples:
   pfb info "Starting process..."            # Display info message
   pfb spinner start "Loading..." 'sleep 2'  # Show spinner during command
   pfb confirm "Continue?" && next_step      # Ask yes/no question
   name=$(pfb input "Your name?" "Anonymous") # Get text input

 Common Commands:
   info, warn, error, success    Display log-level messages
   heading, subheading           Structure your output
   spinner start/stop            Show progress for long operations
   confirm, input, select        Interactive prompts

 All Commands:
   info <msg>              Display info message
   warn <msg>              Display warning message
   error <msg>             Display error message
   success <msg>           Display success message

   heading <msg> [icon]    Display heading
   subheading <msg>        Display subheading
   suggestion <msg>        Display suggestion

   spinner start <msg> [cmd]  Start spinner (optionally with command)
   spinner stop               Stop active spinner

   confirm <question>      Yes/no confirmation (exit code 0/1)
   input <prompt> [default]   Get text input
   select <opt1> <opt2>...    Select from options (returns index via $?)

   prompt <msg>            Display prompt (save cursor position)
   answer <msg>            Display answer (restore cursor position)

   test                    Run interactive demo
   list-spinner-styles     Show available spinner styles
   logfile                 Show log file path

 Options:
   --help, -h             Show this help
   --version, -v          Show version

 Environment Variables:
   PFB_SPINNER_STYLE      Spinner animation style (0-16, default: 2)
   PFB_DEFAULT_LOG_DIR    Log directory (default: $HOME/logs)
   PFB_DEFAULT_LOG        Log basename (default: scripts)
   NO_COLOR               Disable colors (https://no-color.org)
   PFB_NO_COLOR           pfb-specific color disable (set to 1)
   PFB_FORCE_COLOR        Force colors even when not a TTY

 More Examples:
   # Selection from options
   options=("Option 1" "Option 2" "Option 3")
   pfb select "${options[@]}"
   selected=$?
   echo "You selected: ${options[$selected]}"

   # Disable colors for accessibility
   NO_COLOR=1 pfb info "Plain text output"

 Backward Compatibility:
   pfb wait <msg> [cmd]    → use 'pfb spinner start' instead
   pfb wait-stop           → use 'pfb spinner stop' instead
   pfb select-from         → use 'pfb select' instead

 Documentation: https://github.com/ali5ter/pfb
 Report issues: https://github.com/ali5ter/pfb/issues
EOF
    }

    mtype="${1:-}"
    message="${2:-}"
    level=''
    icon=' '

    if [[ -z "$mtype" ]]; then
        _print_help
        return 0
    fi

    case "$mtype" in
        --help|-h|help)
            _print_help
            return 0
            ;;
        --version|-v|version)
            echo "pfb version $PFB_VERSION"
            return 0
            ;;
        info*)
            if [[ -z "$message" ]]; then
                echo "pfb: info requires a message argument" >&2
                echo "Usage: pfb info <message>" >&2
                echo "Example: pfb info \"Processing complete\"" >&2
                return 1
            fi
            level="${INFO_COLOR}[info] "
            message="${message}
"
            _print_message
            ;;
        warn*)
            if [[ -z "$message" ]]; then
                echo "pfb: warn requires a message argument" >&2
                echo "Usage: pfb warn <message>" >&2
                echo "Example: pfb warn \"Low disk space detected\"" >&2
                return 1
            fi
            level="${WARN_COLOR}[warn] "
            message="${message}
"
            _print_message
            ;;
        err*)
            if [[ -z "$message" ]]; then
                echo "pfb: error requires a message argument" >&2
                echo "Usage: pfb error <message>" >&2
                echo "Example: pfb error \"Failed to connect to server\"" >&2
                return 1
            fi
            _wait_stop
            level="${ERROR_COLOR}[error]"
            message="${message}
"
            _print_message
            ;;
        prompt)
            if [[ -z "$message" ]]; then
                echo "pfb: prompt requires a message argument" >&2
                echo "Usage: pfb prompt <message>" >&2
                echo "Example: pfb prompt \"Enter your name:\"" >&2
                return 1
            fi
            icon="${PROMPT_COLOR}?"
            message="${BOLD}$message"
            _print_message
            save_pos
            ;;
        answer)
            if [[ -z "$message" ]]; then
                echo "pfb: answer requires a message argument" >&2
                echo "Usage: pfb answer <message>" >&2
                echo "Example: pfb answer \"John Doe\"" >&2
                return 1
            fi
            message=" ${INFO_COLOR}${message}
"
            restore_pos
            _print_message
            ;;
        done|succ*)
            if [[ -z "$message" ]]; then
                echo "pfb: success requires a message argument" >&2
                echo "Usage: pfb success <message>" >&2
                echo "Example: pfb success \"Process completed successfully\"" >&2
                return 1
            fi
            _wait_stop
            level="${SUCCESS_COLOR}[done] "
            icon="${SUCCESS_COLOR}✓"
            message="${message}
"
            _print_message
            ;;
        heading)
            if [[ -z "$message" ]]; then
                echo "pfb: heading requires a message argument" >&2
                echo "Usage: pfb heading <message> [icon]" >&2
                echo "Example: pfb heading \"Chapter 1\" §" >&2
                return 1
            fi
            echo
            icon="${3:-§}"
            message=$"${BOLD}${message}
"
            _print_message
            ;;
        subheading)
            if [[ -z "$message" ]]; then
                echo "pfb: subheading requires a message argument" >&2
                echo "Usage: pfb subheading <message>" >&2
                echo "Example: pfb subheading \"Introduction to Bash Scripting\"" >&2
                return 1
            fi
            message=" ${DIM}${message}
"
            _print_message
            ;;
        suggestion)
            if [[ -z "$message" ]]; then
                echo "pfb: suggestion requires a message argument" >&2
                echo "Usage: pfb suggestion <message>" >&2
                echo "Example: pfb suggestion \"Consider using functions for better code organization.\"" >&2
                return 1
            fi
            message=" ${BOLD}${SUCCESS_COLOR}${message}
"
            _print_message
            ;;
        spinner)
            case "${2:-}" in
                start)
                    if [[ $# -lt 3 ]]; then
                        echo "pfb: spinner start requires a message" >&2
                        echo "Usage: pfb spinner start <message> [command]" >&2
                        echo "Example: pfb spinner start \"Loading...\" 'sleep 2'" >&2
                        return 1
                    fi
                    shift 2
                    _wait "$@"
                    ;;
                stop)
                    _wait_stop
                    ;;
                *)
                    echo "pfb: unknown spinner subcommand '$2'" >&2
                    echo "Usage: pfb spinner {start|stop}" >&2
                    return 1
                    ;;
            esac
            ;;
        wait)
            # Backward compatibility: redirect to spinner start
            shift
            _wait "$@"
            ;;
        wait-stop)
            # Backward compatibility: redirect to spinner stop
            _wait_stop
            ;;
        select)
            shift
            _select_option "$@"
            ;;
        select-from)
            # Backward compatibility: redirect to select
            shift
            _select_option "$@"
            ;;
        confirm)
            if [[ -z "$message" ]]; then
                echo "pfb: confirm requires a question argument" >&2
                echo "Usage: pfb confirm <question>" >&2
                echo "Example: pfb confirm \"Do you want to continue?\"" >&2
                return 1
            fi
            shift
            _confirm "$@"
            ;;
        input)
            if [[ -z "$message" ]]; then
                echo "pfb: input requires a prompt argument" >&2
                echo "Usage: pfb input <prompt> [default]" >&2
                echo "Example: pfb input \"Enter your name:\" \"Anonymous\"" >&2
                return 1
            fi
            shift
            _input "$@"
            ;;
        test)
            _test
            ;;
        list-spinner-styles)
            _list_spinner_styles
            ;;
        logfile)
            _logfile
            ;;
        *)
            echo "pfb: unknown command '$mtype'" >&2

            # Suggest similar command if available
            local suggestion
            suggestion=$(_suggest_command "$mtype")
            if [[ -n $suggestion ]]; then
                echo >&2
                echo "Did you mean '${suggestion}'?" >&2
            fi

            echo >&2
            echo "Try 'pfb --help' for usage information" >&2
            return 1
            ;;
    esac
}