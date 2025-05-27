import SwiftUI
import MapKit

struct RouteView: View {
    let route: Route
    
    @State private var routeLocations = [CLLocationCoordinate2D]()
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    
    var body: some View {
        VStack {
            header
            Map(
                position: $position,
                selection: .constant(nil)
            ) {
                routeLine
            }
            .mapControls {
                MapUserLocationButton()
            }
        }
        .task {
            routeLocations = await route.mapLocations()
        }
        .onChange(of: route.locations) { _, newValue in
            Task {
                routeLocations = await route.mapLocations()
            }
        }
    }
    
    @ViewBuilder
    var header: some View {
        HStack {
            VStack {
                Text(route.start?.formatted(date: .omitted, time: .shortened) ?? "")
                    .padding(.top)
                Text(route.end?.formatted(date: .omitted, time: .shortened) ?? "")
                    .padding(.bottom)
            }
            .font(.caption)
            .padding(.horizontal)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.black, lineWidth: 1)
            }
         
            if let speed = route.locations.last?.speed,
               speed.value >= 0 {
                Text(lastSpeed)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .padding()
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.black, lineWidth: 1)
                    }
            } else {
                EmptyView()
            }
        }
    }
    
    @MapContentBuilder
    var routeLine: some MapContent {
        MapPolyline(
            coordinates: routeLocations,
            contourStyle: .straight
        )
        .mapOverlayLevel(level: .aboveRoads)
        .stroke(
            Gradient(colors: [.blue.opacity(0.2), .blue]),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }
    
    private var lastSpeed: String {
        route.locations.last?.speed.converted(to: .milesPerHour).formatted(.measurement(width: .abbreviated)) ?? ""
    }
}
