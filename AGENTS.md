# Git Workflow Rules

- **Commit Workflow**:
  - Ketika diperintahkan untuk commit:
    1. Jalankan `git status` untuk memeriksa perubahan yang ada.
    2. Buat commit (`git commit -m "..."` atau `git add` dan `git commit`).
    3. **HANYA itu saja.** Jangan menjalankan perintah lain lagi (seperti push, build, test, atau perintah tambahan lainnya) setelah commit selesai dibuat kecuali secara eksplisit diminta oleh user.
