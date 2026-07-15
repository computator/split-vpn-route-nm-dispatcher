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

echo "${0}: VPN_IP4_GATEWAY: '${VPN_IP4_GATEWAY}'"
echo "${0}: VPN_IP_IFACE: '${VPN_IP_IFACE}'"

if [ "${VPN_IP4_GATEWAY}" = '0.0.0.0' ]; then
    echo "${0}: warning: VPN_IP4_GATEWAY is invalid!"
    VPN_IP4_GATEWAY=$(
        ip route list dev "${VPN_IP_IFACE}" | \
        grep -Eom 1 '\bvia ([0-9]+\.){3}[0-9]+\b' | \
        awk '{ print $2 }'
    )
    [ -n "${VPN_IP4_GATEWAY}" ] && \
        echo "${0}: detected alternate gateway address: '${VPN_IP4_GATEWAY}'"
fi

echo ${hostnames} | xargs -n 1 | dig +short -f - | grep -v '\.$' | sort -u | {
	while read ip_addr; do
		# exit if interface is gone
		[ "$(cat "/sys/class/net/${VPN_IP_IFACE}/carrier")" -eq 1 ] || exit 0

		ip route replace "${ip_addr}" ${VPN_IP4_GATEWAY:+via "${VPN_IP4_GATEWAY}"} dev "${VPN_IP_IFACE}"
	done
}
