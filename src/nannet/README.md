# NANNET — system network manager (M1/M2)

NANNET is the network control plane, separate from private tooling. It owns link,
address, route, DNS, driver-load and WiFi state. All logic is NaN16; the
sources assemble with the normal `tools/nmk.awk` pipeline.

## Source

- `nannet.nas` — implementation (direct-call library).
- `nannet_test.nas` — config apply / rollback / listings.
- `link_test.nas` — state, bounds, longest-prefix lookup.
- `wifi_test.nas` — scan/join/leave state machine.
- `system.nancfg` — sample control-plane config.

## ABI

`r1..r5` arguments, `r1/r2` results, `r3` status:
`0 ok, 1 EINVAL, 2 ENOENT, 3 ENOSPC, 4 EOVERFLOW, 5 EPROTO, 7 EPERM`.

```
nn_link_list / nn_link_set / nn_link_up / nn_link_down
nn_addr_add / nn_addr_del / nn_addr_list
nn_route_add / nn_route_del / nn_route_list / nn_route_lookup
nn_dns_add / nn_dns_list
nn_wifi_scan / nn_wifi_join / nn_wifi_leave / nn_wifi_list
nn_cfg_apply / nn_cfg_rollback / nn_cfg_status
nn_status
```

Config apply snapshots interfaces, addresses, routes, DNS, WiFi joined state
and driver load states; it restores the snapshot on any error. Rollback
restores the snapshot from the last apply.

## Config grammar (M1/M2)

Keywords are matched by first letter; numbers are decimal or `0x`. Addresses
are 16-bit with prefix 0..16 in this world.

```
link 0 1
link 1 1
addr 1 0x0A00 16
route 0x0000 0 0x0A01 1 1
dns 0x0A01
driver 9 1
wscan 2
wjoin 2 0
wleave 2
```

`dns` and `driver` are distinguished by the second letter. Interface, SSID
and driver names are a later layer; the numeric ids are stable.

## WiFi

States: down -> scanning -> joining -> joined/failed. Until a radio driver
exists, scan/join run against a deterministic fixture (HomeNet 60, Cafe 42,
Lab 30) so the state machine and config verbs are exercised for real.

## Gates

```
sh tools/nannet_gate.sh        # apply, lists, lookup, rollback, restore
sh tools/nannet_link_gate.sh   # state, bounds, addr, longest-prefix, DNS
sh tools/nannet_wifi_gate.sh   # scan/join/leave, fixtures, config round-trip
```

Next: pack the manager as a slot-less service cart and surface it from the
system menu/terminal.
