#!/usr/bin/env bash

#===============================================================================
#
#          FILE: gcp_dyndns.sh
#         USAGE: ./gcp_dyndns.sh [options]
#   DESCRIPTION: A script to enable automated updates to a record in
#                Google Cloud DNS for usage similar to DYNDNS
#       OPTIONS: -d [FQDN]
#                -t [TTL]
#                -r [RECORD TYPE]
#                -z [ZONE NAME]
#  REQUIREMENTS: dig and google cloud sdk fully authenticated
#          BUGS: they will be discovered at random times
#         NOTES:
#        AUTHOR: Cesar B. (), cesar@poa.nyc
#  ORGANIZATION: poa.nyc
#       CREATED: 2022-11-20
#      REVISION: 6
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
readonly PROGNAME=$(basename $0)
readonly PROGIDR=$(readlink -m $(dirname $0))
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

function main()
{
    readonly RED=$(tput setaf 1)
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

    if [[ -z "${NEW_ADDR}" ]]
    then
        printf "%s\n" \
            "${RED}[X] Can not get your ISP provided IP address.${CLR}"
        exit 1
    fi
}

function _CUR_ADDR()
{
    readonly CUR_ADDR=$(\
        ${DIG} \
        -4 \
        +short \
        ${DOMAIN} \
        | tr -d "\"")

    if [[ -z "${CUR_ADDR}" ]]
    then
        printf "%s\n" \
            "${RED}[X] Existing address is missing. Check your FQDN.${CLR}"
        exit 1
    fi
}

function _CHANGE_IP()
{
    if [[ $(echo ${NEW_ADDR}) != $(echo ${CUR_ADDR}) ]]
    then
        ${GCP_PATH:-$(which gcloud)}  \
            dns \
            record-sets \
            update \
            ${DOMAIN} \
            --rrdatas=${NEW_ADDR} \
            --ttl=${TTL:-300} \
            --type=${RECORD:-A} \
            --zone=${ZONE} \
            2> >(sed $'s,.*,\e[31m&\e[m,'>&2) 1> /dev/null
        if [[ $? -eq 1 ]]
        then
            exit 1
        fi
    fi
}

function _USAGE()
{
    clear
echo -e "
NAME
    ${PROGNAME}

SYNOPSIS
    ${PROGNAME} [OPTION]...

DESCRIPTION
    A script that reads your current IP address as assigned by your isp to
    enable automated updates to the A record in Google Cloud DNS for usage
    similar to DYNDNS

OPTIONS
    -d [FQDN]
            The DNS name that matches the incoming queries with this zone's
            DNS name as its suffix.
            This can be found in the second column by running :

                    gcloud dns managed-zones list

    -t [TTL]
            The TTL in seconds that the resolver caches this resource
            record set.
            This defaults to 300 (5 minutes).

    -r [resource type]
            The resource record type of this resource record set.
            This defaults to A.

    -z [zone name]
            The managed zone that this resource record set is affiliated with.
            For example, my-zone-name; the name of this resource record set
            must have the DNS name of the managed zone as its suffix.
            This can be found in the first column by running :

                    gcloud dns managed-zones list

Examples
     Update the A record for FQDN FOOBAR.BAZ with zone name EX-SET :

            ${PROGNAME} -d foobar.baz -z EX-SET

Requirement
     This script requires that the Google Cloud SDK tools are installed and
     configured in your PATH and that the command gcloud is functioning
     against your Google Cloud account with access to Google Coud DNS.

    "
}

## option selection
while getopts "d:t:r:z:" OPT
do
    case "${OPT}" in
        'd')
            ## FQDN
            DOMAIN=${OPTARG}
            ;;
        't')
            ## TTL time. This defaults to 300.
            TTL=${OPTARG}
            ;;
        'r')
            ## Record type. This defaults to A type.
            RECORD=${OPTARG}
            ;;
        'z')
            ## Google cloud dns zone name.
            ZONE=${OPTARG}
            ;;
    esac
done
if [[ ${OPTIND} -eq 1 ]]
then
    _USAGE \
        | less
    exit 0
fi
shift $((OPTIND-1))

main
if [[ -z "${DOMAIN+x}" || -z "${ZONE+x}" ]]
then
    _USAGE \
        | less
    exit 1
fi
_NEW_ADDR
_CUR_ADDR
_CHANGE_IP
