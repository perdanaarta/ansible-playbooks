#!/bin/bash

set -e

inventory_file=0
host=""
playbook_option=""
yes=false

function stdout() {
    d=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$d] <out>" "$@"
}

function stderr() {
    d=$(date +'%Y-%m-%d %H:%M:%S')
    echo >&2 "[$d] <err>" "$@"
}

function help() {
    echo "Usage: script_name -i <inventory_file> -h <host> [-p <playbook_name(s)>]"
    echo "Options:"
    echo "  -i <inventory_file>: Specify inventory file"
    echo "  -h <host>: Specify host"
    echo "  -p <playbook_name(s)>: Specify playbook(s) to run (comma-separated without spaces)"
    echo "  -y yes: Skip inventory file and host prompt"
}

while getopts ":i:h:p:y:" option; do
    case $option in
    i)
        inventory_file=$OPTARG
        ;;
    h)
        host=$OPTARG
        ;;
    p)
        playbook_option=$OPTARG
        ;;
    y)
        yes=true
        ;;
    *)
        help
        exit 1
        ;;
    esac
done

if [ -z "$inventory_file" ] || [ -z "$host" ]; then
    echo "Options -i (inventory file) and -h (host) are required"
    help
    exit 1
fi

order=(
    "playbooks/uptime-kuma/main.yml"
)

if [ "$yes" == false ]; then
    echo "Enter inventory file ($inventory_file): "
    read -r inventory_file_prompt
    if [ "$inventory_file_prompt" != "$inventory_file" ]; then
        echo "Inventory file entered \"$inventory_file_prompt\" does not match with inventory option \"$inventory_file\""
        exit 1
    fi

    echo "Enter host ($host): "
    read -r host_prompt
    if [ "$host_prompt" != "$host" ]; then
        echo "Host entered \"$host_prompt\" does not match with inventory option \"$host\""
        exit 1
    fi
fi

script_dir=$(dirname "$0")

IFS=',' read -ra playbooks_incl <<<"$playbook_option"
for i in "${order[@]}"; do
    if [[ -z "$playbook_option" ]] || [[ "${playbooks_incl[*]}" =~ $i ]]; then
        ansible-playbook "$script_dir/$i" -i "$inventory_file" -e "variable_host=$host" -e "app_name=botmaster-platform-sso-onebasket"
    fi
done
