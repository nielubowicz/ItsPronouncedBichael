import Accelerate
import CoreLocation
import SwiftUI

struct RouteListItemView: View {
    let route: Route
    
    init(route: Route) {
        self.route = route
    }
    
    var body: some View {
        HStack {
            Text(route.start ?? .now, format: Date.FormatStyle.dateTime)
            Spacer()
            VStack {
                Text(
                    Measurement<UnitSpeed>( value: vDSP.mean(mappedSpeeds), unit: .metersPerSecond)
                        .converted(to: .milesPerHour)
                        .formatted(.measurement(width: .abbreviated))
                )
                Text(
                    Measurement<UnitSpeed>(value: vDSP.maximum(mappedSpeeds), unit: .metersPerSecond)
                        .converted(to: .milesPerHour)
                        .formatted(.measurement(width: .abbreviated))
                )
            }
            .font(.caption)
            Spacer()
            Text(routeDistance, format: .measurement(width: .abbreviated))
        }
    }
    
    private var mappedSpeeds: [Double] {
        route.locations.map { $0.speed.value }
    }
    
    private var routeDistance: Measurement<UnitLength> {
        var mappedLocations = route.locations.map { CLLocation($0) }
        return zip(mappedLocations.dropLast(), mappedLocations.dropFirst())
            .map { $1.distance(from: $0) }
            .map { Measurement<UnitLength>(value: $0, unit: .meters) }
            .reduce(Measurement<UnitLength>(value: 0, unit: .meters), +)
    }
}
