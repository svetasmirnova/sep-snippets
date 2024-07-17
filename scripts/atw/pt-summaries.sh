#!/bin/bash

declare SERVICE="system-only"
declare PTDEST="$(pwd)/$(hostname)-$(date +%g-%m-%d-%H-%M-%S)"

usage() {
   cat << EOS
Usage: $(basename "${0}") [OPTIONS]
Executes pt-summary scripts

Command line options:

   -s,               Service to collect summaries for. Default: system-only.
      --service=[mysql|mongodb|postgresql|system-only]
   -d, --dest        Destination for the summaries. Default: .$(pwd)/$(hostname)

EOS
   exit
}

OPTS=$(getopt --options -s:d:h --longoptions 'service:,dest:,help' -- "$@")

eval set -- "$OPTS"

while [[ -n "$*" ]]; do
   case "$1" in
      -s | --service)
         SERVICE="$2"
         shift 2
         ;;
      -d | --dest)
         PTDEST="$2"
         shift 2
         ;;
      -h | --help)
         usage
         ;;
      --)
         break
         ;;
      *)
         echo "Unrecognized option '$1'"
         usage
         ;;
   esac
done

mkdir -p "${PTDEST}"
sudo pt-summary > "${PTDEST}/pt-summary.out"
sudo sysctl -a > $PTDEST/sysctl;
sudo dmesg >  $PTDEST/dmesg;
sudo dmesg -T >  $PTDEST/dmesg_t;
sudo sh -c "ulimit -a" > $PTDEST/ulimit_a;
sudo numactl --hardware  >  $PTDEST/numactl-hardware;

# IO related
sudo blockdev --report > "${PTDEST}/blockdev_report";
sudo lsblk --all > "${PTDEST}/lsblk-all";
sudo dmsetup info -c -o name,blkdevname,devnos_used,blkdevs_used > "${PTDEST}/dmsetup-info";
df -h > "${PTDEST}/df";
smartctl --scan |awk '{print $1}'|while read device; do { sudo smartctl --xall "${device}"; } done > "${PTDEST}/smartctl";
sudo multipath -ll > "${PTDEST}/multipath_ll";

# lv/pv/vg only for systems with LVM
sudo lvdisplay --all --maps > "${PTDEST}/lvdisplau-all-maps";
sudo pvdisplay --maps > "${PTDEST}/pvdisplay-maps";
sudo pvs -v > "${PTDEST}/pvs_v";
sudo vgdisplay > "${PTDEST}/vgdisplay";

# nfsstat for systems with NFS mounts
sudo nfsstat -m > "${PTDEST}/nfsstat_m";
sudo nfsiostat 1 120 > "${PTDEST}/nfsiostat";

case "$SERVICE" in
   mysql)
      mkdir -p "${PTDEST}/samples"
      sudo pt-mysql-summary --save-samples="${PTDEST}/samples" > "${PTDEST}/pt-mysql-summary.out"
      sudo cat /proc/$(pidof mysqld)/limits >"${PTDEST}/proc_mysql_limits"
      ;;
   mongodb)
      sudo pt-mongodb-summary > "${PTDEST}/pt-mongodb-summary.out"
      ;;
   postgresql)
      curl https://raw.githubusercontent.com/percona/support-snippets/master/postgresql/pg_gather/gather.sql 2>/dev/null | psql -X -f - > "${PTDEST}/pg_gather.out"
      ;;
   system-only)
      ;;
esac

tar czf "${PTDEST}.tar.gz" -C "$(dirname ${PTDEST})" "$(basename ${PTDEST})";
