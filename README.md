# btc-node-data

Measurement data of reachable nodes on the Bitcoin P2P network.
The raw-data publication repository of a sustainable observation infrastructure.

**Design principles: continuity > accuracy. Explicit and fixed methodology. Open and distributed raw data. No single point of failure.**

## Methodology

Numbers depend heavily on the measurement methodology, and numbers from observers with
different methodologies are not comparable with each other. When using or citing this data,
always state the methodology below alongside it.

### Collection method

- Candidate addresses come from the sources listed in `observer.candidate_sources`
  of each daily file (also covered by `params_hash`):
  - `addrman` — the observer node's (bitcoind) address book via `getnodeaddresses 0`,
    which a single node caps at roughly 82,000 entries.
  - `harvest` — recursive `getaddr` discovery: reachable peers are asked for their
    own address books once a day and the union is added to the candidate set.
  **Even combined, this is "what is visible from our vantage point", not full
  coverage of the network.**
- For each candidate: TCP connect → send `version` → receive `version`/`verack` → disconnect
  immediately. No persistent connections.
- The crawler's user agent is `/btc-node-observatory:0.1.0/`.
- Measurements are taken **from a single vantage point**. Results may differ from other vantage
  points (the same limitation KIT DSN discloses with "the monitor node is located in Germany").

### Parameters (changes are recorded in the CHANGELOG with dates and change the params_hash)

| Item | clearnet | onion |
|---|---|---|
| Interval | 15 min | once a day |
| Concurrent connections | 500 | 90 |
| Connect timeout | 5 s | 90 s |
| Handshake timeout | 5 s | 90 s |
| Route | direct | SOCKS5, round-robin over 3 dedicated Tor daemons |

- Addresses that fail 30 times in a row are probed with exponential backoff
  (900 s × 2^n, capped at 2^10). **They are never removed**, so the address set
  the observer knows about grows without bound (320,538 as of 2026-08-06); what
  backoff limits is how often each address is probed, not how many are kept.
- Candidate limit: 100,000 **per round**. This is a cap on how many addresses one
  round probes, applied after backoff selection — it is not a cap on the address
  set. If it ever binds, addresses that have never completed a handshake are
  dropped first. It has never bound: the highest any round has reached is 85,749
  (2026-07-30), and the figure has been falling since as older addresses move to
  longer backoff intervals. `candidates` in each snapshot is the actual number.
- Because backoff releases addresses in cohorts, `candidates` swings widely
  within a day — on 2026-08-05 it ranged from 8,671 to 47,516. A snapshot's
  reachable count should be read against its own `candidates`, not against a
  daily average.
- `by_country` / `by_asn` / `by_user_agent` in the daily JSON are the top 20 entries + `other`.

A change of `params_hash` is a reliable signal that *something* changed, but not
proof that the measurement did: the hash also changes when a new field is added to
its definition. Every hash change — parameter or definition — is explained in the
CHANGELOG, so check there before treating one as a break in the series.

### Dual definition of reachability

| Metric | Definition | Corresponds to |
|---|---|---|
| `instantaneous` | Nodes that completed a handshake within one round | Bitnodes-style (point-in-time, lower bound) |
| `union_24h` | Union of nodes with at least one successful handshake in the 24 hours preceding the snapshot | KIT-style (upper bound) |

The ratio `instantaneous / union_24h` serves as a churn indicator of the network.

### Separation of clearnet and onion

**clearnet and onion are recorded separately, never combined.** If you need a combined value,
compute it at display time and state so explicitly. When presenting per-country shares, use
clearnet as the denominator (a denominator that includes onion misleadingly deflates country
shares).

### Epistemic weakness of onion node counts

Onion absolute counts must not be treated as authoritative numbers.

- One node can run multiple onion services, so **address count ≠ host count**.
- There is no IP or ASN, so no cross-checking is possible.
- Generating onion addresses is free and unlimited, so the cost of creating Sybils is extremely low.
- **The count is bounded by our Tor capacity, not by the network.** Building a
  rendezvous circuit per address is slow, so a probe that is cut off early is
  indistinguishable from a dead address. Both changes we have made to that budget
  moved the number by roughly an order of magnitude while the network itself stayed
  the same: tripling the Tor daemons (2026-07-31) took it from ~190 to ~320, and
  raising the timeouts from 30 s to 90 s (2026-08-03) took it from 691 to 7,935.
  Roughly 19% of probes still end in `timeout`, so the figure is still a lower
  bound. Read it as "what our Tor capacity could confirm on that day", and treat
  any change to the number of daemons or the timeouts (recorded in the CHANGELOG,
  and part of `params_hash`) as a break in the series.

Therefore treat the onion series primarily as **trends in ratios**; absolute numbers are
indicative only.

## Data layout

```
daily/YYYY/MM/YYYY-MM-DD.json   # Daily aggregates (schema: schema/daily.json)
aggregates/{day,week,month,quarter,year,all}.json  # Pre-aggregated per granularity (generated by Actions)
```

The raw full snapshots (per-node observation results) are archived monthly as tarballs in
GitHub Releases and yearly on [Zenodo](https://zenodo.org/) (with DOI).

## License and citation

The data is published under [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/).

> btc-node-observatory contributors, "Bitcoin reachable node measurements", https://github.com/azuchi/btc-node-data

The `by_country` / `by_asn` breakdowns include GeoLite2 data created by MaxMind,
available from [https://www.maxmind.com](https://www.maxmind.com).

## Mirrors

Mirrors are maintained on Codeberg / GitLab to remove the risk of GitHub account suspension or
outage. If this repository stops being updated, forking it and continuing the observations is
welcome.
