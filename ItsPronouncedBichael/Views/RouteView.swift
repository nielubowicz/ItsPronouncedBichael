import MapKit
import SwiftUI

struct RouteView: View {
    @State var viewModel: RouteViewModel
    
    @State private var lastDistance = Measurement<UnitLength>(value: 0, unit: .meters).formatted()
    @State private var routeLocations = [CLLocationCoordinate2D]()
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    
    init(route: Route) {
        viewModel = RouteViewModel(route: route)
    }
    
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
            .mapStyle(.standard(elevation: .realistic, showsTraffic: viewModel.showTraffic))
            .overlay(alignment: .bottomTrailing) {
                VStack(alignment: .trailing, spacing: 0) {
                    if viewModel.showEndRoute {
                        Button { let _ = LocationManager.shared.endRoute() } label: { Label("", systemImage: "stop.circle").font(.title) }
                            .padding(24)
                            .background(Color(UIColor.darkGray).opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 16,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 16,
                                    style: .continuous
                                )
                            )
                            .contentShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 16,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 16,
                                    style: .continuous
                                )
                            )
                    }
                    
                    Color(.black)
                        .frame(height: 1)
                    
                    Button { viewModel.showTraffic.toggle() } label: { Label("", systemImage: viewModel.showTraffic ? "car.fill" : "car").font(.title)
                            .padding(24)
                            .background(Color(UIColor.darkGray).opacity(0.4))
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: viewModel.showEndRoute ? 0 : 16,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: viewModel.showEndRoute ? 0 : 16,
                                    style: .continuous
                                )
                            )
                            .contentShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: viewModel.showEndRoute ? 0 : 16,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: viewModel.showEndRoute ? 0 : 16,
                                    style: .continuous
                                )
                            )
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.black, lineWidth: 1)
                }
            }
        }
        .task {
            routeLocations = await viewModel.mapLocations()
        }
        .onChange(of: viewModel.route.locations) { _, _ in
            Task {
                try? Task.checkCancellation()
                routeLocations = await viewModel.mapLocations()
            }
        }
    }
    
    @ViewBuilder
    var header: some View {
        HStack {
            VStack {
                Text(viewModel.startDate)
                    .padding(.top)
                Text(viewModel.endDate)
                    .padding(.bottom)
            }
            .font(.caption)
            .padding(.horizontal)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.black, lineWidth: 1)
            }
            
            Text(viewModel.lastSpeed)
                .font(.headline)
                .fontWeight(.bold)
                .padding()
                .background(.gray.opacity(0.1))
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.black, lineWidth: 1)
                }
            
            VStack {
                Text(viewModel.averageSpeed)
                Text(viewModel.maxSpeed)
                Text(lastDistance)
                    .task {
                        lastDistance = await viewModel.routeLength()
                    }
                    .onChange(of: routeLocations) { _,_ in
                        Task {
                            lastDistance = await viewModel.routeLength()
                        }
                    }
            }
            .padding(.horizontal)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.black, lineWidth: 1)
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
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
}
