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
    
    func loadApps() {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        apps = runningApps
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let appName = app.localizedName,
                      let bundleId = app.bundleIdentifier,
                      let icon = app.icon else { return nil }
                
                // Categorize apps based on bundle identifier
                let category = categorizeApp(bundleId: bundleId)
                return AppInfo(name: appName, icon: icon, category: category, bundleIdentifier: bundleId)
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
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AppCategory.allCases, id: \.self) { category in
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
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Apps grid
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(60))], spacing: 16) {
                    ForEach(viewModel.apps.filter { $0.category == viewModel.selectedCategory }) { app in
                        VStack {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                            Text(app.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(width: 60)
                        .onTapGesture {
                            viewModel.switchToApp(app.bundleIdentifier)
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
