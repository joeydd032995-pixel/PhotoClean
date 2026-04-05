// Utilities/Formatting.swift
// Shared formatting helpers used across views.

import Foundation

extension Int64 {
    /// Human-readable byte count: "1.23 GB", "4.5 MB", "512 B".
    func formattedBytes() -> String {
        let gb = Double(self) / 1_073_741_824
        if gb >= 1 { return String(format: "%.2f GB", gb) }
        let mb = Double(self) / 1_048_576
        if mb >= 0.1 { return String(format: "%.1f MB", mb) }
        return "\(self) B"
    }
}
