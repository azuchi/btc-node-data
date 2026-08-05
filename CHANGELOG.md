# CHANGELOG

History of changes to parameters that affect the measurement methodology.
**Always record them with dates.**
(Also machine-detectable via the `params_hash` of each snapshot.)

## 2026-08-03 — onion timeouts raised from 30 s to 90 s

- **Methodology change — the onion `params_hash` changes on this date.** Onion
  counts step up again and are not directly comparable across this date.
- A controlled re-probe settled why 98% of onion probes timed out. Taking 500
  addresses that had just timed out and re-probing them without contention
  (10 concurrent, 120 s) resolved almost all of them: **49% completed a
  handshake**, a further 44% returned a definite "unreachable"/"refused", and
  only 0.8% timed out again. The addresses were not dead — 30 s simply cut the
  probes off before Tor could finish building a rendezvous circuit.
- Timeouts are therefore 90 s (concurrency unchanged at 90). The first round under
  the new parameters (2026-08-04, 23,416 candidates) confirmed the diagnosis:
  **timeouts fell from 98% to 29% of probes, and the reachable count went from 691
  to 7,935.** The round took 2h54m rather than the 6h a fully saturated crawl would
  imply, because most probes now resolve one way or the other before the limit.
- The published onion figure is still a lower bound — 29% of probes remain
  unresolved — but a far less severe one than before this date.

## 2026-07-31 — onion measurement capacity: 1 → 3 Tor daemons

- **Methodology change — the onion `params_hash` changes on this date.** Onion
  counts before and after are not directly comparable.
- Probes are now spread round-robin across three dedicated Tor daemons
  (concurrency 50 → 90). A single daemon's circuit-building queue, not the
  network, was the limit: reachable onion nodes went from ~190 to ~320 and the
  crawl finished in 2h instead of 3h15m.
- Even so, 98% of onion probes still end in `timeout`, so **onion counts remain a
  capacity-limited lower bound** — they describe what our Tor capacity can
  confirm, not how many onion nodes exist. The number of Tor daemons is part of
  `params_hash` for exactly this reason.

## 2026-07-31 — clearnet `params_hash` changed without a methodology change

- On this date the clearnet `params_hash` goes from `eb15fb66` to `08bba3be`.
  **This is not a break in the clearnet series** — the measurement is unchanged
  (15 min / 500 concurrent / 5 s timeouts / same candidate sources and backoff).
- The cause is the entry above: `socks5_instances` was added to the set of fields
  the hash is computed over. For clearnet its value is always 0, but adding the
  field changes the hash input, so every network's hash was recomputed.
- Treat clearnet data from 2026-07-29 (when `harvest` was enabled) onward as one
  continuous series across this hash change. Whenever the *definition* of
  `params_hash` changes rather than a parameter, it will be recorded here the
  same way.

## 2026-07-30 — daily export: `observer.addrman` renamed to `observer.known_addresses`

- The field counts addresses from **all** candidate sources, not just the addrman,
  so the old name became misleading once `harvest` was enabled. Values and meaning
  are unchanged; only the key name differs.
- Reporting rename only — measurement parameters and `params_hash` are unchanged.

## 2026-07-29 — candidate source widened: recursive getaddr (`harvest`)

- **Methodology change — `params_hash` changes on this date.** Numbers before and
  after are not directly comparable: reachability is now measured against a wider
  candidate set, so counts step up.
- Candidate sources are now `addrman` + `harvest`: in addition to the observer
  node's address book (capped at roughly 82,000 entries), reachable peers are
  asked for their own address books once a day (05:30 UTC) and the union is added
  to the candidate set. Measurement itself — the version/verack handshake,
  intervals, concurrency, timeouts, backoff — is unchanged.
- The active sources of each day are published in `observer.candidate_sources`.

## 2026-07-29 — daily export: `observer` block added

- The daily JSON now includes an `observer` object: addrman address counts per
  network and the number of addresses currently in backoff, at export time.
  Aggregate counts only; raw addresses are never published.
- Reporting addition only — measurement parameters and `params_hash` are unchanged.

## 2026-07-28 — IPv6 connectivity enabled at the vantage point

- The observer VPS had no IPv6 route until this date, so all `ipv6` probes failed:
  ipv6 reachability counts before 2026-07-28 ~07:00 UTC are 0 and reflect the
  vantage point, not the network.
- Measurement parameters are unchanged (`params_hash` is unaffected; this is a
  vantage-point capability change, not a methodology change).

## 2026-07-26 — v0.1.0 initial parameters

- clearnet: 15 min interval / 500 concurrent connections / 5 s connect and handshake timeouts
- onion: once a day / 50 concurrent connections / 30 s timeouts / dedicated Tor SOCKS5
- Candidate set limit 100,000
- Exponential backoff after 30 consecutive failures (900 s × 2^n, capped at 2^10); never removed
- Failure reason classification: `timeout` / `refused` / `unreachable` / `handshake_error`
- Daily JSON by_* maps are top 20 entries + `other`
- params_hash covers: interval / concurrency / timeouts / candidate_limit / backoff / protocol_version
