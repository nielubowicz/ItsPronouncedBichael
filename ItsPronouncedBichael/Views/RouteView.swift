import SwiftUI
import MapKit

struct RouteView: View {
    let route: Route
    
    var body: some View {
        Text(route.start?.formatted(date: .abbreviated, time: .shortened) ?? "")
            .font(.title)
        Map {
            MapPolyline(
                coordinates: route.locations.map {
                    CLLocationCoordinate2DMake($0.latitude, $0.longitude)
                },
                contourStyle: .straight
            )
            .mapOverlayLevel(level: .aboveRoads)
            .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
        .overlay(alignment: .topTrailing) {
            if let speed = route.locations.last?.speed,
               speed.value >= 0 {
                Text(route.locations.last?.speed.converted(to: .milesPerHour).formatted(.measurement(width: .abbreviated)) ?? "")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding()
                    .background(.white.opacity(0.4))
                    .padding()
            }
        }
    }
}
