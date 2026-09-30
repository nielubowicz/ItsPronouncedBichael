import Accelerate
import Combine
import CoreLocation
import MapKit
import SwiftUI

// TODO: Make Active and Completed RouteViewModel
@Observable
class RouteViewModel {
    private(set) var locationManager: LocationManager
    private(set) var route: Route
    
    private var timer: Timer?
    
    init(route: Route, locationManager: LocationManager, showTraffic: Bool = true) {
        let routeLocations = route.allLocations
        let mappedLocations = routeLocations.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        self.route = route
        self.locations = routeLocations
        self.mappedLocations = mappedLocations
        self.mappedSpeeds = routeLocations.map { $0.speed.value }
        self.routeDistance = Self.totalDistance(for: routeLocations)
        self.renderedRouteCoordinates = mappedLocations
        self.locationManager = locationManager
        self.showTraffic = showTraffic
        if let start = route.start, let end = route.end {
            self.duration = .seconds(end.timeIntervalSince(start))
        }
    }

    private(set) var locations = [RouteLocation]()
    private(set) var mappedLocations = [CLLocationCoordinate2D]()
    private(set) var renderedRouteCoordinates = [CLLocationCoordinate2D]()
    private(set) var mappedSpeeds = [Double]()
    private(set) var routeDistance = Measurement<UnitLength>(value: 0, unit: .meters)
    private(set) var duration = Duration.seconds(0)
    
    private(set) var isPaused = false
    
    private var locationTracking: AnyCancellable?
    private var dateEnteredBackground: Date?
    
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

    /// The map area that frames the whole route, once it has been completed.
    var completedRouteRect: MKMapRect? {
        guard !showEndRoute else { return nil }
        return Self.framingRect(for: mappedLocations)
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

    fileprivate static func totalDistance(for locations: [RouteLocation]) -> Measurement<UnitLength> {
        let mapped = locations.map { CLLocation($0) }
        return zip(mapped.dropLast(), mapped.dropFirst())
            .map { $1.distance(from: $0) }
            .map { Measurement<UnitLength>(value: $0, unit: .meters) }
            .reduce(Measurement<UnitLength>(value: 0, unit: .meters), +)
    }
}

// MARK: Map framing

extension RouteViewModel {
    /// Fraction of the route's size added on each side, so the line doesn't touch the map's edges.
    private static let framingPadding = 0.15
    /// Keeps very short (or single-point) routes from zooming in to street-furniture level.
    private static let minimumFramingSpan: CLLocationDistance = 200

    static func framingRect(for coordinates: [CLLocationCoordinate2D]) -> MKMapRect? {
        guard let first = coordinates.first else { return nil }
        let bounds = coordinates.dropFirst().reduce(MKMapRect(origin: MKMapPoint(first), size: MKMapSize())) { rect, coordinate in
            rect.union(MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize()))
        }
        let center = MKMapPoint(x: bounds.midX, y: bounds.midY)
        let minimumSpan = minimumFramingSpan * MKMapPointsPerMeterAtLatitude(center.coordinate.latitude)
        let width = max(bounds.width, minimumSpan) * (1 + 2 * framingPadding)
        let height = max(bounds.height, minimumSpan) * (1 + 2 * framingPadding)
        return MKMapRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }
}

// MARK: Route Management

extension RouteViewModel {
    func start() {
        guard showEndRoute else { return }
        route.start = .now
        startTimer()
        locationManager.startRoute()
        subscribeToLocationUpdates()

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main)
        { [weak self] _ in
            self?.timer?.invalidate()
            self?.dateEnteredBackground = .now
            self?.locationManager.beginBackgroundUpdates()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main)
        { [weak self] _ in
            self?.locationManager.endBackgroundUpdates()
            self?.duration += Duration.seconds(Date().timeIntervalSince(self?.dateEnteredBackground ?? Date()))
            self?.dateEnteredBackground = nil
            self?.startTimer()
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
        subscribeToLocationUpdates()
    }

    func stop() {
        route.end = .now
        route.points = locations.map { RoutePoint($0) }
        route.recomputeStats()
        renderedRouteCoordinates = mappedLocations
        locationManager.endRoute()
        timer?.invalidate()
        locationTracking?.cancel()
    }
}

// MARK: Location management

extension RouteViewModel {
    private static let minimumDistanceBetweenPoints: CLLocationDistance = 8

    private func subscribeToLocationUpdates() {
        locationTracking = locationManager.$lastLocation
            .sink { [weak self] location in
                self?.ingest(location)
            }
    }

    func ingest(_ location: CLLocation) {
        guard location.coordinate != CLLocationCoordinate2DMake(0, 0) else { return }
        if let lastLocation = locations.last,
           location.distance(from: CLLocation(lastLocation)) < Self.minimumDistanceBetweenPoints {
            return
        }
        append(location)
    }

    private func append(_ location: CLLocation) {
        guard location.coordinate != CLLocationCoordinate2DMake(0, 0) else { return }

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
            guard let self, timer.isValid else { return }
            self.duration += Duration.seconds(timer.timeInterval)
            self.renderedRouteCoordinates = self.mappedLocations
        }
    }
}
