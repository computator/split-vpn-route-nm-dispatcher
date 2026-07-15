#!/bin/sh
set -eu

# only handle vpn-up actions
[ ${NM_DISPATCHER_ACTION=} = 'vpn-up' ] || exit 0

hostnames=$(
    # parse CONNECTION_FILENAME manually to get ipv4.add-hostname-routes value
	awk '
	    BEGIN {
	        sect="[ipv4]"
			FS="="
		}

		$0 == sect,$0 != sect && /^\[/ {
		    if ($1 == "add-hostname-routes") {
				print $2
			}
		}
	' "${CONNECTION_FILENAME}"
)
echo "${0}: ipv4.add-hostname-routes: '${hostnames}'"

# only run if hostnames were set
[ ${hostnames:+1} ] || exit 0

echo ${hostnames} | xargs -n 1 | dig +short -f - | grep -v '\.$' | sort -u | {
	while read ip_addr; do
		# exit if interface is gone
		[ "$(cat "/sys/class/net/${VPN_IP_IFACE}/carrier")" -eq 1 ] || exit 0

		ip route replace "${ip_addr}" ${VPN_IP4_GATEWAY+via "${VPN_IP4_GATEWAY}"} dev "${VPN_IP_IFACE}"
	done
}
