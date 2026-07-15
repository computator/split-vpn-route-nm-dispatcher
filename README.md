# Introduction

This NetworkManager dispatcher allows you to add routes to send traffic over a split-tunnel VPN by hostname instead of having to specify IP addresses.

# Installation

Copy [`split-vpn-route-config.sh`](split-vpn-route-config.sh) into the NetworkManager dispatcher directory `/etc/NetworkManager/dispatcher.d/`. Make sure it's owned by `root` and marked as executable.

```sh
sudo install -m 755 split-vpn-route-config.sh /etc/NetworkManager/dispatcher.d/
```

# Usage

Add a key `add-hostname-routes` to the `ipv4` section of the `.nmconnection` file. It should contain a space separated list of hostnames to add routes for. If your system uses [Netplan](https://netplan.io/) to configure NetworkManager see the [Netplan](#netplan) section below. Also make sure to take the [limitations](#limitations) into consideration.

### NetworkManager Syntax Example

 ```
 [ipv4]
 add-hostname-routes=host1.example.com host2.example.com
 ```

## Netplan

If your system uses [Netplan](https://netplan.io/) to configure NetworkManager, then you need to set the config option in a netplan `.yaml` file instead. Add a key `ipv4.add-hostname-routes` to the `networkmanager.passthrough` section of a connection. The value is a space separated list of hostnames to add routes for.

Once you have edited the connection you can tell NetworkManager to regenerate it's configs from Netplan by calling `nmcli connection reload`. Alternatively, you can call `netplan generate` to recreate the NetworkManager config files directly, however NetworkManager's internal state will not be updated even though the config files on disk have changed.

### Netplan Syntax Example

```yaml
network:
  nm-devices:
    example-connection:
      # ...
      renderer: NetworkManager
      networkmanager:
        # ...
        passthrough:
          ipv4.add-hostname-routes: host1.example.com host2.example.com
          # ...
```
since this is yaml you can also use the wrapped block syntax:
```yaml
# ...
passthrough:
  ipv4.add-hostname-routes: >
    host1.example.com
    host2.example.com
    host3.example.com
  # ...
```

# Limitations

There are two major limitations of this both related to one-time DNS resolution:

- If a DNS record is updated and starts returning different IPs, the routes this creates will still be set to the old IPs and thus not send the traffic over the tunnel until the tunnel is restarted.
- If a DNS record returns different sets of IPs for each request (common for load balancing), then only some of the IPs will have VPN routes created for them. This will cause intermittent connection issues with only part of the traffic for a hostname being routed over the VPN depending on which IP address each connection to the host uses.

## `/etc/hosts` Workaround

These limitations can be somewhat resolved by setting static IP addresses for affected hostnames, which will give more control over which IPs are being connected to instead of being dependent on DNS. This is particulary effective for the second limitation with load-balanced hostnames.

To do so, use `dig` or another utility to look up the IPs corresponding to a hostname, and then put those IPs in your `/etc/hosts` file.

### Example of looking up IPs for a hostname

```sh
$ dig +short host1.example.com
198.51.100.27
198.51.100.54
```

### Example IPs in `/etc/hosts`

```
...
198.51.100.27 host1.example.com
198.51.100.54 host1.example.com
```
