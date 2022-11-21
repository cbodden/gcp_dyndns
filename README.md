![Unsupported](https://img.shields.io/badge/development_status-in_progress-green.svg)
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

gcp_dyndns.sh
====

    A script that reads your current IP address as assigned by your isp to
    enable automated updates to the A record in Google Cloud DNS for usage
    similar to DYNDNS


Usage
----

<pre><code>
Name
    gcp_dyndns.sh

SYNOPSIS
    gcp_dyndns.sh [OPTION]...

DESCRIPTION
    A script that reads your current IP address as assigned by your isp to
    enable automated updates to the A record in Google Cloud DNS for usage
    similar to DYNDNS

OPTIONS
    -d [FQDN]
            The DNS name that matches the incoming queries with this zone's
            DNS name as its suffix.
            This can be found in the second column by running :

                    /path/to/gcloud dns managed-zones list

    -g [path to gcloud]
            The path to the gcloud command as installed by the
            Google Cloud SDK installer. If installed in path this will default
            to that location.

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

                    /path/to/gcloud dns managed-zones list

Examples
     Update the A record for FQDN FOOBAR.BAZ with zone name EX-SET using the
     installed gcloud command located at ~/google-cloud-sdk/bin :

            ./gcp-dyndns.sh -g ~/google-cloud-sdk/bin -d foobar.baz -z EX-SET

Requirement
     This script requires that the Google Cloud SDK tools are installed and
     configured and that the command gcloud is functioning against your
     Google Cloud account with access to Google Coud DNS.


</code></pre>

Requirements
----

- Google Cloud Command Line Interface (gcloud CLI) (https://cloud.google.com/cli)


License and Author
----

Copyright (c) 2022, cesar@poa.nyc
All rights reserved.

This source code is licensed under the BSD-style license
found in the LICENSE file in the root directory of this
source tree.
