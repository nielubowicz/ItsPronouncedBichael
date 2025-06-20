import MapKit
import SwiftUI

struct RouteView: View {
    @State var viewModel: RouteViewModel
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    
    init(route: Route, locationManager: LocationManager) {
        viewModel = RouteViewModel(route: route, locationManager: locationManager)
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
                        Button {
                            viewModel.isPaused ? viewModel.resume() : viewModel.pause()
                        } label: { Label("", systemImage: viewModel.isPaused ? "play.circle" : "pause.circle").font(.title) }
                            .padding(24)
                            .background(Color(UIColor.darkGray).opacity(0.4))
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
                        
                        Divider()
                            .foregroundStyle(.black)
                        
                        Button {
                            viewModel.stop()
                        } label: { Label("", systemImage: "stop.circle").font(.title) }
                            .padding(24)
                            .background(Color(UIColor.darkGray).opacity(0.4))
                            .clipShape(Rectangle())
                            .contentShape(Rectangle())
                    }
                    
                    Divider()
                        .foregroundStyle(.black)
                    
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
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.start()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
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
            
            VStack {
                Text(viewModel.lastSpeed)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(viewModel.duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 1))))
                    .font(.subheadline)
            }
            .padding()
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.black, lineWidth: 1)
            }
            
            VStack {
                Text(viewModel.averageSpeed)
                Text(viewModel.maxSpeed)
                Text(viewModel.routeDistance.converted(to: .miles).formatted(.measurement(width: .abbreviated, usage: .road)))
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
            coordinates: viewModel.mappedLocations,
            contourStyle: .straight
        )
        .mapOverlayLevel(level: .aboveRoads)
        .stroke(
            Color.accentColor,
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
