import Foundation
import Observation

@Observable
@MainActor
final class PayViewModel {
    static let maxAmount = Decimal(999_999) / 100 // $9,999.99
    private static let maxFractionDigits = 2
    private static let locale = Locale(identifier: "en_US")

    /// The raw keypad entry, e.g. "1250.5".
    private(set) var entry = "0"
    /// Incremented on each accepted key press; drives the selection haptic.
    private(set) var validInputCount = 0
    /// Incremented on each rejected key press; drives the shake and warning haptic.
    private(set) var invalidInputCount = 0

    var amount: Decimal { Self.value(of: entry) }

    var isZero: Bool { amount == 0 }

    /// The entry formatted with a thousands separator, keeping any trailing "." or zeros as typed.
    var displayText: String {
        let parts = entry.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let whole = Int(parts[0]) ?? 0
        var text = "$" + whole.formatted(.number.locale(Self.locale))
        if parts.count > 1 {
            text += "." + parts[1]
        }
        return text
    }

    var accessibilityAmount: String {
        amount.formatted(.currency(code: "USD").locale(Self.locale))
    }

    func press(_ key: KeypadKey) {
        if let next = nextEntry(after: key) {
            entry = next
            validInputCount += 1
        } else {
            invalidInputCount += 1
        }
    }

    func pay() {
        print("Pay \(amount)")
    }

    func request() {
        print("Request \(amount)")
    }

    /// Returns the entry after applying `key`, or nil if the key press is invalid.
    private func nextEntry(after key: KeypadKey) -> String? {
        switch key {
        case .backspace:
            guard entry != "0" else { return nil }
            let trimmed = String(entry.dropLast())
            return trimmed.isEmpty ? "0" : trimmed

        case .decimal:
            guard !entry.contains(".") else { return nil }
            return entry + "."

        case .digit(let digit):
            let candidate: String
            if entry == "0" {
                guard digit != 0 else { return nil }
                candidate = String(digit)
            } else {
                if let dot = entry.firstIndex(of: "."),
                   entry[entry.index(after: dot)...].count >= Self.maxFractionDigits {
                    return nil
                }
                candidate = entry + String(digit)
            }
            guard Self.value(of: candidate) <= Self.maxAmount else { return nil }
            return candidate
        }
    }

    private static func value(of entry: String) -> Decimal {
        let normalized = entry.hasSuffix(".") ? String(entry.dropLast()) : entry
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}
