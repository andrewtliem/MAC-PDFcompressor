//
//  ContentView.swift
//  MACPDFCompressor
//
//  Created by Andrew Tanny Liem on 14/07/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct PDFCompressionResult: Identifiable {
    let id = UUID()
    let fileName: String
    let originalSize: Int64
    let compressedSize: Int64?
    let outputURL: URL?
    let error: String?
    var ratioString: String {
        guard let compressedSize, error == nil else { return "-" }
        let percent = 100.0 * (1.0 - Double(compressedSize) / Double(originalSize))
        return String(format: "%.1f%%", percent)
    }
}

struct ContentView: View {
    @State private var selectedFileURLs: [URL] = []
    @State private var statusMessage: String = "Ready"
    @State private var isFileImporterPresented: Bool = false
    @State private var isTargeted: Bool = false
    @State private var ghostscriptQuality: GhostscriptQuality = .ebook
    @State private var removeMetadata: Bool = true
    @State private var isProcessing: Bool = false
    @State private var progress: Double = 0.0
    @State private var results: [PDFCompressionResult] = []
    @State private var currentFileIndex: Int = 0
    
    var body: some View {
        ZStack {
            Color(.windowBackgroundColor)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                // Branding/Header
                VStack(spacing: 8) {
                    Text("atlverse PDF Compressor")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.primary)
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 2)
                        .accessibilityLabel("atlverse PDF Compressor")
                    Text("Efficient PDF compression made simple")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Efficient PDF compression made simple")
                }
                .padding(.top, 36)
                // Drop Zone
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isTargeted ? Color.accentColor : Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 3, dash: [8]))
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color(NSColor.controlBackgroundColor)))
                        .frame(height: 180)
                    VStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .foregroundColor(Color.accentColor)
                        if selectedFileURLs.isEmpty {
                            Text("Drop your PDF file(s) here or click to browse")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .accessibilityHint("Drop PDF files or click to select")
                        } else {
                            VStack(spacing: 2) {
                                ForEach(selectedFileURLs, id: \.self) { url in
                                    Text(url.lastPathComponent)
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        Text("Maximum file size: 50MB each")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    isFileImporterPresented = true
                }
                .onDrop(of: [UTType.pdf], isTargeted: $isTargeted) { providers in
                    var newFiles: [URL] = []
                    let group = DispatchGroup()
                    for provider in providers {
                        group.enter()
                        _ = provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { url, inPlace, error in
                            if let url = url {
                                DispatchQueue.main.async {
                                    newFiles.append(url)
                                }
                            }
                            group.leave()
                        }
                    }
                    group.notify(queue: .main) {
                        selectedFileURLs.append(contentsOf: newFiles)
                        selectedFileURLs = Array(Set(selectedFileURLs)) // Remove duplicates
                    }
                    return true
                }
                .fileImporter(
                    isPresented: $isFileImporterPresented,
                    allowedContentTypes: [.pdf],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case .success(let urls):
                        selectedFileURLs.append(contentsOf: urls)
                        selectedFileURLs = Array(Set(selectedFileURLs)) // Remove duplicates
                    case .failure(let error):
                        statusMessage = "Error: \(error.localizedDescription)"
                    }
                }
                // Compression Settings
                ZStack {
                    // Card background with gradient and shadow
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [Color(NSColor.windowBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.95)]), startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.accentColor)
                                .imageScale(.large)
                            Text("Compression Settings")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .accessibilityAddTraits(.isHeader)
                        }
                        Divider()
                        Text("Choose your preferred compression quality and options.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 4) {
                                Text("Ghostscript Quality")
                                    .font(.body)
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.accentColor)
                                    .help("Choose the quality preset for compression. Lower quality means smaller file size.")
                            }
                            Picker("", selection: $ghostscriptQuality) {
                                ForEach(GhostscriptQuality.allCases, id: \.self) { quality in
                                    Text(quality.displayName).tag(quality)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 260)
                            .accessibilityLabel("Ghostscript Quality")
                            .labelsHidden()
                            HStack(spacing: 4) {
                                Toggle("Remove metadata", isOn: $removeMetadata)
                                    .accessibilityLabel("Remove metadata")
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.accentColor)
                                    .help("Removes metadata such as author, title, and creation date from the PDF.")
                            }
                        }
                    }
                    .padding(22)
                }
                .padding(.horizontal, 0)
                // Progress Indicator
                if isProcessing {
                    VStack(spacing: 8) {
                        ProgressView(value: progress, total: Double(selectedFileURLs.count)) {
                            Text("Compressing PDF \(currentFileIndex+1) of \(selectedFileURLs.count)...")
                                .font(.body)
                        }
                        .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding(.horizontal, 40)
                }
                // Compress Button
                Button(action: {
                    compressBatch()
                }) {
                    Text(selectedFileURLs.count > 1 ? "Compress PDFs" : "Compress PDF")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(color: .accentColor.opacity(0.3), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(selectedFileURLs.isEmpty || isProcessing)
                .padding(.horizontal, 40)
                .accessibilityLabel("Compress PDF")
                .accessibilityHint("Starts compressing the selected PDF files")
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.arrow.push()
                    }
                }
                // Results Table
                if !results.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color(NSColor.windowBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.95)]), startPoint: .top, endPoint: .bottom))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundColor(.accentColor)
                                    .imageScale(.large)
                                Text("Results:")
                                    .font(.headline)
                            }
                            ForEach(results.indices, id: \.self) { idx in
                                let result = results[idx]
                                HStack(alignment: .center, spacing: 12) {
                                    if result.error == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "xmark.octagon.fill")
                                            .foregroundColor(.red)
                                    }
                                    Text(result.outputURL?.lastPathComponent ?? result.fileName)
                                        .font(.body)
                                        .frame(width: 220, alignment: .leading)
                                    if let compressedSize = result.compressedSize, result.error == nil {
                                        Text("\(formatSize(result.originalSize)) → \(formatSize(compressedSize)) (") +
                                        Text(result.ratioString).foregroundColor(.green) + Text(")")
                                    } else {
                                        Text("Failed").foregroundColor(.red)
                                    }
                                    if let error = result.error {
                                        Text(error).foregroundColor(.red).font(.footnote)
                                    }
                                }
                                if idx < results.count - 1 {
                                    Divider()
                                }
                            }
                            HStack {
                                Spacer()
                                Button(action: {
                                    // Open Downloads folder
                                    let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                                    if let url = downloadsURL {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "folder")
                                        Text("Show in Finder")
                                    }
                                    .font(.body)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.top, 6)
                        }
                        .padding(22)
                    }
                    .padding(.horizontal, 0)
                    // Move info text here
                    Text("Compressed files will be saved in Downloads, with .compressed.pdf added to the name.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                // Status
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
    }
    
    func compressBatch() {
        results = []
        isProcessing = true
        progress = 0
        currentFileIndex = 0
        statusMessage = "Starting compression..."
        DispatchQueue.global(qos: .userInitiated).async {
            var batchResults: [PDFCompressionResult] = []
            for (idx, url) in selectedFileURLs.enumerated() {
                let result = compressPDFSync(inputURL: url, quality: ghostscriptQuality, removeMetadata: removeMetadata)
                batchResults.append(result)
                DispatchQueue.main.async {
                    currentFileIndex = idx
                    progress = Double(idx + 1)
                    results = batchResults
                }
            }
            DispatchQueue.main.async {
                isProcessing = false
                statusMessage = "Batch compression complete."
                selectedFileURLs = []
                progress = 0
                currentFileIndex = 0
            }
        }
    }

    // Synchronous version for background thread
    func compressPDFSync(inputURL: URL, quality: GhostscriptQuality, removeMetadata: Bool) -> PDFCompressionResult {
        // 1. Get Ghostscript binary path in app bundle
        guard let gsPath = Bundle.main.path(forResource: "gs", ofType: nil) else {
            return PDFCompressionResult(fileName: inputURL.lastPathComponent, originalSize: fileSize(inputURL), compressedSize: nil, outputURL: nil, error: "Ghostscript binary not found in app bundle.")
        }
        
        // 1.5. Copy input PDF to a temp directory to ensure sandbox access
        print("NSTemporaryDirectory(): \(NSTemporaryDirectory())")
        var tempInputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(inputURL.lastPathComponent)
        var copySucceeded = false
        do {
            if FileManager.default.fileExists(atPath: tempInputURL.path) {
                try FileManager.default.removeItem(at: tempInputURL)
            }
            try FileManager.default.copyItem(at: inputURL, to: tempInputURL)
            copySucceeded = true
        } catch {
            // Fallback: Try Application Support directory
            if let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                do {
                    try FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
                    let fallbackURL = appSupportDir.appendingPathComponent(inputURL.lastPathComponent)
                    if FileManager.default.fileExists(atPath: fallbackURL.path) {
                        try FileManager.default.removeItem(at: fallbackURL)
                    }
                    try FileManager.default.copyItem(at: inputURL, to: fallbackURL)
                    tempInputURL = fallbackURL
                    copySucceeded = true
                } catch {
                    return PDFCompressionResult(fileName: inputURL.lastPathComponent, originalSize: fileSize(inputURL), compressedSize: nil, outputURL: nil, error: "Failed to copy PDF to temp or app support directory: \(error.localizedDescription)")
                }
            } else {
                return PDFCompressionResult(fileName: inputURL.lastPathComponent, originalSize: fileSize(inputURL), compressedSize: nil, outputURL: nil, error: "Failed to access Application Support directory.")
            }
        }
        if !copySucceeded {
            return PDFCompressionResult(fileName: inputURL.lastPathComponent, originalSize: fileSize(inputURL), compressedSize: nil, outputURL: nil, error: "Failed to copy PDF to temp or app support directory.")
        }
        
        // 2. Ask user for output location (for batch, auto-save next to input file)
        let outputURL = inputURL.deletingPathExtension().appendingPathExtension("compressed.pdf")
        
        // 3. Build Ghostscript arguments
        let pdfSettings: String
        switch quality {
        case .screen: pdfSettings = "/screen"
        case .ebook: pdfSettings = "/ebook"
        case .printer: pdfSettings = "/printer"
        case .prepress: pdfSettings = "/prepress"
        case .defaultQuality: pdfSettings = "/default"
        }
        var args = [
            "-sDEVICE=pdfwrite",
            "-dCompatibilityLevel=1.4",
            "-dPDFSETTINGS=\(pdfSettings)",
            "-dNOPAUSE",
            "-dQUIET",
            "-dBATCH",
            "-sOutputFile=\(outputURL.path)",
            tempInputURL.path
        ]
        if removeMetadata {
            args.insert("-dDetectDuplicateImages=true", at: 3)
            args.insert("-dRemoveMetadata=true", at: 4)
        }
        
        // 4. Run Ghostscript process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gsPath)
        process.arguments = args
        
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let compressedSize = fileSize(outputURL)
                return PDFCompressionResult(fileName: inputURL.lastPathComponent, originalSize: fileSize(inputURL), compressedSize: compressedSize, outputURL: outputURL, error: nil)
            } else {
                return PDFCompressionResult(fileName: inputURL.lastPathComponent, originalSize: fileSize(inputURL), compressedSize: nil, outputURL: nil, error: "Compression failed (exit code: \(process.terminationStatus))")
            }
        } catch {
            return PDFCompressionResult(fileName: inputURL.lastPathComponent, originalSize: fileSize(inputURL), compressedSize: nil, outputURL: nil, error: "Failed to run Ghostscript: \(error.localizedDescription)")
        }
    }
    
    func fileSize(_ url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }
    
    func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// Ghostscript quality presets
enum GhostscriptQuality: String, CaseIterable, Identifiable {
    case screen, ebook, printer, prepress, defaultQuality
    
    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .screen: return "Screen (lowest quality, smallest size)"
        case .ebook: return "eBook (good quality, small size)"
        case .printer: return "Printer (high quality, larger size)"
        case .prepress: return "Prepress (highest quality, largest size)"
        case .defaultQuality: return "Default"
        }
    }
}

#Preview {
    ContentView()
}
