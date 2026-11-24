# Changelog

## 0.1.4

- Widen `connectivity_plus` constraint to `^7.3.0` so apps combining
  `connectivity` and `geolocation` (`geolocator ^14.1.2`) resolve without a
  `dbus` version conflict.

## 0.1.3

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.2

- Bootstrap can dispose the module while the first platform status check
  is still running; the monitor now stops before registering its listener or
  publishing after disposal, instead of throwing or leaking the subscription.
- The module declares its optional `http_client` dependency explicitly,
  so reachability probing is wired regardless of module input order.

## 0.1.1

- The module disposes its network monitor subscription on shutdown.

## 0.1.0

- Initial release.
