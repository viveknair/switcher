import Foundation
import SwiftUI
import AppKit

class AppViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var selectedCategory: AppCategory = .productivity
    @Published var selectedAppIndex: Int = 0
    @Published var appsByCategory: [AppCategory: [AppInfo]] = [:]
    private var categorizer: AppCategorizer?
    private var categorizedApps: [String: AppInfo] = [:] // Cache by bundle ID
    
    var currentSelectedApp: AppInfo? {
        guard let categoryApps = appsByCategory[selectedCategory],
              selectedAppIndex < categoryApps.count else {
            return nil
        }
        return categoryApps[selectedAppIndex]
    }
    
    init() {
        self.categorizer = AppCategorizer()
        Task { @MainActor in
            await loadAndCategorizeApps()
        }
    }
    
    private func loadAndCategorizeApps() async {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications.filter { $0.activationPolicy == .regular }
        
        // First collect all apps that need categorization
        var appsToProcess: [(name: String, bundleId: String, icon: NSImage)] = []
        for app in runningApps {
            guard let appName = app.localizedName,
                  let bundleId = app.bundleIdentifier,
                  let icon = app.icon else { continue }
            
            if categorizedApps[bundleId] == nil {
                appsToProcess.append((appName, bundleId, icon))
            }
        }
        
        // Run all categorization requests in parallel
        await withTaskGroup(of: (String, AppInfo).self) { group in
            for (name, bundleId, icon) in appsToProcess {
                group.addTask {
                    let category = await self.categorizeApp(name: name, bundleId: bundleId)
                    let appInfo = AppInfo(name: name, icon: icon, category: category, bundleIdentifier: bundleId)
                    return (bundleId, appInfo)
                }
            }
            
            // Collect results
            for await (bundleId, appInfo) in group {
                categorizedApps[bundleId] = appInfo
            }
        }
        
        // Build final list including both new and previously cached apps
        var newApps: [AppInfo] = []
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  let appInfo = categorizedApps[bundleId] else { continue }
            newApps.append(appInfo)
        }
        
        await MainActor.run {
            self.apps = newApps
            self.appsByCategory = Dictionary(grouping: newApps, by: { $0.category })
            
            // Reset selection if needed
            if let firstCategory = AppCategory.allCases.first(where: { self.appsByCategory[$0]?.isEmpty == false }) {
                self.selectedCategory = firstCategory
                self.selectedAppIndex = 0
            }
        }
    }
    
    func loadApps() {
        Task { @MainActor in
            await updateRunningApps()
        }
    }
    
    private func updateRunningApps() async {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        var newApps: [AppInfo] = []
        
        for app in runningApps where app.activationPolicy == .regular {
            guard let bundleId = app.bundleIdentifier else { continue }
            if let cached = categorizedApps[bundleId] {
                newApps.append(cached)
            }
        }
        
        self.apps = newApps
        self.appsByCategory = Dictionary(grouping: newApps, by: { $0.category })
        
        // Reset selection if needed
        if let firstCategory = AppCategory.allCases.first(where: { self.appsByCategory[$0]?.isEmpty == false }) {
            self.selectedCategory = firstCategory
            self.selectedAppIndex = 0
        }
    }
    
    private func fallbackCategorization(bundleId: String) -> AppCategory {
        // Keep the existing categorization logic as fallback
        let lowercaseBundleId = bundleId.lowercased()
        
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
            return .productivity
        }
    }
    
    private func categorizeApp(name: String, bundleId: String) async -> AppCategory {
        if let categorizer = categorizer {
            do {
                return try await categorizer.categorizeApp(name: name, bundleId: bundleId)
            } catch {
                return fallbackCategorization(bundleId: bundleId)
            }
        }
        return fallbackCategorization(bundleId: bundleId)
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
            if let previousCategoryApps = appsByCategory[selectedCategory] {
                selectedAppIndex = previousCategoryApps.count - 1  // Set to last app in previous category
            }
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
                return
            }
            previousIndex = (previousIndex - 1 + categories.count) % categories.count
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