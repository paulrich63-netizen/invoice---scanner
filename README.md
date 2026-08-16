# Invoice Scanner (Flutter + Google ML Kit)

A polished Android app that photographs invoices, runs on-device OCR, attaches the photo, and exports data to **CSV** or **Excel (.xlsx)**.

## Features

- **Camera + Gallery** capture
- **On-device OCR** (Google ML Kit) – fully offline & private
- Extracts:
  - Invoice number
  - Invoice date & Due date
  - Supplier / Vendor
  - Total amount
  - Tax / VAT
  - Currency
  - Description
- **Invoice photo is permanently attached** to each entry (thumbnail in list, full-screen zoomable view)
- Review & edit before saving
- Search / filter
- Export options:
  - **CSV** (Excel / Google Sheets compatible)
  - **Excel (.xlsx)** native workbook
- Light / Dark / System theme
- Material 3 UI, pull-to-refresh, polished empty & loading states

## Requirements

- Flutter 3.16+ (Dart 3.2+)
- Android Studio or VS Code + Flutter plugin
- Android device or emulator (API 21+)

## Quick start

```bash
cd invoice_scanner_flutter

# Generate remaining platform files (keeps your lib/ and pubspec)
flutter create . --project-name invoice_scanner --org com.yourname

flutter pub get
flutter run
```

### Release APK

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

## Project structure

```
lib/
├── main.dart
├── models/invoice_entry.dart
├── services/
│   ├── ocr_service.dart
│   ├── storage_service.dart
│   ├── image_storage_service.dart   ← saves photos permanently
│   ├── csv_service.dart
│   └── excel_service.dart           ← .xlsx export
└── screens/
    ├── home_screen.dart
    └── edit_entry_screen.dart
```

## CSV / Excel columns

```
Date | Due Date | Invoice Number | Supplier | Total | Tax / VAT | Currency | Description | Created At | Has Image
```

Photos are stored under the app’s documents directory (`invoice_images/`) and are deleted when the corresponding entry is removed.

## License

MIT – free for personal and commercial use.

---

## Build the APK in the cloud (no Flutter install needed)

A GitHub Actions workflow is already included:

`.github/workflows/build-apk.yml`

### Steps

1. Create a new **public or private** repository on GitHub.
2. Push this entire project folder to the repository:
   ```bash
   git init
   git add .
   git commit -m "Initial commit – Invoice Scanner"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/invoice-scanner.git
   git push -u origin main
   ```
3. Go to the **Actions** tab of your repository.
4. You will see the workflow **“Build Android APK”**.
   - It runs automatically on every push to `main`/`master`.
   - Or click **Run workflow** → **Run workflow** to start it manually.
5. When the job finishes (usually 3–6 minutes), open the run and download the artifact named:
   - `invoice-scanner-apk`  
   or the versioned one with the commit SHA.

The downloaded file is a ready-to-install **release APK**.  
Copy it to your Android phone and install it (enable “Install unknown apps” if needed).

> Note: The first run may take a bit longer while Flutter is cached.
