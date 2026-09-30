import SwiftUI

struct RouteListItemView: View {
    let route: Route

    init(route: Route) {
        self.route = route
    }

    var body: some View {
        HStack {
            Text(route.start ?? .now, format: Date.FormatStyle.dateTime)
            Spacer()
            VStack {
                Text(route.averageSpeed.converted(to: .milesPerHour).formatted(.measurement(width: .abbreviated)))
                Text(route.maxSpeed.converted(to: .milesPerHour).formatted(.measurement(width: .abbreviated)))
            }
            .font(.caption)
            Spacer()
            Text(route.distance, format: .measurement(width: .abbreviated))
        }
    }
}
