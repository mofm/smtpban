#!/usr/bin/env bash

# This script parse and block IP addresses from postfix log file
# which are trying to brute force SMTP AUTH login.
# It will block IP addresses with more than n failed attempts
# in last n minutes.

script_dir="$HOME/smtpban"
blocked="blocked_ips"
logfile="/var/log/mail.log"
git_remote=""


die() {
    echo "[ERROR] $1" >&2
    echo "$USAGE" >&2 # To be filled by the caller.
    # Kill the caller.
    if [ -n "$TOP_PID" ]; then kill -s TERM "$TOP_PID"; else exit 1; fi
}

pushd_quiet() {
    pushd "$1" &>/dev/null || die "Failed to enter $1."
}

popd_quiet() {
    popd &>/dev/null || die "Failed to exit directory."
}

# Check if log file exists and is readable
if [ ! -f "$logfile" ] || [ ! -r "$logfile" ]; then
    die "$logfile does not exist or is not readable"
fi

# Check if git is installed
if ! command -v git &> /dev/null
then
    die "git could not be found"
fi

# Check if script directory exists
if [ ! -d "$script_dir" ]; then
    echo "Creating $script_dir"
    mkdir -p "$script_dir"
fi

pushd_quiet "$script_dir"

## Check if git repo is initialized
if [ ! -d .git ]; then
    echo "Initializing git repo"
    git init
    git remote add origin $git_remote
fi

# Get blocked IP addresses
git pull origin main

# Get logs in last n minutes
# PARSE_MINS is last n minutes to parse
# should be set to this variable in crontab
# e.g. 5 * * * * PARSE_MINS="30 minutes ago" /path/to/smtpban.sh
parsed_logs=$(mktemp)
awk -F - -vDT="$(date --date="$PARSE_MINS" "+%b %_d %H:%M:%S")" ' DT < $1' $logfile > $parsed_logs

# Get IP addresses with more than n failed attempts from last n minutes
# PARSE_COUNTS is number of failed attempts
# should be set to this variable in crontab
# e.g. 5 * * * * PARSE_COUNTS="3" /path/to/smtpban.sh
parsed_ips=$(mktemp)
cat $parsed_logs | grep -E 'authentication failed|too many errors after AUTH'| grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sort | uniq -c | awk -v limit="$PARSE_COUNTS" '$1 > limit{print $2}' > $parsed_ips

# Merge and sort blocked IP addresses
blocked_ips=$(mktemp)
sort -u $blocked $parsed_ips > $blocked.tmp
mv $blocked.tmp $blocked

# git push
git add $blocked
git commit -m "Update blocked IP addresses $(date +%Y%m%d%H%M%S)"

# Push to remote repo
if [ -n "$git_remote" ]; then
    git push -u origin main
fi

# Remove temp files
rm $parsed_logs $parsed_ips

popd_quiet

