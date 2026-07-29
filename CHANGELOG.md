# CHANGELOG

History of changes to parameters that affect the measurement methodology.
**Always record them with dates.**
(Also machine-detectable via the `params_hash` of each snapshot.)

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
