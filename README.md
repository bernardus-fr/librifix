# LIBRIFIX

## Introduction

Librifix is a tool designed to automate the creation and structuring of EPUB 3 files from user-provided text documents and media. It ensures a smooth conversion process that adheres to EPUB standards while facilitating metadata management and compatibility between EPUB 2 and EPUB 3.

Librifix primarily handles EPUB file structuring. Once the EPUB is generated, manual adjustments may be necessary. The tool performs approximately 90% of the work, but the editor should review and refine details if needed.

## Key Features

- **Metadata Collection**: Requests essential book information from the user.
- **EPUB 3 Structure Creation**: Generates mandatory files (OPF, NCX, NAV, etc.), inserts metadata, and automatically creates essential files when needed (CSS stylesheets, cover page, etc.).
- **User File Analysis**: Automatically identifies and classifies text documents and media.
- **XHTML Structure Generation**: Converts text and media into compliant XHTML files.
- **Footnote Management**: Converts footnotes into interactive links that comply with EPUB standards, handling multiple references properly.
- **Insertion of Components into EPUB 3 Structure**: Automatically integrates generated files into the EPUB.
- **Automatic Manifest, Reading Order, and Index Update**: Ensures optimized navigation and correct structuring.
- **Maximum Compatibility for EPUB 2 and EPUB 3**: Ensures the generated EPUB functions on most e-readers.
- **EPUB Archive Compilation**: Generates the final EPUB file.
- **EPUBCheck Compliance Verification**: Validates the EPUB to ensure proper functionality.

## Installation

### Prerequisites

Librifix runs with **Bash** and **Python**.

- **Bash**: Requires `Zenity` and `json` libraries.
- **Python**: Requires **Python 3.x** and the following libraries:
  - `os`
  - `json`
  - `pathlib`
  - `subprocess`
  - `re`
  - `sys`
  - `xml.etree.ElementTree`
  - `datetime`
  - `time`
  - `bs4` (BeautifulSoup)
  - `uuid`
- **Java**: Required to run **EPUBCheck**, which is included in the software.
- **ImageMagick**: Required for image processing.
- **Zip**: Required for EPUB archive creation.

### Installation Steps

1. Install the required dependencies:
   - **ubuntu|debian|linuxmint**:
     ```sh
     sudo apt install zenity imagemagick zip default-jre python3 jq
     ```
   - **fedora|centos|rhel**:
     ```sh
     sudo dnf install zenity imagemagick zip default-jre python3 jq
     ```
   - **opensuse**:
     ```sh
     sudo zypper install zenity imagemagick zip default-jre python3 jq
     ```
   - **arch**:
     ```sh
     sudo pacman -S zenity imagemagick zip default-jre python3 jq
     ```
   - **Python libraries**:
     ```sh
     pip install bs4 os json pathlib subprocess re sys xml.etree.ElementTree datetime time uuid
     ```
2. Clone the repository:
   ```sh
   git clone https://github.com/bernardus-fr/librifix.git
   cd librifix
   ```
3. Run Librifix:
   ```sh
   ./librifix.sh
   ```

## Usage

Librifix works by analyzing a folder containing the user's text and media files to generate a compliant EPUB.

### File Organization

The user must organize files within a dedicated folder using a well-defined structure based on filenames and extensions:

- **Images**:
  - Cover image: `cover.[jpg|jpeg|png]`
  - Back cover: `4cover.[jpg|jpeg|png]`
- **Text files**:
  - Title page: `page_de_garde.xhtml`
  - Preface: `preface.txt`
  - Introduction: `introduction.txt`
  - Chapters: `chapitre[X].txt` (`[X]` is the numeric chapter index; at least one chapter is required)
  - Supplements, appendices: `complement[X].txt` (`[X]` is the numeric supplement index)
- **Footnotes**:
  - Preface notes: `notes_preface.txt`
  - Introduction notes: `notes_introduction.txt`
  - Chapter notes: `notes_chapitre[X].txt` (the numeric index must match the chapter number)
  - Supplement notes: `notes_complement[X].txt` (the numeric index must match the supplement number)
- **Other File Support**:
  - **XHTML files** are directly recognized.
  - Users may provide their own stylesheets and fonts.
  - **Fonts** must be provided with pre-defined stylesheets.
  - If the user provides **TXT files**, stylesheets should be named `style-[garde|global|index|notes]`.
  - If **chapters are already formatted in XHTML**, they can have different names.
  - **Additional images** and **media** for book content are not yet supported.

### Text File Formatting Rules

- The first line of the file must be the chapter title.
- Footnote references within a chapter should be formatted as numbers in parentheses: `(1)`, `(2)`, `(X)`, etc.
- In footnote files, each note should start with a number followed by a closing parenthesis: `1)`, `2)`, `X)`, etc.

### Running the Software

From the root directory of the program, execute the following command:

```sh
./librifix.sh
```

### Result

Find the final file '**livre.epub**' in the '**temp**' folder of the program.

## Version History

### Alpha Version 1.XX

- v1.0: Initial functional version of the project.
- v1.1: 2025-02-06 Minor update - small improvements
- v1.2: 2025-02-08 Current version. See [CHANGELOG.md](CHANGELOG.md) for details.

### Beta Version 2.0 (Upcoming)

- Performance optimization
- Bug fixes
- Addition of new features

### Release Version 3.0 (Planned)

- Stable and finalized version

## License

### Project License

Librifix is distributed under the **GNU General Public License v3 (GPL v3)**. See the [LICENSE](LICENSE) file for more details.

Librifix is free software; you may redistribute and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License or (at your option) any later version.

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of **MERCHANTABILITY** or **FITNESS FOR A PARTICULAR PURPOSE**. See the GNU General Public License for more details.

### Third-Party Licenses

This project includes the following third-party libraries:

- **BeautifulSoup 4** (MIT License)
- **EPUBCheck** (Apache 2.0 License)

Please see the [third\_party\_licenses.md](third_party_licenses.md) file for more information on these libraries and their licenses.

