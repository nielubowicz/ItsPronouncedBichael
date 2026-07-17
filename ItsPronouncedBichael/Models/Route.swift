import Accelerate
import SwiftData
import CoreLocation

@Model
final class Route {
    var start: Date?
    var end: Date?
    var locations: [RouteLocation] = [RouteLocation]()

    var cachedDistance: Double = 0
    var cachedAverageSpeed: Double = 0
    var cachedMaxSpeed: Double = 0
    var statsComputed: Bool = false

    init(initialRoute: [CLLocation]) {
        self.locations = initialRoute.map { RouteLocation($0) }
    }
}

extension Route {
    var distance: Measurement<UnitLength> {
        Measurement(value: cachedDistance, unit: .meters)
    }

    var averageSpeed: Measurement<UnitSpeed> {
        Measurement(value: cachedAverageSpeed, unit: .metersPerSecond)
    }

    var maxSpeed: Measurement<UnitSpeed> {
        Measurement(value: cachedMaxSpeed, unit: .metersPerSecond)
    }

    /// Backfills stats for routes persisted before caching was added; a no-op afterward.
    func recomputeStatsIfNeeded() {
        guard !statsComputed else { return }
        recomputeStats()
    }

    func recomputeStats() {
        let speeds = locations.map { $0.speed.value }
        cachedAverageSpeed = speeds.isEmpty ? 0 : vDSP.mean(speeds)
        cachedMaxSpeed = speeds.isEmpty ? 0 : vDSP.maximum(speeds)

        let mapped = locations.map { CLLocation($0) }
        cachedDistance = zip(mapped.dropLast(), mapped.dropFirst())
            .map { $1.distance(from: $0) }
            .reduce(0, +)

        statsComputed = true
    }
}
