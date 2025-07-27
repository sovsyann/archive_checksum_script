# Cross-Platform DVD/BD/ISO/Folder Data Archive Integrity Verification Scripts

## Overview

This project offers a **reliable, cross-platform workflow for archiving data to DVD/BD discs with file-level integrity verification**. By including both a file checklist and verification scripts directly on your disc, you can verify the integrity of your archive from the disc itself on different OS in the future.

## Project Purpose

Burned optical discs (and some other media that does not exclude HDDs) can develop errors over time. A disc-level checksum only reveals that *something* is wrong, not *what* or *where*.  
Rather than hashing the entire disc as a single entity, this system:
- Generates per-file MD5 hashes
- Stores them in a compatible `checklist.md5sum` file
- Allows **platform-independent** integrity verification

This allows for error checking. If error appears this script will help you to understand where, and if not, that means your data is sill safe. 

---

## Features:
- **Cross-platform scripts:** macOS/Linux (Bash) and Windows 10/11 (PowerShell)
- **Unicode support:** Handles filenames with accented, Cyrillic, and other non-ASCII characters
- **Long file/path name support**
- **Hidden/system file filtering:** Skips `.DS_Store`, `desktop.ini`, `._*`, etc.
- **Checklist format:** UTF-8 with BOM and **LF-only line endings** for maximum compatibility
- **Verifies individual files** (vs. whole-disc hashing)
- **Readable progress output** with per-file status
---

## Recommended Archive Structure

**Place the checklist and verification scripts *outside* your root archive folder, best if in the root of the disc.**  
This matches how the scripts expect relative paths.

```
/checklist.md5sum       ← The integrity checklist (place in disc root, not inside the archive folder)
/verify_md5sum.sh       ← Linux/macOS verification script (place in disc root)
/verify_md5sum.ps1      ← Windows verification script (place in disc root)
/YourArchiveFolder      ← Your data folder (top-level, matches checklist paths)
    /datafile1.ext
    /subfolder/datafile2.ext
```

**Why?**  
- The scripts expect the archive folder’s name as the first element in each checklist path.
- Keeping checklist and scripts at the disc root ensures simple, reliable verification from the disc itself. You can, however, check the disc from the script places elsewere, read below.

---

## Usage Instructions

### 1. Generating the Checklist

First task is to generate the checklist. Prepare your archive folder with file structure inside and place the scripts on the same level with that folder.

#### On macOS/Linux (Bash)

```bash
./generate_md5_checklist.sh <target-folder>
```
- `<target-folder>`: Path to the folder you wish to archive (e.g., `MyArchiveFolder`).
- Outputs `checklist.md5sum` in the current working directory (not inside the archive folder).
- Running script on Mac will normalize to NFC, while on Linux it's already in NFC. Normalizarion of actual files will be done automatically when you burn using Finder. As the result both files and checklist will be in NFC.

#### On Windows (PowerShell)

Allow script execution: 
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run the script:
```powershell
.\generate_md5_checklist.ps1 YourArchiveFolder
```
or
```powershell
.\generate_md5_checklist.ps1 -TargetDir "D:\Path\To\YourArchiveFolder"
```
- Produces `checklist.md5sum` in the current directory.
- Output is UTF-8 BOM with LF endings for cross-platform compatibility.

Additional logging can be enabled for Windows version of this script using the `-LogSkipped` option. This creates a text file listing the issues when generation the checklist. 
```powershell
.\generate_md5_checklist.ps1 -LogSkipped"
```

---

### 2. Preparing Your Data - Disc or image

1. **Copy/Burn the following to your DVD/BD:**
    - `checklist.md5sum` (in the root of the disc)
    - `verify_md5sum.sh` (root, for Linux/macOS)
    - `verify_md5sum.ps1` (root, for Windows)
    - Your entire archive folder (e.g., `YourArchiveFolder/`)

2. **On macOS:**  
   - When using Finder (to burn) or Disk Utility (to make image), hidden system and MacOS specific files are automatically excluded.
   - For hybrid discs, use Disk Utility’s **Hybrid Image Format (HFS+/ISO/UDF)** option.
   - On Mac to convert from .dmg to .iso you can use this command: `hdiutil convert myimage.dmg -format UDTO -o myimage.iso`, after that you may have to rename created myimage.iso.cdr file to myimage.iso

---

### 3. Verifying Your Archive (After Burning)

#### **Option 1: Default Verification**  
*(Run directly from the disc root; assumes default filenames and structure)*

**macOS/Linux:**
```bash
./verify_md5sum.sh
```

**Windows:**
```powershell
.\verify_md5sum.ps1
```

- This checks `checklist.md5sum` in the current directory and verifies the archive folder also in the current directory (disc root).

#### **Option 2: Advanced Verification (Custom Locations)**  
*(If your checklist or archive folder is in a different location, or to verify a copy elsewhere)*

**macOS/Linux:**
```bash
./verify_md5sum.sh /path/to/checklist.md5sum /path/to/YourArchiveFolder
```

**Windows:**
```powershell
.\verify_md5sum.ps1 -ChecklistFile "E:\checklist.md5sum" -RootFolder "E:\YourArchiveFolder"
```
or
```powershell
.\verify_md5sum.ps1 <path to checklist> <path to folder>
```

- Use this if you want to verify an archive copy that is not in the original location, or you have moved the checklist.

---

## Notes on Compatibility

- **Checklist Format:**  
  - Always UTF-8, LF line endings, forward slashes in paths.
- **Unicode and Long Filenames:**  
  - Fully supported on all platforms.
- **System/Junk Files:**  
  - Hidden Mac/Windows system files are excluded by the generation scripts.
- **Disc Creation:**  
  - On macOS, use **Hybrid Image Format (HFS+/ISO/UDF)** for best cross-platform results.
  - Finder skips MacOS junk files when burning.
  - On Lunix k3b software was tested and works with no issues.
- **Disc Created on Windows caveat:**  
  - The script was tested to create checklist on Windows and then verify on Lunix - works fine as both use NFC. 
  - Creating the checklist on Windows may result discrepancies of verification on Mac because it's native NFD unicode normalization. Even though the files and the checklist  were both created in NFC, MacOS seems to be converting the names on the fly to NFD when reading, that may result in errors with file paths containing special characters. 
  - Another caveat discovered when creating the checklist on Windows is that linux .sh files lose their -x attribute which results in not being able to run the script directly from the CD. A workaround in this case is to copy the script to any folder and lauch it from there indicating the paths to checklist and the folder.
  - Creating AND Verification of the archive on Windows works fine. 

---

## Example Scenario

Suppose you want to archive your folder `VacationPhotos`:

1. **Generate checklist (on your computer):**
    - **macOS/Linux:** `./generate_md5_checklist.sh VacationPhotos`
    - **Windows:** `.\generate_md5_checklist.ps1 -TargetDir "D:\VacationPhotos"`

2. **Burn the following to disc:**
    - `checklist.md5sum`
    - `verify_md5sum.sh`
    - `verify_md5sum.ps1`
    - `VacationPhotos/` (your archive folder)

3. **To verify from the disc (default):**
    - **macOS/Linux:** `./verify_md5sum.sh`
    - **Windows:** `.\verify_md5sum.ps1`

4. **To verify from a copy or non-default location:**
    - Adjust the script parameters to match the location of your checklist and archive folder.

---

## Recommendations & Tips

- **Always place `checklist.md5sum` and verification scripts at the disc root.**
- **Keep your archive folder’s name unchanged after checklist generation.**
- **Test your workflow with an ISO or rewritable disc before burning archival discs.**
- **For best long-term compatibility, avoid overly long or complex path names.**
- **On Windows, run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` if needed to allow PowerShell script execution.**

---

### Discs Longevity Comparison

| Disc Type           | Typical Lifespan        | Notes                                                                 |
|---------------------|-------------------------|-----------------------------------------------------------------------|
| **CD-R**            | 10–30 years             | Depends on dye quality and storage conditions.                        |
| **DVD-R**           | 5–30 years              | Slightly more fragile due to higher data density.                     |
| **BD-R (Blu-ray)**  | 20–50 years             | Better materials; more stable than CDs/DVDs, HTL type recommended.    |
| **M-DISC DVD**      | 1,000+ years (claimed)  | Uses inorganic material;                                              |
| **M-DISC Blu-ray**  | 1,000+ years (claimed)  | Ideal for archiving; resistant to heat, light, and humidity.          |

* Lifespan assumes proper storage: cool, dark, dry environment with minimal handling.



## License

This project is provided as-is for archival and educational purposes.

---
