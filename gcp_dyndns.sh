#!/usr/bin/env bash

#===============================================================================
#
#          FILE: gcp_dyndns.sh
#         USAGE: ./gcp_dyndns.sh [options]
#   DESCRIPTION: A script to enable automated updates to a record in
#                Google Cloud DNS for usage similar to DYNDNS
#       OPTIONS:
#  REQUIREMENTS: dig and google cloud sdk fully authenticated
#          BUGS: they will be discovered at random times
#         NOTES:
#        AUTHOR: Cesar B. (), cesar@poa.nyc
#  ORGANIZATION: poa.nyc
#       CREATED: 2022-11-20
#      REVISION: 1
#       LICENSE: Copyright (c) 2022, cesar@poa.nyc
#                All rights reserved.
#
#                This source code is licensed under the BSD-style license
#                found in the LICENSE file in the root directory of this
#                source tree.
#
#===============================================================================

LC_ALL=C
LANG=C
set -e
set -o nounset
set -o pipefail
set -u
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

function main()
{
    readonly GCLOUD_PATH="/home/cbodden/google-cloud-sdk/bin"
    readonly RED=$(tput setaf 1)
    readonly BLU=$(tput setaf 4)
    readonly GRN=$(tput setaf 40)
    readonly CLR=$(tput sgr0)

    local _DEPS="dig"
    for ITER in ${_DEPS}
    do
        if [ -z "$(which ${ITER} 2>/dev/null)" ]
        then
            printf "%s\n" \
                "${RED}. . .${ITER} not found. . .${CLR}"
            exit 1
        else
            readonly ${ITER^^}="$(which ${ITER})"
        fi
    done

    readonly NAME=$(basename $0)
}

function _NEW_ADDR()
{
    readonly NEW_ADDR=$(\
        ${DIG} \
        -4 \
        TXT \
        +short \
        o-o.myaddr.l.google.com \
        @ns1.google.com \
        | tr -d "\"")
}

function _CUR_ADDR()
{
    readonly CUR_ADDR=$(\
        ${GCLOUD_PATH}/gcloud  \
        dns \
        record-sets \
        list \
        --zone=${ZONE} \
        | awk '/ A / {print $4}')
}

function _CHANGE_IP()
{
    if [[ ${NEW_ADDR} != ${CUR_ADDR} ]]
    then
        ${GCLOUD_PATH}/gcloud  \
            dns \
            record-sets \
            update \
            ${DOMAIN} \
            --rrdatas=${NEW_ADDR} \
            --ttl=${TTL:-300} \
            --type=${RECORD:-A} \
            --zone=${ZONE} \
            &> /dev/null
    fi
}

## option selection
while getopts "d:D:t:T:r:R:z:Z:" OPT
do
    case "${OPT}" in
        'd'|'D')
            DOMAIN=${OPTARG}
            ;;
        't'|'T')
            TTL=${OPTARG}
            ;;
        'r'|'R')
            RECORD=${OPTARG}
            ;;
        'z'|'Z')
            ZONE=${OPTARG}
            ;;
        *)
            echo "no options given"
            exit 0
            ;;
    esac
done
if [[ ${OPTIND} -eq 1 ]]
then
    echo "no options given"
    exit 0
fi
shift $((OPTIND-1))

main
if [[ -z "${DOMAIN+x}" || -z "${ZONE+x}" ]]
then
    echo "both domain (-d,-D) and zone (-z,-Z) must be set"
    exit 1
fi
_NEW_ADDR
_CUR_ADDR
_CHANGE_IP
