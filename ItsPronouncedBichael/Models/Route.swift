import Accelerate
import SwiftData
import CoreLocation

@Model
final class Route {
    var start: Date?
    var end: Date?

    @Relationship(deleteRule: .cascade, inverse: \RoutePoint.route)
    var points: [RoutePoint]? = []

    var cachedDistance: Double = 0
    var cachedAverageSpeed: Double = 0
    var cachedMaxSpeed: Double = 0

    init() {}
}

extension Route {
    /// SwiftData to-many relationships are unordered, so points must be sorted back into travel order.
    var allLocations: [RouteLocation] {
        (points ?? [])
            .sorted { $0.timestamp < $1.timestamp }
            .map { RouteLocation($0) }
    }

    var distance: Measurement<UnitLength> {
        Measurement(value: cachedDistance, unit: .meters)
    }

    var averageSpeed: Measurement<UnitSpeed> {
        Measurement(value: cachedAverageSpeed, unit: .metersPerSecond)
    }

    var maxSpeed: Measurement<UnitSpeed> {
        Measurement(value: cachedMaxSpeed, unit: .metersPerSecond)
    }

    func recomputeStats() {
        let source = allLocations
        let speeds = source.map { $0.speed.value }
        cachedAverageSpeed = speeds.isEmpty ? 0 : vDSP.mean(speeds)
        cachedMaxSpeed = speeds.isEmpty ? 0 : vDSP.maximum(speeds)

        let mapped = source.map { CLLocation($0) }
        cachedDistance = zip(mapped.dropLast(), mapped.dropFirst())
            .map { $1.distance(from: $0) }
            .reduce(0, +)
    }
}
