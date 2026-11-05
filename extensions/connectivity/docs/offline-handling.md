# Offline handling

Being online on the network does not always mean the server is reachable. Use
`ReachabilityProbe` with a lightweight URL (for example `/health`) when the
application needs to know server reachability.

The monitor can do this on demand: when a `probe_url` is configured and an
`HttpClient` is installed, `gate.networkReachable()` sends a `HEAD` request to
that URL and returns `Ok(false)` on a failure or a `probe_timeout`. Call it on
resume, or on your own schedule using `probe_interval` as the cadence.

The probe is optional: without it, the status only follows platform
connectivity. `offline_guard` still prevents requests while the device is
offline.
