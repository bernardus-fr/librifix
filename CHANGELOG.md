# 📢 Librifix - Changelog (Alpha - V 1.2.2)

## 🚀 Improvements

### 🔧 Stability & Performance

- General improvements for program stability.
- Temporary files are now properly deleted at the end of execution.

### 📦 Dependency Management

- Automated dependency analysis and installation.
- Adaptation for different Linux distributions:
  - Ubuntu, Debian, Linux Mint
  - Fedora, CentOS, RHEL
  - openSUSE
  - Arch Linux

### 🔍 Integrity & Execution Checks

- Verification of file integrity before processing.
- Ensuring all Bash scripts have the necessary execution permissions.
- Detection of first launch or crash recovery.

### ⚙️ Configuration & Compliance

- Introduced a `config.ini` file to store essential program settings.
- Added checks for compliance and compatibility with Calibre viewer.

### 🌍 Multi-language Support

- Implemented language support for the interface (French, Italian, English, Spanish, German...).
- Simplified translation by using `lang.json` files without modifying the code.

## 🛠 Bug Fixes

- Improved error handling and better `exit` management for smoother execution.
- Fixed a bug where only the first paragraph of multi-paragraph notes was duplicated when synchronizing multiple references.

## 📄 Documentation Updates

- Updated README and licenses.
- Provided a sample working directory for simulation purposes.

