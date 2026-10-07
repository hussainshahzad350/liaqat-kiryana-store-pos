# Release performance baseline — 2026-10-04

Measured on this Windows development host in a compiled AOT release executable.
The disposable dataset contains 10,001 products and
2,002 customers after verification. It includes 50
posted/cancelled historical invoices before startup. The standalone source copy
is 2.29 MiB; its SHA-256 remains unchanged while
all actions execute on an independent copy. The catalog/contact rows are synthetic,
with zero opening stock/balances for generated records; this is representative
volume, not a populated customer store or a realistic sold-item distribution.

| Operation | Median ms | Highest of seven samples ms |
| --- | ---: | ---: |
| catalogFirstPage | 1.75 | 2.13 |
| catalogSearch | 7.10 | 7.86 |
| catalogDeepPage | 3.49 | 4.18 |
| stockPage | 0.66 | 0.88 |
| postAndCancel | 31.45 | 36.14 |
| backup | 47.29 | 51.11 |

One warm-up precedes seven samples for each operation. Highest sample is reported
rather than implying a statistically reliable percentile from seven observations.
Repository timings include the call and its result checks; postAndCancel includes
both transactions. Native startup and checkout are separate single observations:

- App bootstrap to first rendered PIN login: **240.6 ms**.
- Checkout callback to rendered post-sale dialog: **789.4 ms**,
  including harness field-entry/wait delays; not human checkout time.

Startup excludes synthetic fixture generation, process loading and provisioning.
Search is the catalog repository query; deep paging uses offset 9980 and limit20;
stock paging uses limit100. The existing SalesBloc still loads all active products
initially. These measurements do not justify a claim that every list is virtualized
or that production search latency matches this machine. No protected behavior or
schema was changed to obtain a faster number. Retain this baseline before any
future performance change and compare equivalent release fixtures/cache conditions.

Reproduce with ./tool/verify_release.ps1. Raw samples and failure/repair evidence
are retained in build/cleanup-phase5-review/release-smoke.json and build logs.
Release workflows also verify four payment/reversal modes, account payments,
purchase/reversal, stock adjustment, cash in/out and every saved table after restore.
The source audit reported 195 production-reachable
libraries at that historical measurement. The later unused-code cleanup removes
17 orphan libraries and 95 declaration-only methods; rerun verification before
using the historical timings as measurements of a new build.
