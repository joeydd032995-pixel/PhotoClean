// Services/PhotoLibraryService.swift
// All PHPhotoLibrary access: authorization, fetching, analyzing, and safe deletion.

import Photos
import PhotosUI
import UIKit
import SwiftUI

// ─── Authorization ────────────────────────────────────────────────────────────

@MainActor
final class PhotoLibraryService {

    static let shared = PhotoLibraryService()
    private init() {}

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // ─── Fetch All Assets ──────────────────────────────────────────────────────

    func fetchAllPhotoAssets() -> PHFetchResult<PHAsset> {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opts.includeAssetSourceTypes = [.typeUserLibrary]
        return PHAsset.fetchAssets(with: .image, options: opts)
    }

    func fetchAllVideoAssets() -> PHFetchResult<PHAsset> {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .video, options: opts)
    }

    // ─── Fetch image for a single asset ───────────────────────────────────────

    func loadImage(for asset: PHAsset, targetSize: CGSize = CGSize(width: 800, height: 800)) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let opts = PHImageRequestOptions()
            opts.isSynchronous = false
            opts.deliveryMode = .highQualityFormat
            opts.resizeMode = .fast
            opts.isNetworkAccessAllowed = false  // on-device only
            manager.requestImage(for: asset, targetSize: targetSize,
                                 contentMode: .aspectFit, options: opts) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
                // if degraded a second call will come; ignore first
            }
        }
    }

    func loadThumbnail(for asset: PHAsset) async -> UIImage? {
        await loadImage(for: asset, targetSize: CGSize(width: 200, height: 200))
    }

    func loadFullResolution(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let opts = PHImageRequestOptions()
            opts.isSynchronous = false
            opts.deliveryMode = .highQualityFormat
            opts.isNetworkAccessAllowed = false
            manager.requestImageDataAndOrientation(for: asset, options: opts) { data, _, _, _ in
                if let data, let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // ─── File Size ─────────────────────────────────────────────────────────────

    func fileSize(for asset: PHAsset) async -> Int64 {
        await withCheckedContinuation { continuation in
            let resources = PHAssetResource.assetResources(for: asset)
            let resource = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto })
                           ?? resources.first
            guard let res = resource else {
                continuation.resume(returning: 0)
                return
            }
            let size = res.value(forKey: "fileSize") as? Int64 ?? 0
            continuation.resume(returning: size)
        }
    }

    func fileSizes(for assets: [PHAsset]) async -> [Int64] {
        await withTaskGroup(of: (Int, Int64).self, returning: [Int64].self) { group in
            for (i, asset) in assets.enumerated() {
                group.addTask {
                    let size = await self.fileSize(for: asset)
                    return (i, size)
                }
            }
            var sizes = [Int64](repeating: 0, count: assets.count)
            for await (i, size) in group {
                sizes[i] = size
            }
            return sizes
        }
    }

    // ─── Safe Bulk Delete ──────────────────────────────────────────────────────

    /// Deletes assets by local identifier. Returns count of successfully deleted assets.
    /// Must be called after user confirmation UI.
    func deleteAssets(localIDs: [String]) async throws -> Int {
        let opts = PHFetchOptions()
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: localIDs, options: opts)
        var assetsToDelete: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in assetsToDelete.append(asset) }

        guard !assetsToDelete.isEmpty else { return 0 }

        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
            } completionHandler: { success, error in
                if success {
                    continuation.resume(returning: assetsToDelete.count)
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.deleteFailed)
                }
            }
        }
    }

    // ─── Statistics ───────────────────────────────────────────────────────────

    func totalLibraryStats() async -> LibraryStats {
        let photos = fetchAllPhotoAssets()
        let videos = fetchAllVideoAssets()

        // Sample 200 assets for size estimate (full scan is too slow)
        let sampleCount = min(200, photos.count)
        var sampleAssets: [PHAsset] = []
        if sampleCount > 0 {
            let stride = max(1, photos.count / sampleCount)
            var i = 0
            while i < photos.count && sampleAssets.count < sampleCount {
                sampleAssets.append(photos[i])
                i += stride
            }
        }

        let sampleSizes = await fileSizes(for: sampleAssets)
        let avgSize = sampleSizes.isEmpty ? 0 : sampleSizes.reduce(0, +) / Int64(sampleSizes.count)
        let estimatedTotalBytes = avgSize * Int64(photos.count)

        return LibraryStats(
            totalPhotoCount: photos.count,
            totalVideoCount: videos.count,
            estimatedTotalBytes: estimatedTotalBytes
        )
    }
}

struct LibraryStats {
    let totalPhotoCount: Int
    let totalVideoCount: Int
    let estimatedTotalBytes: Int64

    var estimatedGB: Double { Double(estimatedTotalBytes) / 1_073_741_824 }
    var estimatedMB: Double { Double(estimatedTotalBytes) / 1_048_576 }
}

enum PhotoLibraryError: LocalizedError {
    case notAuthorized
    case deleteFailed
    case assetNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Photo library access not authorized."
        case .deleteFailed:  return "Failed to delete photos."
        case .assetNotFound: return "Photo asset not found."
        }
    }
}
