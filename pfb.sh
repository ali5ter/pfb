#!/usr/bin/env bash
# @file pfg.sh
# Pretty feedback (pfb) untilty functions
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
# @ref https://github.com/dylanaraps/writing-a-tui-in-bash
# @ref https://www2.ccs.neu.edu/research/gpc/VonaUtils/vona/terminal/vtansi.htm
# @ref https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu

[[ -z $VERBOSE ]] && VERBOSE=false

PFB_DEFAULT_LOG_DIR="${HOME}/logs"
PFB_DEFAULT_LOG="scripts"

 # Variables for ANSI codes
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
    return 0
}

# Print pretty feedback
# @param message type
# @param message string
# @param message
pfb() {
    local mtype message level icon

    mtype="${1}"
    message="${2}"
    level=''
    icon=' '

    case "$mtype" in
        info*)
            level="${CYAN}[info] "
            message="${message}
"
            ;;
        warn*)
            level="${YELLOW}[warn] "
            message="${message}
"
            ;;
        err*)
            level="${RED}[fatal]"
            message="${message}
"
            ;;
        prompt)
            icon="${GREEN}?"
            message="${BOLD}$message"
            ;;
        answer)
            message=" ${CYAN}${message}
"
            ;;
        done|succ*)
            level="${GREEN}[done] "
            icon="${GREEN}√"
            message="${message}
"
            ;;
        subheading)
            message=" ${DIM}${message}
"
            ;;
        heading)
            echo
            icon="${3:-§}"
            message=$"${BOLD}${message}
"
            ;;
    esac
    # TODO: Consider using logger for datestamping and redirection to syslog
    printf "${BOLD}%s${RESET}${BOLD}%s${RESET} %s${RESET}" "$level" "$icon" "$message"
}

# Print pretty spinner prompt
# @param message to show
# @param command to be performed
pfb_wait() {
    local message spinner step logfile pid 

    message="$1" && shift
    command="$*"
    spinner="/-\|"
    step=1
    ESC=$(printf "\033")
    # shellcheck disable=SC2059
    cursor_blink_on()  { printf "${ESC}[?25h"; }
    # shellcheck disable=SC2059
    cursor_blink_off() { printf "${ESC}[?25l"; }
    # shellcheck disable=SC2059
    cursor_up()     { printf "${ESC}[A"; }
    # shellcheck disable=SC2059
    erase_line()    { printf "${ESC}[2K"; }
    # shellcheck disable=SC2059
    save_pos()      { printf "${ESC}7"; }
    # shellcheck disable=SC2059
    restore_pos()   { printf "${ESC}8"; }

    _set_ansi_vars
    [ -d "$PFB_DEFAULT_LOG_DIR" ] || mkdir -p "$PFB_DEFAULT_LOG_DIR"
    logfile="${PFB_DEFAULT_LOG_DIR}/${PFB_DEFAULT_LOG}.log"

    echo -e "\n\$ $command" >>"$logfile"
    eval "$command" >>"$logfile" 2>&1 &
    pid=$!
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2

    cursor_blink_off
    cursor_up   # because job control message was printed
    # shellcheck disable=SC2009
    while ps | grep -v grep | grep -q "$pid"; do
        save_pos
        erase_line
        # shellcheck disable=SC2059
        printf "${BOLD}${CYAN}[wait]${RESET} ${BOLD}${spinner:step++%${#spinner}:1}${RESET} ${message}${RESET}"
        restore_pos
        sleep 0.08
    done
    cursor_up   # because job control message was printed
    erase_line  # so a success message can replace the wait message
    cursor_blink_on
}

# Print pretty selection prompt for list of options
# @param options array of options to select from
# @return selected index of option in the given array
pfb_select_option() {
    local message options i last_row start_row selected
    options=("$@")
    
    _set_ansi_vars

    ESC=$(printf "\033")
    # shellcheck disable=SC2059
    cursor_blink_on()  { printf "${ESC}[?25h"; }
    # shellcheck disable=SC2059
    cursor_blink_off() { printf "${ESC}[?25l"; }
    # shellcheck disable=SC2059
    cursor_to()        { printf "${ESC}[$1;${2:-1}H"; }
    # shellcheck disable=SC2059
    erase_down()        { printf "${ESC}[J"; }
    # shellcheck disable=SC2059
    print_option()     { printf "  $1\n"; }
    # shellcheck disable=SC2059
    print_selected()   { printf "${BOLD}${CYAN}> $1${RESET}\n"; }
    # shellcheck disable=SC2034
    get_cursor_row()   { IFS=';' read -srdR -p $'\E[6n' ROW COL; echo "${ROW#*[}"; }
    key_input()        { 
        read -rs -n3 key 2>/dev/null >&2
        if [[ $key = ${ESC}[A ]]; then echo 'up';    fi
        if [[ $key = ${ESC}[B ]]; then echo 'down';  fi
        if [[ $key = ''       ]]; then echo 'enter'; fi; 
    }

    # shellcheck disable=SC2059
    printf "${ESC}[s  ${CYAN}[Use arrows to move]${RESET}\n"

    for (( i=0; i<${#options[@]}; i++ )); do echo; done
    last_row="$(get_cursor_row)"
    start_row=$((last_row - ${#options[@]}))
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off
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

    # shellcheck disable=SC2059
    printf "${ESC}[u\n"
    erase_down
    cursor_blink_on

    return "$selected"
}

# Example pfb output
pfb_test() {

    PFB_DEFAULT_LOG="pfb_test"
    
    pfb heading "Log levels:"
    echo
    pfb info "There are only 24 hours in the day. Play hard, work hard."
    pfb warn "It's hard to be green! Deal with it!"
    pfb err "Going... going... gone... BOOM!"
    pfb success "That's all folks."

    sleep 2

    pfb heading "Headings:"
    echo
    pfb heading "Some wisdom from Dr. Seuss" "🐸"
    pfb subheading "Be who you are and say what you feel,"
    pfb subheading "because those who mind don't matter and,"
    pfb subheading "those who matter don't mind."

    sleep 2

    pfb heading "Long running commands:"
    echo
    pfb_wait "Having a ten second snooze..." 'sleep 10 && date'
    pfb success "Ten second snooze successful... that feels better!"

    sleep 2

    pfb heading "Prompt and answer:"
    echo
    pfb prompt "Is there only one way to do this?"
    pfb answer "Nope. Many"

    sleep 2

    pfb heading "Selection from a set of options:"
    echo
    local options=("Four in Hand Necktie" "The Seven Fold Tie" "Skinny Necktie" "Bowtie" "Western Bowtie" "Bolo Tie" "Cravat" "Neckerchief" "Nothing. Can't stand anything round my neck")
    pfb prompt "Select a particular type of tie you prefer to adorn yourself with?"
    pfb_select_option "${options[@]}"
    pfb info "You selected '${options[$?]}'"
}