# CHANGELOG

History of changes to parameters that affect the measurement methodology.
**Always record them with dates.**
(Also machine-detectable via the `params_hash` of each snapshot.)

## 2026-07-26 — v0.1.0 initial parameters

- clearnet: 15 min interval / 500 concurrent connections / 5 s connect and handshake timeouts
- onion: once a day / 50 concurrent connections / 30 s timeouts / dedicated Tor SOCKS5
- Candidate set limit 100,000
- Exponential backoff after 30 consecutive failures (900 s × 2^n, capped at 2^10); never removed
- Failure reason classification: `timeout` / `refused` / `unreachable` / `handshake_error`
- Daily JSON by_* maps are top 20 entries + `other`
- params_hash covers: interval / concurrency / timeouts / candidate_limit / backoff / protocol_version
