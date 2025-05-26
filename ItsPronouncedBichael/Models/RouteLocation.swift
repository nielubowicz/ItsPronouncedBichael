import CoreLocation

struct RouteLocation: Codable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let speed: Measurement<UnitSpeed>
    let course: Double
}

extension RouteLocation: Hashable {}

extension RouteLocation: Comparable {
    static func <(lhs: RouteLocation, rhs: RouteLocation) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
    
    static func == (lhs: RouteLocation, rhs: RouteLocation) -> Bool {
        lhs.timestamp == rhs.timestamp &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.speed == rhs.speed &&
        lhs.course == rhs.course
    }
}

extension RouteLocation {
    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        timestamp = location.timestamp
        speed = Measurement(value: location.speed, unit: .metersPerSecond)
        course = location.course
    }
}
