#!/bin/bash

# UTILITY FUNCTIONS

export TERMINAL_COLUMNS="$(stty -a 2> /dev/null | grep -Po '(?<=columns )\d+' || echo 0)"

print_separator() {
    for ((i = 0; i < "$TERMINAL_COLUMNS"; i++)); do
        printf $1
    done
}

echo_run() {
    line_count=$(wc -l <<<$1)
    echo -n ">$(if [ ! -z ${2+x} ]; then echo "($2)"; fi)_ $(sed -e '/^[[:space:]]*$/d' <<<$1 | head -1 | xargs)"
    if (($line_count > 1)); then
        echo -n "(command truncated....)"
    fi
    echo
    if [ -z ${2+x} ]; then
        eval $1
    else
        FUNCTIONS=$(declare -pf)
        echo "$FUNCTIONS; $1" | sudo --preserve-env -H -u $2 bash
    fi
    print_separator "+"
    echo -e "\n"
}

# ACTION FUNCTIONS

install_docker() {
    echo_run "apt install docker.io docker-compose -y"
}

download_moodle_image() {
    echo_run "mkdir -p ~/docker/moodle/"
    echo_run "curl -sSL https://raw.githubusercontent.com/bitnami/containers/main/bitnami/moodle/docker-compose.yml > ~/docker/moodle/docker-compose.yml"
    echo 'nameserver 178.22.122.100' >> /etc/resolv.conf
    echo 'nameserver 185.51.200.2' >> /etc/resolv.conf
    echo_run "docker pull bitnami/moodle:latest"
}

install_moodle() {
    echo "Find these lines and change them if required:"
    echo "- '80:8080'"
    echo "- '443:8443'"
    echo "nano ~/docker/moodle/docker-compose.yml"
    echo_run "cd ~/docker/moodle/"
    echo_run "docker-compose up -d"
}

install_nginx_proxy() {
    echo_run "apt install nginx -y"
    echo_run "rm /etc/nginx/sites-{available,enabled}/default"
    echo_run "cp {default,moodle}.conf /etc/nginx/sites-available/"
    echo_run "ln -sf /etc/nginx/sites-available/{default.conf,moodle.conf} /etc/nginx/sites-enabled"
    echo_run "nginx -t"
    echo_rum "service nginx restart"
}

ACTIONS=(
    install_docker
    download_moodle_image
    install_moodle
    install_nginx_proxy
)

while true; do
    echo "Which action? $(if [ ! -z ${LAST_ACTION} ]; then echo "($LAST_ACTION)"; fi)"
    for i in "${!ACTIONS[@]}"; do
        echo -e "\t$((i + 1)). ${ACTIONS[$i]}"
    done
    read ACTION
    LAST_ACTION=$ACTION
    print_separator "-"
    $ACTION
    print_separator "-"
done
