import CoreLocation
import XCTest
@testable import ItsPronouncedBichael

final class RouteViewModelPerformanceTests: XCTestCase {
    func testIngestThinningPerformance() {
        let locations = Self.syntheticLocations(count: 10_000)
        measure {
            let viewModel = RouteViewModel(route: Route(initialRoute: []), locationManager: LocationManager())
            for location in locations {
                viewModel.ingest(location)
            }
        }
    }

    func testSeedingFromLargeHistoricalRoute() {
        let route = Route(initialRoute: Self.syntheticLocations(count: 10_000))
        measure {
            _ = RouteViewModel(route: route, locationManager: LocationManager())
        }
    }

    /// Walks a straight path in fixed 5m steps, alternating just-below and
    /// just-above the 8m thinning threshold so `ingest` exercises both the
    /// skip and append branches, rather than always taking one path.
    private static func syntheticLocations(count: Int) -> [CLLocation] {
        let baseLatitude = 37.7749
        let baseLongitude = -122.4194
        let metersPerDegreeLatitude = 111_320.0
        let stepMeters = 5.0
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
