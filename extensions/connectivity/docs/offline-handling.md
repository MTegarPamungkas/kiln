# Offline handling

Being online on the network does not always mean the server is reachable. Use
`ReachabilityProbe` with a lightweight URL (for example `/health`) when the
application needs to know server reachability.

The probe is optional: without it, the status only follows platform
connectivity. `offline_guard` still prevents requests while the device is
offline.
