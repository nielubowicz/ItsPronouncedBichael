import CoreLocation

extension CLLocation {
    convenience init(_ location: RouteLocation) {
        self.init(
            coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            course: location.course,
            speed: location.speed.value,
            timestamp: location.timestamp
        )
    }
}
