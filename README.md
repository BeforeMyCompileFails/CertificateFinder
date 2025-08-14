# Certificate Finder

[![Author](https://img.shields.io/badge/Author-BeforeMyCompileFails-blue.svg)](https://github.com/BeforeMyCompileFails/CertificateFinder)

**Certificate Finder** is a Windows batch tool that scans an offline or dead system’s drive for certificates, private keys, and related cryptographic files.  
It preserves folder structure, copies Firefox and Windows crypto data, and generates a CSV manifest with SHA256 hashes for verification — making it ideal for IT admins and forensic recovery.

---

## 🔍 Features

- Recursively scans a specified drive for common certificate/key file types:
  - `.pfx`, `.p12`, `.p7b`, `.p7c`, `.p7m`, `.cer`, `.crt`, `.pem`, `.key`, `.der`, `.jks`, `.keystore`, `.asc`
- Copies found files to a timestamped output folder, preserving relative directory structure
- Generates a CSV manifest with:
  - SHA256 hash
  - File size (bytes)
  - Original path
  - New location
- Collects:
  - **Firefox** profile DBs (`cert9.db`, `key4.db`, `profiles.ini`)
  - **Windows Crypto & DPAPI** data:
    - User/System Certificate Stores
    - RSA/DSS keys
    - DPAPI Master Keys
    - Machine-level keys
    - Registry hives (`SAM`, `SECURITY`, `SOFTWARE`, `SYSTEM`, `DEFAULT`)
- Keeps original paths in the copied folder structure for easier mapping

---

## 📂 Output Structure

```
Cert_Collection_YYYY-MM-DD_HHMMSS\
├── collection.log
├── manifest.csv
├── files\               # Found certificate/key files
├── firefox_profiles\    # Firefox cert/key databases
├── windows_crypto\      # System & user certificate store data
└── misc\                # Any extra matches from browser data
```

---

## ⚙️ Requirements

- **Windows 7/10/11 or Server**
- **Run as Administrator** for full access to protected folders
- The source drive must be connected and assigned a drive letter
- Built-in tools used: `for`, `robocopy`, `certutil`

---

## 🚀 Usage

1. Clone the repository or download `CertificateFinder.bat`
   ```bash
   git clone https://github.com/BeforeMyCompileFails/CertificateFinder.git
   ```
2. Connect the offline/dead system's drive to your machine.
3. Open **Command Prompt** as Administrator.
4. Run:
   ```cmd
   CertificateFinder.bat <DriveLetter>:
   ```
   Example:
   ```cmd
   CertificateFinder.bat G:
   ```

---

## 📝 Example Run

```
C:\Tools> CertificateFinder.bat G:
[INFO] Searching for candidate certificate/key files...
[INFO] Collecting Firefox profiles (cert9.db, key4.db, profiles.ini)...
[INFO] Collecting Windows Crypto/DPAPI material...
[OK] Done.
Output folder: "C:\Tools\Cert_Collection_2025-08-14_1702"
Manifest:      "C:\Tools\Cert_Collection_2025-08-14_1702\manifest.csv"
Log:           "C:\Tools\Cert_Collection_2025-08-14_1702\collection.log"
```

---

## ⚠️ Notes

- This script **copies raw files** — it does **not** crack, decrypt, or export non-exportable keys.
- If a certificate was stored in the Windows Certificate Store with a non-exportable key, you will need the original Windows DPAPI context (user credentials, domain creds, etc.) to recover it.
- The CSV manifest helps verify file integrity via SHA256.

---

## 📄 License

This script is provided **as-is**, without warranty of any kind.  
Use responsibly and ensure you have legal rights to access and copy data from the target drive.

---

**Author:** [BeforeMyCompileFails](https://github.com/BeforeMyCompileFails/CertificateFinder)
