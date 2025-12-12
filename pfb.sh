#!/usr/bin/env bash

# @file pfb.sh
# Pretty feedback (pfb) utility functions
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
# @ref https://github.com/dylanaraps/writing-a-tui-in-bash
# @ref https://www2.ccs.neu.edu/research/gpc/VonaUtils/vona/terminal/vtansi.htm
# @ref https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu

export PFB_DEFAULT_LOG_DIR="${HOME}/logs"
export PFB_DEFAULT_LOG="scripts"

# Print pretty feedback
# @param message type
# @param message string
# @param message
pfb() {
    local mtype message level icon

    _set_ansi_vars() {
        local colors=( BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE )
        for (( i=0; i<${#colors[@]}; i++ )); do
            # shellcheck disable=SC2086
            export ${colors[${i}]}="$(tput setaf ${i})"
            # shellcheck disable=SC2086
            export B${colors[${i}]}="$(tput setab ${i})"
        done
        # shellcheck disable=SC2155
        export BOLD="$(tput bold)"
        # shellcheck disable=SC2155
        export DIM="$(tput dim)"
        # shellcheck disable=SC2155
        export REV="$(tput rev)"
        # shellcheck disable=SC2155
        export RESET="$(tput sgr0)"
        # shellcheck disable=SC2155
        export ESC=$(printf "\033")

        # RGB color palette (24-bit true color)
        export INFO_COLOR="${ESC}[38;2;100;180;220m"       # Soft blue-cyan
        export WARN_COLOR="${ESC}[38;2;255;180;80m"        # Warm amber
        export ERROR_COLOR="${ESC}[38;2;240;90;90m"        # Clear red
        export SUCCESS_COLOR="${ESC}[38;2;90;200;120m"     # Fresh green
        export SPINNER_COLOR="${ESC}[38;2;215;119;87m"     # Claude Code orange
        export PROMPT_COLOR="${ESC}[38;2;120;220;240m"     # Bright cyan
    }
    _set_ansi_vars

    # shellcheck disable=SC2059
    cursor_on()   { printf "${ESC}[?25h"; }
    # shellcheck disable=SC2059
    cursor_off()  { printf "${ESC}[?25l"; }
    # shellcheck disable=SC2034
    get_cursor_row()    { IFS=';' read -srdR -p $'\E[6n' ROW COL; echo "${ROW#*[}"; }
    # shellcheck disable=SC2059
    cursor_to()         { printf "${ESC}[$1;${2:-1}H"; }
    # shellcheck disable=SC2059
    cursor_up()         { printf "${ESC}[A"; }
    # shellcheck disable=SC2059
    cursor_down()       { printf "${ESC}[B"; }
    # shellcheck disable=SC2059
    line_start()        { printf "\r"; }
    # shellcheck disable=SC2059
    erase_down()        { printf "${ESC}[J"; }
    # shellcheck disable=SC2059
    erase_eol()        { printf "${ESC}[K"; }
    # shellcheck disable=SC2059
    erase_line()        { printf "${ESC}[2K"; }
    # shellcheck disable=SC2059
    save_pos()          { printf "${ESC}7"; }
    # shellcheck disable=SC2059
    restore_pos()       { printf "${ESC}8"; }
    # shellcheck disable=SC2059
    rgb_fg()            { printf "${ESC}[38;2;${1};${2};${3}m"; }
    # shellcheck disable=SC2059
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
                if [ "$i" -eq "$selected" ]; then
                    print_selected "${options[$i]}"
                else
                    print_option "${options[$i]}"
                fi
            done

            case $(key_input) in
                enter) break;;
                up)    ((selected--));
                    if [ "$selected" -lt 0 ]; then selected=$((${#options[@]} - 1)); fi;;
                down)  ((selected++));
                    if [ "$selected" -ge $# ]; then selected=0; fi;;
            esac
        done

        cursor_to $start_row
        erase_down
        cursor_on

        return "$selected"
    }

    # Echo the filename of the log file
    _logfile() {
        [ -d "$PFB_DEFAULT_LOG_DIR" ] || mkdir -p "$PFB_DEFAULT_LOG_DIR"
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
            line_start
            erase_line
            printf "${BOLD}${PROMPT_COLOR}?${RESET}${BOLD} %s${RESET} ${DIM}(y/n)${RESET} " "$message"
            if [ "$selected" -eq 0 ]; then
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
                    if [ "$selected" -eq 0 ]; then
                        selected=1
                    else
                        selected=0
                    fi
                    ;;
            esac
        done

        line_start
        erase_line
        cursor_on
        printf "${BOLD}${PROMPT_COLOR}?${RESET}${BOLD} %s${RESET} " "$message"
        if [ "$selected" -eq 0 ]; then
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

        if [ -n "$default" ]; then
            printf "${BOLD}${PROMPT_COLOR}?${RESET}${BOLD} ${message}${RESET} ${DIM}[$default]${RESET} " >&2
        else
            printf "${BOLD}${PROMPT_COLOR}?${RESET}${BOLD} ${message}${RESET} " >&2
        fi

        read -r value

        if [ -z "$value" ] && [ -n "$default" ]; then
            value="$default"
        fi

        echo "$value"
    }

    # Print pretty spinner prompt
    # @param message to show
    # @param command to be performed
    _wait() {
        local message frames step logfile pid command

        message="$1" && shift
        command="$*"

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

        # Select spinner style (default: 2)
        # Env var PFB_SPINNER_STYLE can be set to choose spinner style (0-18)
        local style=${PFB_SPINNER_STYLE:-2}
        eval "frames=(\"\${spinner_${style}[@]}\")"
        step=0

        logfile="$(_logfile)"

        echo -e "\n\$ $command" >>"$logfile"

        { eval "$command" >>"$logfile" 2>&1 & } 2>/dev/null
        pid=$!
        disown 2>/dev/null

        trap "cursor_on; stty echo; printf '\n'; exit" 2

        cursor_off
        while kill -0 "$pid" 2>/dev/null; do
            line_start
            erase_line
            # shellcheck disable=SC2059
            printf "${BOLD}${INFO_COLOR}[wait]${RESET} ${BOLD}${SPINNER_COLOR}${frames[step++ % ${#frames[@]}]}${RESET} ${message}${RESET}"
            sleep 0.08
        done

        wait "$pid" 2>/dev/null

        line_start
        erase_line
        cursor_on
    }

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
        echo "13: Claude code"
        echo "14: Pulsing bar"
        echo "15: Segments"
        echo "16: Clock faces"
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
        pfb wait "Having a five second snooze..." 'sleep 5 && date'
        erase_line
        pfb success "Five second snooze successful... that feels better!"
        pfb subheading "Commands are written to ${BOLD}$(pfb logfile)${RESET}"

        sleep 2 && clear

        pfb heading "Spinner styles:"
        pfb subheading "Available spinner styles (set PFB_SPINNER_STYLE=N):"
        mapfile -t spinner_names < <(_list_spinner_styles)
        echo
        for i in "${!spinner_names[@]}"; do
            PFB_SPINNER_STYLE=$i 
            pfb wait "${spinner_names[$i]}" 'sleep 2'
            cursor_off
            erase_line
        done
        cursor_on
        unset PFB_SPINNER_STYLE

        sleep 2 && clear

        pfb heading "Text input:"
        pfb subheading "Supports default values shown in [brackets]."
        echo
        local answer
        answer=$(pfb input "What's your name?" "Anonymous")
        pfb success "Nice to meet you, $answer!"

        command -v fzf 1>/dev/null 2>&1 && {
            echo
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
        pfb select-from "${options[@]}"
        selected=$?
        cursor_up
        erase_line
        pfb prompt "Select a particular type of tie you prefer to adorn yourself with?"
        pfb answer "${options[$selected]}"

        sleep 2 && clear

        pfb heading "Confirm prompts:"
        pfb subheading "Use left/right arrows, y/n, or enter to select. Returns 0 for yes, 1 for no."
        echo
        pfb confirm "Do you enjoy using pfb?"
        if [ $? -eq 0 ]; then
            pfb success "Wonderful! We're glad you like it."
        else
            pfb info "That's okay, we'll keep improving."
        fi
    }

    mtype="${1}"
    message="${2:-}"
    level=''
    icon=' '

    case "$mtype" in
        info*)
            level="${INFO_COLOR}[info] "
            message="${message}
"
            _print_message
            ;;
        warn*)
            level="${WARN_COLOR}[warn] "
            message="${message}
"
            _print_message
            ;;
        err*)
            level="${ERROR_COLOR}[fatal]"
            message="${message}
"
            _print_message
            ;;
        prompt)
            icon="${PROMPT_COLOR}?"
            message="${BOLD}$message"
            _print_message
            save_pos
            ;;
        answer)
            message=" ${INFO_COLOR}${message}
"
            restore_pos
            _print_message
            ;;
        done|succ*)
            level="${SUCCESS_COLOR}[done] "
            icon="${SUCCESS_COLOR}√"
            message="${message}
"
            _print_message
            ;;
        heading)
            echo
            icon="${3:-§}"
            message=$"${BOLD}${message}
"
            _print_message
            ;;
        subheading)
            message=" ${DIM}${message}
"
            _print_message
            ;;
        suggestion)
            message=" ${BOLD}${SUCCESS_COLOR}${message}
"
            _print_message
            ;;
        wait)
            shift
            _wait "$@"
            ;;
        select-from)
            shift
            _select_option "$@"
            ;;
        confirm)
            shift
            _confirm "$@"
            ;;
        input)
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
    esac
}