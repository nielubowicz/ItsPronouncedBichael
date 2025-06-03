import Accelerate
import CoreLocation

// TODO: Make Active and Completed RouteViewModel
struct RouteViewModel {
    let route: Route
    
    var locations = [RouteLocation]()
    private(set) var mappedLocations = [CLLocationCoordinate2D]()
    
    var showTraffic = true
    
    var showEndRoute: Bool {
        route.end == nil
    }
    
    var maxSpeed: String {
        maxSpeedCalculation.converted(to: speedUnit).formatted(.measurement(width: .abbreviated))
    }
    
    var averageSpeed: String {
        averageSpeedCalculation.converted(to: speedUnit).formatted(.measurement(width: .abbreviated))
    }
    
    var lastSpeed: String {
        lastSpeedCalculation.converted(to: speedUnit).formatted(.measurement(width: .abbreviated))
    }
    
    var startDate: String {
        route.start?.formatted(date: .omitted, time: .shortened) ?? ""
    }
    
    var endDate: String {
        route.end?.formatted(date: .omitted, time: .shortened) ?? ""
    }
    
    mutating func append(_ location: RouteLocation) {
        mappedLocations.append(CLLocationCoordinate2DMake(location.latitude, location.longitude))
        locations.append(location)
    }
    
    mutating func append(contentsOf locations: [RouteLocation]) {
        mappedLocations.append(contentsOf: locations.map { CLLocationCoordinate2DMake($0.latitude, $0.longitude) })
        self.locations.append(contentsOf: locations)
    }
    
    func routeLength() async -> String {
        return await withCheckedContinuation { continuation in
            let locations = locations.map { CLLocation($0) }
            let measurement = Measurement<UnitLength>(value: vDSP.sum(zip(locations.dropLast(), locations.dropFirst()).map { $0.0.distance(from: $0.1) }), unit: .meters)
            continuation.resume(
                returning: measurement.converted(to: lengthUnit).formatted(.measurement(width: .abbreviated))
            )
        }
    }
    
    func mapLocations() -> [CLLocationCoordinate2D] {
        locations.map { CLLocationCoordinate2DMake($0.latitude, $0.longitude) }
    }
    
    func mapLocations() async -> [CLLocationCoordinate2D] {
        await withCheckedContinuation { $0.resume(returning: mapLocations()) }
    }
}

extension RouteViewModel {
    
    private var lengthUnit: UnitLength { UnitLength(forLocale: Locale.autoupdatingCurrent, usage: .road) }
    private var speedUnit: UnitSpeed { UnitSpeed(forLocale: Locale.autoupdatingCurrent, usage: .asProvided) }
    
    private var lastSpeedCalculation: Measurement<UnitSpeed> {
        locations.last?.speed ?? Measurement<UnitSpeed>(value: 0, unit: .metersPerSecond)
    }
    
    private var averageSpeedCalculation: Measurement<UnitSpeed> {
        Measurement(value: vDSP.mean(locations.map(\.speed.value)), unit: .metersPerSecond)
    }
    
    private var maxSpeedCalculation: Measurement<UnitSpeed> {
        Measurement(value: vDSP.maximum(locations.map(\.speed.value)), unit: .metersPerSecond)
    }
}
