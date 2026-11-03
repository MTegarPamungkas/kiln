# Troubleshooting delivery

## Android receivers

`flutter_local_notifications` membutuhkan dua receiver di
`android/app/src/main/AndroidManifest.xml`. Extension menambahkannya otomatis
lewat `android.receivers`; bagian ini hanya untuk memverifikasi hasil install:

```xml
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON" />
    <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```

Extension juga menambahkan `POST_NOTIFICATIONS` dan
`RECEIVE_BOOT_COMPLETED`.

## Exact alarms

Dengan `exact_alarms: true`, izin berikut ditambahkan otomatis ke manifest saat
install:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

Di Android 12 ke atas pengguna tetap harus memberi akses **Alarms & reminders**
untuk aplikasi. Bila izin tidak diberikan, plugin melempar error dan
`DeviceNotifications` mengubahnya menjadi `Failure(notifications.unavailable)`.

## Jadwal tidak muncul

1. Cek izin notifikasi lewat `requestPermission()`.
2. Cek channel: id yang diminta harus ada di `NotificationChannels`, kalau
   tidak notifikasi memakai channel default.
3. Cek zona perangkat: `TimezoneResolver.configure()` harus berhasil.
4. Cek optimized battery Android; beberapa vendor menghentikan alarm.
5. Cek receiver di atas dan pastikan `RECEIVE_BOOT_COMPLETED` ada.

## Tap tidak terbaca

- Tap yang membuka aplikasi dibaca lewat `getNotificationAppLaunchDetails`,
  jadi panggil `initialize()` sebelum mendengarkan `taps`.
- Tap aksi latar belakang memakai `IsolateNameServer`; web tidak mendukungnya.
- Pastikan payload berukuran di bawah `NotificationPayload.maxEncodedLength`.

## Web

Browser hanya mengizinkan permintaan izin sebagai respons langsung terhadap
aksi user. Panggil `requestPermission()` dari handler tombol, bukan saat start.
