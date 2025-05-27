import SwiftData
import CoreLocation

@Model
final class Route {
    var start: Date?
    var end: Date?
    var locations: [RouteLocation]
    
    init(initialRoute: [CLLocation]) {
        self.locations = initialRoute.map { RouteLocation($0) }
    }
    
    func mapLocations() async -> [CLLocationCoordinate2D] {
        return await withCheckedContinuation { continuation in
            continuation.resume(
                returning: locations.map {
                    CLLocationCoordinate2DMake($0.latitude, $0.longitude)
                }
            )
        }
    }
}
