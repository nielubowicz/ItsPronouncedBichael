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
    @State var locationManager = LocationManager()
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        RouteView(route: item, locationManager: locationManager)
                    } label: {
                        RouteListItemView(route: item)
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
            locationManager.beginUpdates()
        }
    }

    private func addItem() {
        withAnimation {
            let currentRoute = Route(initialRoute: [CLLocation]())
            // TODO: Don't update the Model so often
            // Find a way to batch, stream or collect location updates without
            // changing the Route object at every update.
            currentRoute.start = .now
            modelContext.insert(currentRoute)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
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
