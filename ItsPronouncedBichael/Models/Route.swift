import Accelerate
import SwiftData
import CoreLocation

@Model
final class Route {
    var start: Date?
    var end: Date?
    var locations: [RouteLocation] = [RouteLocation]()

    @Relationship(deleteRule: .cascade, inverse: \RoutePoint.route)
    var points: [RoutePoint]? = []

    var cachedDistance: Double = 0
    var cachedAverageSpeed: Double = 0
    var cachedMaxSpeed: Double = 0
    var statsComputed: Bool = false

    init(initialRoute: [CLLocation]) {
        self.locations = initialRoute.map { RouteLocation($0) }
    }
}

extension Route {
    /// Prefers the relationship-backed points; falls back to the legacy embedded array for routes not yet migrated.
    var allLocations: [RouteLocation] {
        guard let points else { return [] }
        return points.isEmpty ? locations : points.map { RouteLocation($0) }
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

    /// Moves points persisted before relationship-based storage existed into `points`, freeing the embedded blob.
    func migratePointsIfNeeded() {
        guard let points, points.isEmpty, !locations.isEmpty else { return }
        self.points = locations.map { RoutePoint($0) }
        locations = []
    }

    /// Backfills stats (and points storage) for routes persisted before caching was added; a no-op afterward.
    func recomputeStatsIfNeeded() {
        guard !statsComputed else { return }
        migratePointsIfNeeded()
        recomputeStats()
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

        statsComputed = true
    }
}
