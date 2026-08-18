# CHANGELOG

History of changes to parameters that affect the measurement methodology.
**Always record them with dates.**
(Also machine-detectable via the `params_hash` of each snapshot.)

## 2026-08-18 — daily export: `by_fail_reason` added

- Each snapshot now publishes the probes that did not complete a handshake,
  split into `timeout` / `refused` / `unreachable` / `handshake_error`.
- **Reporting addition only — measurement parameters and `params_hash` are
  unchanged.** Nothing about how probes are made or classified has changed; this
  data was always recorded, just not exported.
- Unlike `by_country` / `by_asn` / `by_user_agent` it is **not** truncated to a
  top N. The reason set is closed and small, and the split between the reasons is
  the whole point of the field. `instantaneous` plus these counts equals
  `candidates`, so a consumer can check that every probed address is accounted
  for.
- The reason it exists: the entries for 2026-08-08 and 2026-08-03 both turn on
  the share of probes that time out, and until now that figure could not be
  derived from the published data — it had to be quoted from the observer's own
  database, and quoted figures went stale. With this field those claims are
  checkable, and so is any future one.
- **The first daily file carrying it is 2026-08-17**, which is exported on
  2026-08-18. The field is absent, not zero, in every earlier file, and
  `schema/daily.json` does not mark it required for that reason.
- Note that the boundary between `timeout` and the definite reasons depends on the
  observer's load, so this field is not comparable across the dates recorded in
  this file — see the 2026-08-08 entry.

## 2026-08-09 — no onion data point on this date

- **The 2026-08-09 daily file has no onion snapshot.** The round ran normally for
  3h52m and probed all 25,897 candidates; it was the write to storage that
  failed, on a lock held by the concurrent clearnet round and address import for
  five unbroken minutes. The results were never persisted and are not
  recoverable.
- **This is a gap, not a zero, and not a network event.** Nothing is known about
  onion reachability on 2026-08-09 either way. Do not interpolate across it
  without saying so; onion counts had been 11,015 / 11,407 / 11,173 on the three
  preceding days.
- **clearnet has 95 snapshots for this day rather than the usual 96.** The 05:45
  round was lost to the same lock: the daily harvest import held it from 05:31 to
  05:47, which killed first the round's address import and then the round itself.
  Aggregates for 2026-08-09 are therefore an average over 95 rounds; the missing
  one is 05:45–06:00 UTC.
- The timeout that expired has been raised and the write is now retried, so a
  round is no longer discarded for losing a race it could have waited out.
- A replacement round was run the same day and then **deliberately excluded from
  the series**. It ran 07:49–12:00 UTC instead of the usual 02:30, and returned
  **9,719 reachable of 26,256 candidates (37.0%)**. Two reasons not to publish it
  as the 2026-08-09 point: the measurement time is part of the fixed methodology
  and this one is five hours off it, and having two onion rounds inside one 24 h
  window made the *following* day's `union_24h` a union of both (11,912 against
  an instantaneous 10,535), which is not comparable with any other day. Its
  observations are archived on the observer and available on request.
- For scale, the scheduled rounds either side were 11,173 (2026-08-08, 43.8%) and
  10,535 (2026-08-10, 40.1%), so the off-schedule figure sits about 10% below
  what interpolation would suggest. Whether that gap is the time of day or the
  measurement conditions is not something one round can settle.

## 2026-08-08 — failure reasons are reclassified from this date; `timeout` and `unreachable` are not comparable across it

- **Revised on 2026-08-18.** The version of this entry published on 2026-08-14
  said that measurement capacity was falling and that onion `instantaneous` had
  dropped from ~11,400 to ~10,600. The second claim was wrong and is withdrawn:
  the count recovered and then exceeded its previous high (12,045 on 08-17). It
  was drawn from six days of a series whose seventh day contradicted it. What
  follows is what the data supports.
- **No parameter changed, so `params_hash` does not change on this date.** The
  Tor daemon count, the timeouts and the concurrency are all as they were — this
  is the category the hash cannot signal, like the 2026-08-07 entry below.
- What changed is which bucket a failed onion probe lands in. `timeout` and
  `unreachable` traded places in a single round and have stayed swapped:

  | Round | Candidates | Reachable | Success | `timeout` | `unreachable` | Duration |
  |---|---|---|---|---|---|---|
  | 2026-08-06 | 24,497 | 11,015 | 45.0% | 19.4% | 24.7% | 2h52m |
  | 2026-08-07 | 24,930 | 11,407 | 45.8% | 18.5% | 24.6% | 2h55m |
  | 2026-08-08 | 25,496 | 11,173 | 43.8% | 34.2% | 14.8% | 3h43m |
  | 2026-08-10 | 26,297 | 10,535 | 40.1% | 37.3% | 14.9% | 4h02m |
  | 2026-08-11 | 26,602 |  9,934 | 37.3% | 43.8% | 11.2% | 4h39m |
  | 2026-08-12 | 26,937 | 10,519 | 39.1% | 38.0% | 14.6% | 4h09m |
  | 2026-08-13 | 27,401 | 10,634 | 38.8% | 39.4% | 14.5% | 4h17m |
  | 2026-08-14 | 27,966 | 10,547 | 37.7% | 30.7% | 21.1% | 4h09m |
  | 2026-08-15 | 28,413 | 11,329 | 39.9% | 37.1% | 15.7% | 4h20m |
  | 2026-08-16 | 28,874 | 11,869 | 41.1% | 32.7% | 17.9% | 4h14m |
  | 2026-08-17 | 29,181 | 12,045 | 41.3% | 33.8% | 16.9% | 4h19m |

- The cause is the observer, which has one CPU core and 961 MB of RAM. Peak swap
  per Tor daemon went from under 10 MB in the 2026-08-07 round to 120–165 MB from
  the 2026-08-08 round onward and has stayed there, and rounds run at 74–98% of
  the single core. A slower observer does not fail to reach a node it would
  otherwise have reached; it fails to finish *classifying* the ones it cannot
  reach. Probes that used to return a definite "unreachable" inside the 90 s
  budget now exhaust it and are recorded as `timeout` instead.
- **What this invalidates:** any comparison of `by_fail_reason` across this date,
  and in particular reading the rise in `timeout` as onion nodes becoming slower
  or less responsive. The 2026-08-03 entry's framing — that `timeout` share
  indicates how much of the network our Tor capacity fails to confirm — is only
  valid within a period of stable observer load.
- **What this does not invalidate:** the reachable counts. `instantaneous` has
  risen more or less steadily since 2026-08-11 and set a new high on 08-17, while
  the observer stayed just as saturated. Do not read the elevated `timeout` share
  as a suppressed node count.
- Success *rate* and success *count* move in opposite directions here and should
  not be substituted for one another. The rate fell from 45.8% to 41.3% because
  the candidate set grew 17% over the period while reachable grew 6%; both
  statements are true and describe different things. Most of the added candidates
  are addresses that have never completed a handshake.
- The test from the 2026-08-06 entry still applies. From roughly 2026-09-01,
  backoff begins skipping the longest-failing onion addresses, which will cut
  candidates and therefore load. If the observer is the reason `timeout` and
  `unreachable` are swapped, that swap should partly unwind as rounds get
  shorter, with no matching change in `instantaneous`.
- **clearnet is not affected by the reclassification, but it is not isolated from
  the load either.** Its rounds run measurably longer while the onion round is in
  progress — 140 s against 104 s elsewhere in the day on 2026-08-11, 189 s against
  130 s on 08-14. Its own timeout share fell across this date rather than rising
  (46.3% on 08-07 to 40.0% on 08-13). clearnet probes are direct with a 5 s
  budget, so they do not wait on a rendezvous circuit, which is the part that
  degrades. Treat the clearnet series as continuous across this date.

## 2026-08-07 — bug fix: addresses in the addrman were permanently excluded from probing

- **`params_hash` does not change on this date, but what is measured does.** The
  backoff parameters are identical; the bug was in how they were applied. This is
  the case the hash cannot signal, so it is recorded here instead.
- Backoff decided when to re-probe an address from `last_seen`, but the observer
  node's address book is re-imported every 15 minutes and that import rewrote
  `last_seen` to the current time for every address it contained. The backoff
  interval could therefore never elapse for any address still in the address
  book: once such an address failed 30 times in a row it was **never probed
  again**, instead of returning on the published 900 s × 2^n schedule.
- 46,123 clearnet addresses were in that state, 524 of which had completed a
  handshake at some point and 296 within the previous week. The effect ratchets:
  any node that stays offline for 7.5 h (30 rounds) joins the excluded set and
  does not come back when it recovers. **Clearnet counts up to and including
  2026-08-06 are therefore an undercount that grows slowly over time**, masked so
  far by the candidate set expanding faster than the exclusion accumulated.
- Fixed by tracking the last probe time separately from `last_seen`. The ~97k
  addresses that were overdue are returned to the rotation gradually over the 24 h
  following the fix, rather than all at once. If clearnet `instantaneous` rises
  over 2026-08-07/08-08, read that as recovering addresses that were being missed,
  not as the network growing. The first round after the fix probed 5,058 more
  addresses and found none of them reachable, so the correction may well turn out
  to be small — most of what was excluded is genuinely dead.
- **`union_24h` is affected more than `instantaneous`, so the ratio between them
  shifts across this date.** Daily means for clearnet went from 8,440 /
  9,012 on 2026-08-06 to 8,836 / 9,615 on 2026-08-10: `instantaneous` +4.7%,
  `union_24h` +6.7%. The addresses that came back into rotation are mostly nodes
  that are up intermittently, which show up somewhere in a 24 h union far more
  readily than in any single round.
- The consequence is that `instantaneous / union_24h` — the churn indicator
  described in the README — **steps down across this date for reasons that have
  nothing to do with churn**. It sat between 0.936 and 0.945 for 2026-08-01 to
  08-06 and between 0.915 and 0.919 for 2026-08-09 to 08-10, with 08-07 and 08-08
  in transition as the backlog was released. Do not read that step as the network
  becoming less stable. Comparisons of this ratio across 2026-08-07 are not valid;
  within either period they are.
- onion was not affected. Its rounds are daily, so no onion address had yet
  reached 30 consecutive failures — see the entry below, which still applies.

## 2026-08-06 — advance notice: onion candidate counts will start falling ~2026-09-01

- No parameter changes; `params_hash` is unaffected. This is a heads-up about a
  scheduled effect of the existing backoff rule, so it is not misread as a change
  in the network.
- Backoff has never yet removed an onion address from a round. It applies after
  30 consecutive failures, but the interval only starts at 900 s × 2^0, and an
  address is skipped only once that interval exceeds the 24 h onion round — i.e.
  at 37 consecutive failures, not 30. The oldest onion failure streak is 11 as of
  2026-08-06, so **every known onion address is still probed every round**, and
  `candidates` equals the full onion address set.
- From roughly 2026-09-01 the longest-failing addresses begin skipping rounds, and
  the share skipped grows as intervals keep doubling (capped at 900 s × 2^10 ≈
  10.6 days). About 13,000 of the 24,926 known onion addresses have never
  completed a handshake and are the ones affected.
- Expect `candidates` to fall, round duration to shorten, and the success *rate*
  to rise — none of which mean the onion network changed. `instantaneous` should
  be largely unaffected, since the addresses dropping out are ones that have never
  been reachable. Compare `instantaneous` across this period, not the rate.
- clearnet has been in this regime since the start (900 s rounds, so backoff bites
  at 31 failures), which is why its `candidates` already swings between roughly
  8,700 and 47,500 within a day as cohorts are released.

## 2026-08-04 — data quality: Tor daemons crashed mid-round (2 rounds)

- The onion rounds of 2026-08-04 (7,935) and 2026-08-05 (10,225) were measured
  while all three Tor daemons aborted partway through and restarted. The cause
  was `MaxMemInQueues 96 MB`, below the descriptor cache a round of this size
  builds; the daemons hit the ceiling and aborted on a conflux assertion.
- **Parameters and `params_hash` are unchanged** — this is not a methodology
  change, and the figures are not invalid. But the crash time was coupled to how
  well the round was going, so these two days are not directly comparable with
  each other or with later ones.
- Fixed on 2026-08-05: `MaxMemInQueues 256 MB`, `ConfluxEnabled 0`, and all
  three daemons are restarted before each round so every round starts from an
  empty descriptor cache. The first clean round (2026-08-06) returned 11,015.

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
