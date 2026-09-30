import CoreLocation
import XCTest
@testable import ItsPronouncedBichael

final class RouteTests: XCTestCase {
    func testLoadingRoutePreservesPointData() {
        let originalLocations = Self.syntheticLocations(count: 5)
        let route = Route()
        route.points = originalLocations.map { RoutePoint(RouteLocation($0)) }

        let viewModel = RouteViewModel(route: route, locationManager: LocationManager())

        XCTAssertEqual(viewModel.locations.count, originalLocations.count)
        for (loaded, original) in zip(viewModel.locations, originalLocations) {
            XCTAssertEqual(loaded.latitude, original.coordinate.latitude, accuracy: 0.000001)
            XCTAssertEqual(loaded.longitude, original.coordinate.longitude, accuracy: 0.000001)
        }
    }

    func testStopWritesPointsAndStats() {
        let route = Route()
        let viewModel = RouteViewModel(route: route, locationManager: LocationManager())

        for location in Self.syntheticLocations(count: 5) {
            viewModel.ingest(location)
        }
        viewModel.stop()

        XCTAssertEqual(route.points?.count, 5)
        XCTAssertGreaterThan(route.cachedDistance, 0)
    }

    private static func syntheticLocations(count: Int) -> [CLLocation] {
        let baseLatitude = 37.7749
        let baseLongitude = -122.4194
        let metersPerDegreeLatitude = 111_320.0
        let stepMeters = 20.0
        let baseDate = Date(timeIntervalSince1970: 0)

        return (0..<count).map { index in
            let distanceAlongPath = Double(index) * stepMeters
            let latitude = baseLatitude + (distanceAlongPath / metersPerDegreeLatitude)
            return CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: baseLongitude),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 0,
                speed: 2,
                timestamp: baseDate.addingTimeInterval(Double(index))
            )
        }
    }
}
