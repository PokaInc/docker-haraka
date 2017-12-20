#!/bin/bash

set -e


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

# extract and export AWS region based on the SNS topic ARN
extract_and_export_region() {
    export AWS_REGION=`echo $BOUNCES_SNS_TOPIC_ARN | sed -e 's/arn:aws:sns:\(.*\):[[:digit:]]\{12\}:.*/\1/'`

    if test "x$AWS_REGION" = "x";then
        echo "AWS_REGION was not properly extracted from BOUNCES_SNS_TOPIC_ARN." 1>&2

        return 1
    fi

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

    if test "x$BOUNCES_SNS_TOPIC_ARN" = "x";then
        echo "BOUNCES_SNS_TOPIC_ARN has not been set." 1>&2

        return 1
    fi

    return 0
}

exec_haraka() {
    validate_haraka_env || exit 1
    extract_and_export_region || exit 2
    create_dkim_private_key || exit 3
    write_log_level || exit 4

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
