import CoreLocation
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var backgroundActivitySession: CLBackgroundActivitySession?
    private var backgroundTask: Task<Void, Never>?
    @Published private(set) var lastLocation = CLLocation(latitude: 0, longitude: 0)
    @Published private(set) var isPaused = false
    
    func beginUpdates() {
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationManagerStatusAndRequestLocationOrAuthorization(manager)
    }
    
    func beginBackgroundUpdates() {
        manager.showsBackgroundLocationIndicator = true
        backgroundTask = Task {
            routeTask?.cancel()
            backgroundActivitySession = CLBackgroundActivitySession()
            do {
                try Task.checkCancellation()
                for try await update in CLLocationUpdate.liveUpdates() {
                    try Task.checkCancellation()
                    guard let location = update.location else { continue }
                    lastLocation = location
                }
            } catch {
                print(error)
            }
        }
    }
    
    func endBackgroundUpdates() {
        manager.showsBackgroundLocationIndicator = false
        backgroundTask?.cancel()
        backgroundActivitySession?.invalidate()
        startRouteTask()
    }
    
    private var routeTask: Task<Void, Never>?
    
    func startRoute() {
        isPaused = false
        manager.startUpdatingLocation()
        startRouteTask()
    }
    
    func pauseRoute() {
        isPaused = true
        routeTask?.cancel()
    }
    
    func endRoute() {
        isPaused = false
        routeTask?.cancel()
        lastLocation = CLLocation(latitude: 0, longitude: 0)
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

extension LocationManager {
    private func startRouteTask() {
        routeTask = Task { @MainActor in
            do {
                try Task.checkCancellation()
                for try await update in CLLocationUpdate.liveUpdates() {
                    try Task.checkCancellation()
                    guard let location = update.location else { continue }
                    lastLocation = location
                }
            } catch {
                print(error)
            }
        }
    }
}
