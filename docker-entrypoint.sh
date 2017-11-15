#!/bin/bash

set -e

# change the ownership of the haraka persistence volumes.
# @param $1 {String} chown ownership rule
haraka_chown() {
    chown -R "$1" "$HARAKA_DATA"
}

# change the permission flags of the haraka persistence volumes.
# @param $1 {String} chmod permission flags
haraka_chmod() {
    chmod "$1" "$HARAKA_DATA"
}


# perform pre-boot actions before the SMTP server starts.
haraka_bootstrap() {
    if test "x$DOCKER_VOLUMES_CHOWN" != "x";then
        haraka_chown "$DOCKER_VOLUMES_CHOWN" || return 1
    fi

    if test "x$DOCKER_VOLUMES_CHMOD" != "x";then
        haraka_chmod "$DOCKER_VOLUMES_CHMOD" || return 1
    fi

    return 0
}

write_log_level() {
    echo ${LOG_LEVEL:NOTICE} > /app/config/loglevel
    return 0
}

# create dkim key and Route53 record
create_dkim_private_key() {
    # create a directory for each DKIM signing domain
    mkdir -p "/app/config/dkim/$DOMAIN"
    pushd "/app/config/dkim/$DOMAIN"

    date '+%s' > selector

    openssl genrsa -out private 1024
    chmod 400 private
    openssl rsa -in private -out public -pubout
    
    export DKIM_RECORD_NAME="$(tr -d "\n" < selector)._domainkey.$DOMAIN"
    export DKIM_RECORD_VALUE="v=DKIM1;p=$(grep -v -e '^-' public | tr -d "\n")"

    popd

    return 0
}

# ensure the environment has been set up correctly.
# @return {Number} a value greater than zero if anything is not OK
validate_haraka_env() {
    if test "x$DOMAIN" = "x";then
        echo "DOMAIN has not been set." 1>&2

        return 1
    fi

    if test "x$HOSTED_ZONE_ID" = "x";then
        echo "HOSTED_ZONE_ID has not been set." 1>&2

        return 1
    fi

    if test "x$AWS_REGION" = "x";then
        echo "AWS_REGION has not been set." 1>&2

        return 1
    fi

    if test "x$BOUNCES_SNS_TOPIC_ARN" = "x";then
        echo "BOUNCES_SNS_TOPIC_ARN has not been set." 1>&2

        return 1
    fi

    if test "x$HARAKA_LOGS" = "x";then
        echo "Haraka logs directory has not been set." 1>&2

        return 1
    fi

    if test "x$HARAKA_DATA" = "x";then
        echo "Haraka data directory has not been set." 1>&2

        return 1
    fi

    return 0
}


exec_haraka() {
    validate_haraka_env || exit 1
    create_dkim_private_key || exit 2
    write_log_level || exit 3
    haraka_bootstrap || exit 4

    exec "$@" 2>&1
}

exec_help() {
    echo "Either run this command without any parameters to execute"
    echo "Haraka or specify the command which should be invoked."

    exit 0
}

# script entry point
main() {
    echo "$@"
    case "${1:-haraka}" in
        [hH]araka)
            exec_haraka "$@"
            ;;
        --help|-h|-?)
            exec_help
            ;;
        *)
            exec "$@"
            ;;
    esac
}

main "$@"

