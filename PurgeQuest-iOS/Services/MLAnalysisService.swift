// Services/MLAnalysisService.swift
// On-device photo analysis: blur detection, duplicate clustering,
// screenshot detection, quality scoring – all via Vision framework.
// No network calls. No data leaves the device.

import Vision
import Photos
import UIKit
import CoreImage
import Accelerate

// ─── Photo Analysis Result ────────────────────────────────────────────────────

struct PhotoAnalysisResult {
    let assetLocalID: String
    let isBlurry: Bool
    let isScreenshot: Bool
    let isDuplicate: Bool
    let qualityScore: Double       // 0.0 (terrible) → 1.0 (excellent)
    let isOld: Bool                // creationDate > 5 years ago
    let isDark: Bool               // underexposed
    let featurePrint: VNFeaturePrintObservation?  // for duplicate grouping
    var suggestedMonsterType: MonsterType {
        if isDuplicate        { return .duplicateDragon }
        if isBlurry           { return .blurryBeast }
        if isScreenshot       { return .screenshotSpecter }
        if qualityScore < 0.3 { return .lowQualityGoblin }
        if isDark             { return .darkShadowDemon }
        if isOld              { return .oldRelicWraith }
        return .lowQualityGoblin
    }
}

// ─── Batch Grouping Result ────────────────────────────────────────────────────

struct PhotoGroup {
    let monsterType: MonsterType
    let assetLocalIDs: [String]
    let assetByteSizes: [Int64]
}

// ─── Service ──────────────────────────────────────────────────────────────────

actor MLAnalysisService {

    static let shared = MLAnalysisService()
    private init() {}

    // ─── Analyze a batch of assets and group into dungeon rooms ───────────────

    func analyzeAndGroup(assets: [PHAsset]) async -> [PhotoGroup] {
        // Step 1: Analyze all assets concurrently (but throttled to avoid memory pressure)
        var results: [PhotoAnalysisResult] = []
        let chunkSize = 20
        var index = 0
        while index < assets.count {
            let chunk = Array(assets[index..<min(index + chunkSize, assets.count)])
            let chunkResults = await withTaskGroup(of: PhotoAnalysisResult?.self,
                                                   returning: [PhotoAnalysisResult].self) { group in
                for asset in chunk {
                    group.addTask { await self.analyzeAsset(asset) }
                }
                var out: [PhotoAnalysisResult] = []
                for await r in group { if let r { out.append(r) } }
                return out
            }
            results.append(contentsOf: chunkResults)
            index += chunkSize
        }

        // Step 2: Find duplicates via feature-print clustering
        let duplicateIDs = clusterDuplicates(results: results, threshold: 0.12)
        var markedResults = results.map { r -> PhotoAnalysisResult in
            var mut = r
            if duplicateIDs.contains(r.assetLocalID) {
                mut = PhotoAnalysisResult(
                    assetLocalID: r.assetLocalID, isBlurry: r.isBlurry,
                    isScreenshot: r.isScreenshot, isDuplicate: true,
                    qualityScore: r.qualityScore, isOld: r.isOld, isDark: r.isDark,
                    featurePrint: r.featurePrint
                )
            }
            return mut
        }

        // Step 3: Group by monster type
        let fileSizes = await fetchFileSizes(for: assets, results: &markedResults)
        return buildGroups(from: markedResults, fileSizes: fileSizes)
    }

    // ─── Single asset analysis ────────────────────────────────────────────────

    func analyzeAsset(_ asset: PHAsset) async -> PhotoAnalysisResult? {
        guard let image = await loadCGImage(asset: asset) else { return nil }

        async let blurry = detectBlur(image: image)
        async let screenshot = detectScreenshot(asset: asset, image: image)
        async let quality = scoreQuality(image: image)
        async let dark = detectDark(image: image)
        async let fp = generateFeaturePrint(image: image)

        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: .now)!
        let isOld = (asset.creationDate ?? .now) < fiveYearsAgo

        return PhotoAnalysisResult(
            assetLocalID: asset.localIdentifier,
            isBlurry: await blurry,
            isScreenshot: await screenshot,
            isDuplicate: false,          // set later after clustering
            qualityScore: await quality,
            isOld: isOld,
            isDark: await dark,
            featurePrint: await fp
        )
    }

    // ─── Blur Detection (Laplacian variance via vImage) ───────────────────────

    private func detectBlur(image: CGImage) async -> Bool {
        // Convert to grayscale
        guard let gray = grayscale(cgImage: image) else { return false }
        let variance = laplacianVariance(of: gray)
        return variance < 80.0   // threshold tuned empirically
    }

    private func grayscale(cgImage: CGImage) -> CGImage? {
        let w = cgImage.width, h = cgImage.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()
    }

    private func laplacianVariance(of cgImage: CGImage) -> Double {
        let w = cgImage.width, h = cgImage.height
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }
        // Laplacian kernel: [0,1,0,1,-4,1,0,1,0]
        var sum: Double = 0, sumSq: Double = 0, count: Double = 0
        for y in 1..<(h - 1) {
            for x in 1..<(w - 1) {
                let lap = Double(ptr[(y-1)*w+x]) + Double(ptr[(y+1)*w+x])
                          + Double(ptr[y*w+(x-1)]) + Double(ptr[y*w+(x+1)])
                          - 4.0 * Double(ptr[y*w+x])
                sum += lap; sumSq += lap * lap; count += 1
            }
        }
        guard count > 0 else { return 0 }
        let mean = sum / count
        return (sumSq / count) - (mean * mean)
    }

    // ─── Screenshot Detection ─────────────────────────────────────────────────

    private func detectScreenshot(asset: PHAsset, image: CGImage) async -> Bool {
        // Primary signal: PHAsset subtype
        if asset.mediaSubtypes.contains(.photoScreenshot) { return true }

        // Secondary: aspect ratio check (full-screen screenshots have device aspect ratios)
        let w = Double(asset.pixelWidth), h = Double(asset.pixelHeight)
        let ratio = w / h
        let commonRatios: [Double] = [9/19.5, 9/20, 9/16, 375/812, 390/844, 393/852]
        let isCommonRatio = commonRatios.contains { abs($0 - ratio) < 0.01 }

        // Tertiary: dense text via VNRecognizeTextRequest
        if isCommonRatio {
            let hasText = await detectDenseText(image: image)
            return hasText
        }
        return false
    }

    private func detectDenseText(image: CGImage) async -> Bool {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: observations.count > 10)
            }
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    // ─── Quality Score via VNDetectFaceRectanglesRequest + brightness ─────────

    private func scoreQuality(image: CGImage) async -> Double {
        // Use average brightness as a proxy for quality
        let brightness = averageBrightness(of: image)
        // 0.05-0.7 is "reasonable" exposure range
        if brightness < 0.05 || brightness > 0.95 { return 0.2 }
        return min(1.0, (brightness / 0.7) * 0.8 + 0.2)
    }

    private func averageBrightness(of cgImage: CGImage) -> Double {
        guard let gray = grayscale(cgImage: cgImage),
              let data = gray.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0.5 }
        let count = gray.width * gray.height
        guard count > 0 else { return 0.5 }
        var total: UInt64 = 0
        for i in 0..<count { total += UInt64(ptr[i]) }
        return Double(total) / (Double(count) * 255.0)
    }

    private func detectDark(image: CGImage) -> Bool {
        averageBrightness(of: image) < 0.10
    }

    // ─── Feature Print for Duplicate Clustering ───────────────────────────────

    private func generateFeaturePrint(image: CGImage) async -> VNFeaturePrintObservation? {
        await withCheckedContinuation { continuation in
            let request = VNGenerateImageFeaturePrintRequest { req, _ in
                continuation.resume(returning: req.results?.first as? VNFeaturePrintObservation)
            }
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    private func clusterDuplicates(results: [PhotoAnalysisResult], threshold: Float) -> Set<String> {
        var duplicates = Set<String>()
        let withPrint = results.compactMap { r -> (String, VNFeaturePrintObservation)? in
            guard let fp = r.featurePrint else { return nil }
            return (r.assetLocalID, fp)
        }
        for i in 0..<withPrint.count {
            for j in (i+1)..<withPrint.count {
                var dist: Float = 0
                try? withPrint[i].1.computeDistance(&dist, to: withPrint[j].1)
                if dist < threshold {
                    duplicates.insert(withPrint[i].0)
                    duplicates.insert(withPrint[j].0)
                }
            }
        }
        return duplicates
    }

    // ─── Build Groups ─────────────────────────────────────────────────────────

    private func buildGroups(from results: [PhotoAnalysisResult], fileSizes: [String: Int64]) -> [PhotoGroup] {
        var byType: [MonsterType: [PhotoAnalysisResult]] = [:]
        for r in results {
            let type = r.suggestedMonsterType
            byType[type, default: []].append(r)
        }
        return byType.map { type, items in
            let ids = items.map(\.assetLocalID)
            let sizes = ids.map { fileSizes[$0] ?? 0 }
            return PhotoGroup(monsterType: type, assetLocalIDs: ids, assetByteSizes: sizes)
        }.sorted { $0.assetLocalIDs.count > $1.assetLocalIDs.count }
    }

    private func fetchFileSizes(for assets: [PHAsset],
                                 results: inout [PhotoAnalysisResult]) async -> [String: Int64] {
        var out: [String: Int64] = [:]
        for asset in assets {
            let resources = PHAssetResource.assetResources(for: asset)
            let res = resources.first(where: { $0.type == .photo }) ?? resources.first
            let size = res?.value(forKey: "fileSize") as? Int64 ?? 0
            out[asset.localIdentifier] = size
        }
        return out
    }

    // ─── Helper: Load CGImage ─────────────────────────────────────────────────

    private func loadCGImage(asset: PHAsset) async -> CGImage? {
        await withCheckedContinuation { continuation in
            let opts = PHImageRequestOptions()
            opts.isSynchronous = false
            opts.deliveryMode = .fastFormat   // speed > quality for analysis
            opts.resizeMode = .fast
            opts.isNetworkAccessAllowed = false
            let target = CGSize(width: 512, height: 512)
            PHImageManager.default().requestImage(
                for: asset, targetSize: target,
                contentMode: .aspectFit, options: opts
            ) { image, info in
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !degraded { continuation.resume(returning: image?.cgImage) }
            }
        }
    }
}
