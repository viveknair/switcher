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
        
        // Reset apps array and appsByCategory
        appsByCategory = [:] // Clear the dictionary first
        
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
        // Convert to lowercase once to avoid multiple conversions
        let lowercaseBundleId = bundleId.lowercased()
        
        // Use more specific bundle ID checks
        switch lowercaseBundleId {
        case let id where id.contains("xcode"):
            return .development
        case let id where id.contains("visual") || id.contains("android"):
            return .development
        case let id where id.contains("slack") || id.contains("teams") || id.contains("zoom"):
            return .communication
        case let id where id.contains("spotify") || id.contains("music") || id.contains("netflix"):
            return .media
        case let id where id.contains("notes.app") || id.contains("microsoft.word") || 
                         id.contains("microsoft.excel") || id.contains("microsoft.powerpoint"):
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
        guard let currentCategoryApps = appsByCategory[selectedCategory] else { 
            moveToNextCategoryWithApps()
            return 
        }
        
        selectedAppIndex += 1
        
        // If we've reached the end of apps in current category
        if selectedAppIndex >= currentCategoryApps.count {
            selectedAppIndex = 0
            moveToNextCategoryWithApps()
        }
        
        // Switch to the selected app
        if let currentCategoryApps = appsByCategory[selectedCategory],
           selectedAppIndex < currentCategoryApps.count {
            let selectedApp = currentCategoryApps[selectedAppIndex]
            switchToApp(selectedApp.bundleIdentifier)
        }
    }
    
    private func moveToNextCategoryWithApps() {
        let categories = AppCategory.allCases
        guard let currentIndex = categories.firstIndex(of: selectedCategory) else { return }
        
        var nextIndex = (currentIndex + 1) % categories.count
        let startIndex = currentIndex
        
        // Keep looking until we find a category with apps or we've checked all categories
        while nextIndex != startIndex {
            let nextCategory = categories[nextIndex]
            if let nextCategoryApps = appsByCategory[nextCategory], !nextCategoryApps.isEmpty {
                selectedCategory = nextCategory
                selectedAppIndex = 0
                return
            }
            nextIndex = (nextIndex + 1) % categories.count
        }
        
        // If we've checked all categories and found none with apps, stay in current category
        if let currentCategoryApps = appsByCategory[selectedCategory], !currentCategoryApps.isEmpty {
            selectedAppIndex = 0
        }
    }
    
    func cycleToPreviousApp() {
        // Get apps for current category
        guard let currentCategoryApps = appsByCategory[selectedCategory] else { 
            moveToPreviousCategoryWithApps()
            return 
        }
        
        selectedAppIndex -= 1
        
        // If we've reached the start of apps in current category
        if selectedAppIndex < 0 {
            moveToPreviousCategoryWithApps()
        }
        
        // Switch to the selected app
        if let currentCategoryApps = appsByCategory[selectedCategory],
           selectedAppIndex >= 0 && selectedAppIndex < currentCategoryApps.count {
            let selectedApp = currentCategoryApps[selectedAppIndex]
            switchToApp(selectedApp.bundleIdentifier)
        }
    }
    
    private func moveToPreviousCategoryWithApps() {
        let categories = AppCategory.allCases
        guard let currentIndex = categories.firstIndex(of: selectedCategory) else { return }
        
        var previousIndex = (currentIndex - 1 + categories.count) % categories.count
        let startIndex = currentIndex
        
        // Keep looking until we find a category with apps or we've checked all categories
        while previousIndex != startIndex {
            let previousCategory = categories[previousIndex]
            if let previousCategoryApps = appsByCategory[previousCategory], !previousCategoryApps.isEmpty {
                selectedCategory = previousCategory
                selectedAppIndex = previousCategoryApps.count - 1  // Set to last app in category
                return
            }
            previousIndex = (previousIndex - 1 + categories.count) % categories.count
        }
        
        // If we've checked all categories and found none with apps, stay in current category
        if let currentCategoryApps = appsByCategory[selectedCategory], !currentCategoryApps.isEmpty {
            selectedAppIndex = currentCategoryApps.count - 1
        }
    }
    
    func jumpToNextCategory() {
        let categories = AppCategory.allCases
        guard let currentIndex = categories.firstIndex(of: selectedCategory) else { return }
        
        var nextIndex = (currentIndex + 1) % categories.count
        let startIndex = currentIndex
        
        // Find next category with apps
        while nextIndex != startIndex {
            let nextCategory = categories[nextIndex]
            if let nextCategoryApps = appsByCategory[nextCategory], !nextCategoryApps.isEmpty {
                selectedCategory = nextCategory
                selectedAppIndex = 0  // Always jump to first app in category
                
                // Switch to the first app in the new category
                if let firstApp = nextCategoryApps.first {
                    switchToApp(firstApp.bundleIdentifier)
                }
                return
            }
            nextIndex = (nextIndex + 1) % categories.count
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    
    @Namespace private var namespace
    @State private var scrollTarget: Int?
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                                    withAnimation {
                                        viewModel.selectedCategory = category
                                        viewModel.selectedAppIndex = 0  // Reset index when changing category
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            ScrollViewReader { proxy in
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
                                .id(index)
                                .onTapGesture {
                                    viewModel.switchToApp(app.bundleIdentifier)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .id(viewModel.selectedCategory) // Add an ID to force refresh when category changes
                }
                .onChange(of: viewModel.selectedAppIndex) { newIndex in
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            viewModel.loadApps()
        }
    }
}
