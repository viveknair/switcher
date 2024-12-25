//
//  ContentView.swift
//  switcher
//
//  Created by Vivek Nair on 4/28/22.
//

import Foundation
import SwiftUI

enum AppCategory: String, CaseIterable {
    case productivity = "Productivity"
    case development = "Development"
    case communication = "Communication"
    case media = "Media"
    case other = "Other"
}

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let icon: NSImage
    let category: AppCategory
    let bundleIdentifier: String
}

class AppViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var selectedCategory: AppCategory = .productivity
    @Published var selectedAppIndex: Int = 0
    @Published var appsByCategory: [AppCategory: [AppInfo]] = [:]
    
    func loadApps() {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        // Reset apps array
        apps = runningApps
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let appName = app.localizedName,
                      let bundleId = app.bundleIdentifier,
                      let icon = app.icon else { return nil }
                
                let category = categorizeApp(bundleId: bundleId)
                return AppInfo(name: appName, icon: icon, category: category, bundleIdentifier: bundleId)
            }
        
        // Organize apps by category
        appsByCategory = Dictionary(grouping: apps, by: { $0.category })
        
        // Reset selection if needed
        if let firstCategory = AppCategory.allCases.first(where: { appsByCategory[$0]?.isEmpty == false }) {
            selectedCategory = firstCategory
            selectedAppIndex = 0
        }
    }
    
    private func categorizeApp(bundleId: String) -> AppCategory {
        switch bundleId.lowercased() {
        case let id where id.contains("xcode"):
            return .development
        case let id where id.contains("visual") || id.contains("android"):
            return .development
        case let id where id.contains("slack") || id.contains("teams") || id.contains("zoom"):
            return .communication
        case let id where id.contains("spotify") || id.contains("music") || id.contains("netflix"):
            return .media
        case let id where id.contains("word") || id.contains("excel") || id.contains("notes"):
            return .productivity
        default:
            return .other
        }
    }
    
    func switchToApp(_ bundleId: String) {
        NSWorkspace.shared.runningApplications
            .first { $0.bundleIdentifier == bundleId }?
            .activate(options: .activateIgnoringOtherApps)
    }
    
    func cycleToNextApp() {
        // Get apps for current category
        guard let currentCategoryApps = appsByCategory[selectedCategory] else { return }
        
        selectedAppIndex += 1
        
        // If we've reached the end of apps in current category
        if selectedAppIndex >= currentCategoryApps.count {
            selectedAppIndex = 0
            // Move to next category
            let categories = AppCategory.allCases
            if let currentIndex = categories.firstIndex(of: selectedCategory) {
                let nextIndex = (currentIndex + 1) % categories.count
                selectedCategory = categories[nextIndex]
            }
        }
        
        // Switch to the selected app
        if let currentCategoryApps = appsByCategory[selectedCategory],
           selectedAppIndex < currentCategoryApps.count {
            let selectedApp = currentCategoryApps[selectedAppIndex]
            switchToApp(selectedApp.bundleIdentifier)
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AppCategory.allCases, id: \.self) { category in
                        if let apps = viewModel.appsByCategory[category], !apps.isEmpty {
                            Text(category.rawValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.selectedCategory == category ? Color.blue : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture {
                                    viewModel.selectedCategory = category
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Apps grid with selection highlight
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(60))], spacing: 16) {
                    if let apps = viewModel.appsByCategory[viewModel.selectedCategory] {
                        ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                            VStack {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                Text(app.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .frame(width: 60)
                            .background(index == viewModel.selectedAppIndex ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                viewModel.switchToApp(app.bundleIdentifier)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            viewModel.loadApps()
        }
    }
}
