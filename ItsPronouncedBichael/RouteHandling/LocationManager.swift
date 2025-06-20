import CoreLocation
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var backgroundActivitySession: CLBackgroundActivitySession?
    private var backgroundLocations = [RouteLocation]()
    
    @Published private(set) var lastLocation = CLLocation(latitude: 0, longitude: 0)
    private(set) var locations = [RouteLocation]()
    @Published private(set) var isPaused = false
    
    func beginUpdates() {
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationManagerStatusAndRequestLocationOrAuthorization(manager)
    }
    
    func beginBackgroundUpdates() {
        manager.showsBackgroundLocationIndicator = true
        Task {
            backgroundActivitySession = CLBackgroundActivitySession()
            do {
                try Task.checkCancellation()
                for try await update in CLLocationUpdate.liveUpdates() {
                    try Task.checkCancellation()
                    if let location = update.location {
                        backgroundLocations.append(RouteLocation(location))
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func endBackgroundUpdates() {
        manager.showsBackgroundLocationIndicator = false
        backgroundActivitySession?.invalidate()
        locations.append(contentsOf: backgroundLocations)
        locations.sort()
        backgroundLocations.removeAll()
    }
    
    private var routeTask: Task<Void, Never>?
    
    func startRoute() {
        isPaused = false
        manager.startUpdatingLocation()
        routeTask = Task { @MainActor in
            do {
                try Task.checkCancellation()
                for try await update in CLLocationUpdate.liveUpdates() {
                    try Task.checkCancellation()
                    guard let location = update.location else { continue }
                    lastLocation = location
                    locations.append(RouteLocation(location))
                }
            } catch {
                print(error)
            }
        }
    }
    
    func pauseRoute() {
        isPaused = true
        routeTask?.cancel()
    }
    
    func endRoute() {
        isPaused = false
        routeTask?.cancel()
        backgroundLocations.removeAll()
        locations.removeAll()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationManagerStatusAndRequestLocationOrAuthorization(manager)
    }
    
    private func checkLocationManagerStatusAndRequestLocationOrAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse,
                .authorizedAlways:
            break
        case .denied,
                .restricted:
            print("L10n.Error.Location.notEnabled")
        default:
            print("L10n.Error.Location.unknown", manager.authorizationStatus)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error)
    }
}

