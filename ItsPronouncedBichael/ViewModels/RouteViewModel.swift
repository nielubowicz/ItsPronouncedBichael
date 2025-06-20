import Accelerate
import Combine
import CoreLocation
import SwiftUI

// TODO: Make Active and Completed RouteViewModel
@Observable
class RouteViewModel {
    private(set) var locationManager: LocationManager
    private(set) var route: Route
    
    private var timer: Timer?
    
    init(route: Route, locationManager: LocationManager, showTraffic: Bool = true) {
        self.route = route
        self.locations = route.locations
        self.locationManager = locationManager
        self.showTraffic = showTraffic
    }
    
    private(set) var locations: [RouteLocation] = []
    private(set) var mappedLocations: [CLLocationCoordinate2D] = []
    private(set) var mappedSpeeds: [Double] = []
    private(set) var routeDistance: Measurement<UnitLength> = .init(value: 0, unit: .meters)
    private(set) var duration = Duration.seconds(0)
    
    
    private(set) var isPaused = false
    private var locationTracking: AnyCancellable?
    
    var showTraffic = true
    
    var showEndRoute: Bool {
        route.end == nil
    }
    
    var maxSpeed: String {
        maxSpeedCalculation.converted(to: RouteViewModel.speedUnit).formatted(.measurement(width: .abbreviated))
    }
    
    var averageSpeed: String {
        averageSpeedCalculation.converted(to: RouteViewModel.speedUnit).formatted(.measurement(width: .abbreviated))
    }
    
    var lastSpeed: String {
        lastSpeedCalculation.converted(to: RouteViewModel.speedUnit).formatted(.measurement(width: .abbreviated))
    }
    
    var startDate: String {
        route.start?.formatted(date: .omitted, time: .shortened) ?? ""
    }
    
    var endDate: String {
        route.end?.formatted(date: .omitted, time: .shortened) ?? ""
    }
}

extension RouteViewModel {
    private static var lengthUnit = UnitLength(forLocale: Locale.autoupdatingCurrent, usage: .road)
    private static var speedUnit = UnitSpeed(forLocale: Locale.autoupdatingCurrent, usage: .asProvided)
    
    private var lastSpeedCalculation: Measurement<UnitSpeed> {
        locations.last?.speed ?? Measurement<UnitSpeed>(value: 0, unit: .metersPerSecond)
    }
    
    private var averageSpeedCalculation: Measurement<UnitSpeed> {
        Measurement(value: vDSP.mean(mappedSpeeds), unit: .metersPerSecond)
    }
    
    private var maxSpeedCalculation: Measurement<UnitSpeed> {
        Measurement(value: vDSP.maximum(mappedSpeeds), unit: .metersPerSecond)
    }
}

// MARK: Route Management

extension RouteViewModel {
    func start() {
        route.start = .now
        startTimer()
        locationManager.startRoute()
        locationTracking = locationManager.$lastLocation.sink { [weak self] location in
            self?.append(location)
        }
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
        locationTracking?.cancel()
    }
    
    func resume() {
        isPaused = false
        startTimer()
        locationTracking = locationManager.$lastLocation.sink { [weak self] location in
            self?.append(location)
        }
    }
    
    func stop() {
        route.end = .now
        route.locations = locations
        locationManager.endRoute()
        timer?.invalidate()
        locationTracking?.cancel()
    }
}

// MARK: Location management

extension RouteViewModel {
    private func append(_ location: CLLocation) {
        guard location != CLLocation(latitude: 0, longitude: 0) else { return }
        
        if let lastLocation = locations.last {
            routeDistance = routeDistance + Measurement<UnitLength>(value: location.distance(from: CLLocation(lastLocation)), unit: .meters)
        }
        mappedLocations.append(location.coordinate)
        mappedSpeeds.append(location.speed)
        locations.append(RouteLocation(location))
    }
}

// MARK: Timer management

extension RouteViewModel {
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard timer.isValid else { return }
            self?.duration += Duration.seconds(timer.timeInterval)
        }
    }
}
