//
//  ContentView.swift
//  ItsPronouncedBichael
//
//  Created by mac on 5/24/25.
//

import SwiftUI
import SwiftData

import CoreLocation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Route]
    
    @State private var currentRoute: Route?
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        RouteView(route: item)
                    } label: {
                        Text(item.start ?? .now, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .onAppear {
            LocationManager.shared.beginUpdates()
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main) { _ in
                    LocationManager.shared.beginBackgroundUpdates()
                }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main) { _ in
                    LocationManager.shared.endBackgroundUpdates()
                }
        }
    }

    private func addItem() {
        withAnimation {
            let currentRoute = Route(initialRoute: [CLLocation]())
            LocationManager.shared.startRoute(currentRoute)
            modelContext.insert(currentRoute)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            self.currentRoute = LocationManager.shared.endRoute()
            
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Route.self, inMemory: true)
}
