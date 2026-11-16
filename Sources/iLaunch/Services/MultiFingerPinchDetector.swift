import Foundation

struct PinchContact {
    let id: Int32
    let x: Double
    let y: Double
}

/// Tracks four- or five-contact pinches without relying on thumb shape.
enum PinchDirection {
    case inward
    case outward
}

struct MultiFingerPinchDetector {
    private var identifiers: [Int32] = []
    private var initialRadius = 0.0
    private var startedAt = 0.0
    private var fired = false
    private var lastTrigger = -Double.infinity

    mutating func update(_ contacts: [PinchContact], timestamp: Double) -> PinchDirection? {
        guard (4...5).contains(contacts.count) else {
            identifiers = []
            if contacts.isEmpty { fired = false }
            return nil
        }
        let sorted = contacts.sorted { $0.id < $1.id }
        let ids = sorted.map(\.id)
        let centerX = sorted.reduce(0.0) { $0 + $1.x } / Double(sorted.count)
        let centerY = sorted.reduce(0.0) { $0 + $1.y } / Double(sorted.count)
        let radius = sorted.reduce(0.0) {
            $0 + hypot($1.x - centerX, $1.y - centerY)
        } / Double(sorted.count)
        guard radius.isFinite else { return nil }
        if identifiers != ids {
            identifiers = ids
            initialRadius = radius
            startedAt = timestamp
            return nil
        }
        guard !fired, initialRadius >= 0.08,
              timestamp - startedAt >= 0.08,
              timestamp - lastTrigger >= 0.7 else { return nil }
        let ratio = radius / initialRadius
        let direction: PinchDirection
        if ratio <= 0.78 {
            direction = .inward
        } else if ratio >= 1.25 {
            direction = .outward
        } else {
            return nil
        }
        fired = true
        lastTrigger = timestamp
        return direction
    }
}
