# Penanganan offline

Online di jaringan tidak selalu berarti server terjangkau. Gunakan
`ReachabilityProbe` dengan URL ringan (misalnya `/health`) bila aplikasi perlu
mengetahui keterjangkauan server.

Probe bersifat opsional: tanpanya, status hanya mengikuti konektivitas
platform. `offline_guard` tetap mencegah request saat perangkat offline.
