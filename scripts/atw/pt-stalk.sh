#!/bin/bash

declare PTDEST="$(pwd)/$(hostname)"
declare PID="$PTDEST/pt-stalk.pid"
declare LOG="$PTDEST/pt-stalk.log"
declare ITERATIONS=2
declare SLEEP=30
declare IS_DAEMON=0
declare ACTION="start"

usage() {
   cat << EOS
Usage: $(basename "${0}") [OPTIONS]
Executes pt-stalk or stops the daemon

Command line options:

   --pid                   pt-stalk PID file
   --log                   pt-stalk log file
   -d, --dest              Destination for the summaries. 
                           Default: .$(pwd)/$(hostname)
   --iterations            How many iterations to run
   --sleep                 Sleep time between iterations
   --daemon                Run pt-stalk in daemon mode
   --action=[start|stop]   Start or stop pt-stalk. Compresses data when stopped.
                           Default: start

EOS
   exit
}

compress_data() {
   tar czf "${PTDEST}.tar.gz" -C "$(dirname ${PTDEST})" "$(basename ${PTDEST})";
}

OPTS=$(getopt --options -s:d:h --longoptions 'pid:,log:,dest:,iterations:,sleep:i,action:,daemon,help' -- "$@")

eval set -- "$OPTS"

while [[ -n "$*" ]]; do
   case "$1" in
      --pid)
         PID="$2"
         shift 2
         ;;
      --log)
         LOG="$2"
         shift 2
         ;;
      -d | --dest)
         PTDEST="$2"
         shift 2
         ;;
      --iterations)
         ITERATIONS="$2"
         shift 2
         ;;
      --sleep)
         SLEEP="$2"
         shift 2
         ;;
      --daemon)
         IS_DAEMON=1
         shift 1
         ;;
      --action)
         ACTION="$2"
         shift 2
         ;;
      -h | --help)
         usage
         ;;
      --)
         shift 1
         break
         ;;
      *)
         echo "Unrecognized option '$1'"
         usage
         ;;
   esac
done

echo $@

case "$ACTION" in
   start)
      mkdir -p "${PTDEST}"
      if [ $IS_DAEMON -eq 1 ]; then
         sudo pt-stalk --daemonize --iterations=$ITERATIONS --sleep=$SLEEP --dest="${PTDEST}" --pid="${PID}" --log="${LOG}" "$@"
      else
         sudo pt-stalk --no-stalk --iterations=$ITERATIONS --sleep=$SLEEP --dest="${PTDEST}" --pid="${PID}" --log="${LOG}" "$@"
         compress_data
      fi
      ;;
   stop)
      sudo kill `cat ${PID}`
      compress_data
      ;;
   *)
      echo "Unrecognized action '$1'"
      usage
      ;;
esac

