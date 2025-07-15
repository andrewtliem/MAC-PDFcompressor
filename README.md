# MACPDFCompressor

A native macOS app built with SwiftUI that compresses PDF files using Ghostscript. Supports batch processing, progress indication, and shows compression ratios for each file.

## Features
- Drag-and-drop or select multiple PDF files for compression
- Choose compression quality and remove metadata
- Progress indicator and results table
- Compressed files are saved in the same folder as the original (e.g., Downloads), with `.compressed.pdf` added to the name

## Download
You can download the latest prebuilt version of the app here:

👉 [https://atlverse.xyz/pdfcompressor.html](https://atlverse.xyz/pdfcompressor.html)

If you prefer to build from source, see the instructions below.

## Requirements
- **macOS 14+ (Sonoma or later)**
- **Apple Silicon (M1/M2/M3)**
- Xcode 14+
- **Ghostscript static binary** (not included in this repository)

> **Note:** This app is only supported on Apple Silicon Macs running macOS 14 or later. It will not run on Intel Macs or earlier macOS versions.

## Ghostscript Binary
**This repository does NOT include the Ghostscript (`gs`) binary.**

You must build or obtain your own static Ghostscript binary for macOS and place it at:

```
MACPDFCompressor/Tools/gs
```

### How to Build a Static Ghostscript Binary
1. Download the Ghostscript source from [https://ghostscript.com/download/gsdnld.html](https://ghostscript.com/download/gsdnld.html)
2. Extract and open a terminal in the source directory
3. Run:
   ```sh
   ./configure --disable-shared --enable-static --without-fontconfig --without-freetype --without-libidn --prefix=/tmp/gs-static
   make clean
   make -j$(sysctl -n hw.ncpu)
   make install
   cp /tmp/gs-static/bin/gs /path/to/your/project/MACPDFCompressor/Tools/gs
   chmod +x /path/to/your/project/MACPDFCompressor/Tools/gs
   ```
4. Make sure the binary is executable and included in your Xcode project (with target membership enabled).

If you want to use a prebuilt Ghostscript binary, ensure it is statically linked and does not depend on Homebrew or other external libraries.

## Building the App
1. Open the project in Xcode.
2. Make sure the Ghostscript binary is present as described above.
3. Build and run the app.

## License
MIT 