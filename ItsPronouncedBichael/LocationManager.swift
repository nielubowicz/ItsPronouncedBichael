import CoreLocation
import SwiftUI

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var route: Route?

    private var backgroundActivitySession: CLBackgroundActivitySession?
    private var backgroundLocations = [RouteLocation]()
    
    private static var _shared: LocationManager = LocationManager()
    static var shared: LocationManager {
        return _shared
    }
    
    private override init() {
        super.init()
    }
    
    func beginUpdates() {
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationManagerStatusAndRequestLocationOrAuthorization(manager)
    }
    
    func beginBackgroundUpdates() {
        Task {
            backgroundActivitySession = CLBackgroundActivitySession()
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
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
        backgroundActivitySession?.invalidate()
        route?.locations.append(contentsOf: backgroundLocations)
        route?.locations.sort()
        backgroundLocations.removeAll()
    }
    
    func startRoute(_ route: Route) {
        route.start = .now
        self.route = route
    }
    
    func endRoute() -> Route {
        route?.end = .now
        return route ?? Route(initialRoute: [CLLocation]())
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
            manager.showsBackgroundLocationIndicator = true
            manager.startUpdatingLocation()
        case .denied,
                .restricted:
            print("L10n.Error.Location.notEnabled")
        default:
            print("L10n.Error.Location.unknown", manager.authorizationStatus)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            route?.locations.append(contentsOf: locations.map { RouteLocation($0) })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error)
    }
}

