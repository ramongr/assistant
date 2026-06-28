<!-- markdownlint-disable MD013 -->
# Security Policy

`assistant` is a small Ruby gem with no runtime dependencies and a tiny
surface area, but security reports are still very welcome.

## Supported versions

| Version | Status                                                          |
|---------|-----------------------------------------------------------------|
| 1.x     | **Supported.** Security fixes land on `main` and ship promptly. |
| 0.x     | **End of life** on the `1.0.0` release. No further fixes.       |

The supported branch will always be the current `1.x` release line. There is
no intention to backport security fixes to `0.x` once `1.0.0` ships; users on
`0.x` should upgrade. The migration guide lives at
[`docs/v1/index.md`](./docs/v1/index.md).

## Reporting a vulnerability

**Do not open a public GitHub issue or pull request for a security report.**

Email <cerberus.ramon@gmail.com> with:

- A description of the issue.
- The version of `assistant` (and Ruby) you reproduced it on.
- A minimal proof-of-concept or runnable reproduction.
- Any suggested mitigation, if you have one.

If the report involves dependencies pulled in by a downstream Rails or Sinatra
application, please mention that too — `assistant` itself has zero runtime
dependencies, so the issue may need to be routed upstream.

## Response SLA

We aim for the following turnaround on a best-effort basis:

- **First response:** within **7 days** of receiving the email.
- **Fix or mitigation plan:** within **30 days** of triage, depending on
  severity. Critical issues are fast-tracked.

You will be kept in the loop on the timeline and credited in the
`CHANGELOG.md` entry once the fix ships, unless you ask to remain anonymous.

## Coordinated disclosure

We follow a coordinated-disclosure model: the fix is released first, the
CHANGELOG entry calls out the affected versions and the reporter, and any
CVE / GHSA advisory is filed afterwards. Please do not publish details
publicly until the fixed release is out.
