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
}
