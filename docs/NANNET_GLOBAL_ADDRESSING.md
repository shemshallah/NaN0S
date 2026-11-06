# NANNET global mesh addressing and N16T routing

## Canonical address

A NaN endpoint has a stable logical address independent of its IP address,
DNS name, carrier, or transport:

```text
nan://GM0:SC0:MC0:BS0:HW0
```

The five decimal coordinates are each 0..255:

- GM: global mesh
- SC: supercluster
- MC: macrocluster
- BS: bootstrap universe
- HW: hardware endpoint within that bootstrap universe

Initial assignments in GM0/SC0/MC0/BS0:

| HW | Endpoint | Existing local node point |
|---:|---|---:|
| 0 | NaNLMind six-runner GitHub runner ring | 1 |
| 1 | Android / NaNLMind_android | 2 |
| 2 | Hermes | 3 |
| 3 | Clocked | 4 |

HWn maps to local overbootstrap node point n+1. This preserves the existing
NaN16 `ob_point_to_page` interface, which accepts local points 1..256.
The global address is the identity; the local point is only a slot index.
Different bootstrap/supercluster/macrocluster domains may reuse local point 1.

Clocked remains HW3 for now. It may later participate in a macrocluster or
cooperative corpus process with Android and Hermes without changing its
historical endpoint identity.

## Transport and authority

The Koyeb NANNET HTTPS origin is a replaceable transport ingress. It is not the
NaN address and must not be encoded as a fixed IPv4 address. A bearer token is
issued by NANNET and cryptographically bound to one canonical NaN address.
Clients may send `X-NaN-Address` as a consistency claim; NANNET rejects a
claim that differs from the token-bound address. The address alone is never
authentication.

```text
HTTPS request to Koyeb NANNET
  + endpoint bearer token
  + optional X-NaN-Address: nan://GM0:SC0:MC0:BS0:HW1
  -> authenticated logical address
  -> route/capability lookup
  -> local node point 2
  -> NaN16 guest routing and N16T peer
```

## N16T compatibility boundary

N16T remains the guest-owned frame/session protocol. Its CRC, replay sequence,
session transition, and control-message semantics stay in NaN16. NANNET only
authenticates the HTTPS caller, binds its address, applies route policy, and
relays opaque N16T frames to a configured trusted peer.

The current NaN16 frame route payload still carries the existing 16-bit local
node point. It must not be misrepresented as carrying the full five-coordinate
global address. Until a versioned NaN16 address envelope is implemented, the
authenticated NANNET session supplies the global address and translates it to
the local node point. A future wire extension must be versioned and tested
without changing the v1 payload interpretation.

## Routing invariants

1. Never trust a client-supplied address without checking its bearer binding.
2. Never use IP/DNS address as the endpoint's logical identity.
3. Keep GM/SC/MC/BS/HW as separate coordinates.
4. Keep global address separate from local 1..256 overbootstrap point.
5. Keep endpoint intake evidence-only; only the independent validator can
   approve corpus data, and only the canonical runner can commit learning.
6. Clocked may be a cooperative corpus participant now; macrocluster promotion
   is a later topology operation, not a credential shortcut.
