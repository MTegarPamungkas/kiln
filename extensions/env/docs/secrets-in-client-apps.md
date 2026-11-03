# Secrets in client apps

`--dart-define` menyimpan nilai di binary aplikasi. Siapa pun yang memiliki
binary dapat mengekstrak nilai tersebut.

Aturannya:

- Jangan simpan service role key, private key, atau kata sandi server di env
  aplikasi klien.
- Simpan hanya nilai yang memang boleh diketahui klien, misalnya URL API dan
  public key.
- `api_key` di extension ini ditandai rahasia agar tidak muncul di log/debug,
  bukan agar aman dari ekstraksi.
- Operasi sensitif harus berjalan di server atau backend seperti Appwrite,
  Firebase, atau Supabase dengan aturan akses.
