import CoreLocation
import SwiftData

@Model
final class RoutePoint {
    var timestamp: Date = Date.distantPast
    var latitude: Double = 0
    var longitude: Double = 0
    var speedValue: Double = 0
    var course: Double = 0
    var route: Route?

    init(timestamp: Date, latitude: Double, longitude: Double, speedValue: Double, course: Double) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.speedValue = speedValue
        self.course = course
    }
}

extension RoutePoint {
    convenience init(_ location: RouteLocation) {
        self.init(
            timestamp: location.timestamp,
            latitude: location.latitude,
            longitude: location.longitude,
            speedValue: location.speed.value,
            course: location.course
        )
    }
}

extension RouteLocation {
    init(_ point: RoutePoint) {
        timestamp = point.timestamp
        latitude = point.latitude
        longitude = point.longitude
        speed = Measurement(value: point.speedValue, unit: .metersPerSecond)
        course = point.course
    }
}
