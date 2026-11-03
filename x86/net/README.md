# x86 host-backed network

The x86 image can use QEMU's user-mode network through an ISA NE2000. That path
carries the **host's active connection** — WiFi or wired — so the guest gets
real connectivity without owning a radio. A virtual machine cannot own a WiFi
radio without hardware passthrough; bridging the host is the correct model.

`ne2k_probe.nas` is the driver prototype and acceptance probe:

- initializes the NE2000 at I/O base 0x300 (polled, no IRQ);
- sends an ARP request for the user-net gateway 10.0.2.2 from 10.0.2.15;
- verifies the ARP reply (ethertype, opcode, sender IP).

Run it with:

```
sh x86/tools/netgate.sh
```

The gate builds a temporary image whose boot cart is the probe, boots it under
`qemu-system-i386` with `-netdev user` + `ne2k_isa`, and requires `NET PASS`.

Next: DHCP/ICMP/UDP on top of this driver, bind it to the NANNET `eth0` link,
then add a real-hardware PCI NIC path. Android WiFi is a separate host bridge
(WifiManager scan/join + VpnService or datagram service) — see the roadmap.
