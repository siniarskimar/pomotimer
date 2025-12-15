#!/bin/env bash

_basedir="$(dirname $0)"

session_length=55
session_short_break_length=5
session_long_break_length=10

usage() {
  echo 'pomotimer.sh [-h] [-t minutes] [-b minutes] [-B minutes]'
}

showHelp() {
  _msg="Usage: $(usage)
Options:
  -h    Show this help message

  -t    Specify the work period (default: $session_length minutes)

  -b    Specify the small break period (default: $session_short_break_length minutes)

  -B    Specify the big break period (default: $session_long_break_length minutes)
  "
  echo "$_msg"
}


while getopts ":ht:b:B:" arg ; do
  case $arg in
    t)
      if [ -z "${OPTARG##*[!0-9]*}" ]; then
        echo "err: -t value must be a number"
        exit 1
      fi

      session_length=$OPTARG
      ;;
    b)
      if [ -z "${OPTARG##*[!0-9]*}" ]; then
        echo "err: -b value must be a number"
        exit 1
      fi

      session_short_break_length=$OPTARG
      ;;

    B)
      if [ -z "${OPTARG##*[!0-9]*}" ]; then
        echo "err: -B value must be a number"
        exit 1
      fi

      session_long_break_length=$OPTARG
      ;;
    h | *)
    showHelp
    exit 0
     ;;
  esac
done

session_counter=1

notify() {
  notify-send -a 'pomotimer.sh' -e "$@"
}

notify_sound() {
  ffplay -v 0 -nodisp -autoexit "$_basedir/ding-246413.mp3" 2>&1 >/dev/null &
}

while true; do
   notify \
    "Time for $session_length minute work session!"
  
  sleep "$(($session_length * 60))"

  notify_sound
  resp=$(notify \
    -u critical \
    -t 0 \
    -A 'stop=End timer' \
    -A 'break=Take a break' \
    "Time is up, maybe take a break?" \
    )

  case "$resp" in
    "stop")
      break
      ;;
    "break")
      break_length=$session_short_break_length

      if [[ $(($session_counter % 3)) -eq 0 ]]; then
        break_length=$session_long_break_length
      fi
      
      notify "Enjoy your $break_length minute break!"

      sleep $(($break_length * 60))
      ;;
    *)
      echo "err: invalid notification response"
      break
      ;;
  esac

  notify_sound
  resp=$(notify \
    -u critical \
    -t 0 \
    -A "yes=Yes" \
    -A "no=No (stops timer)" \
    "Ready for the next work session?" \
  )

  case "$resp" in
    "yes")
      ;;
    "no")
      break
      ;;
    *)
      echo "err: invalid notification response"
      break
      ;;
  esac

  session_counter=$(($session_counter + 1))
done
