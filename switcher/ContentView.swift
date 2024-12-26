//
//  ContentView.swift
//  switcher
//
//  Created by Vivek Nair on 4/28/22.
//

import Foundation
import SwiftUI
import AppKit

struct AppInfo {
    let name: String
    let icon: NSImage
    let category: AppCategory
    let bundleIdentifier: String
}

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    
    @Namespace private var namespace
    @State private var scrollTarget: Int?
    
    private var activeCategories: [AppCategory] {
        AppCategory.allCases.filter { category in
            viewModel.appsByCategory[category]?.isEmpty == false
        }
    }
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        mainContent
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            categoryTabs
            appGrid
        }
        .frame(minWidth: 600, minHeight: 300)
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(activeCategories, id: \.self) { category in
                    categoryTab(category)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
        .background(Color(.windowBackgroundColor))
    }
    
    private func categoryTab(_ category: AppCategory) -> some View {
        Text(category.rawValue)
            .font(.system(size: 14))
            .foregroundColor(category == viewModel.selectedCategory ? .accentColor : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(category == viewModel.selectedCategory ? 
                          Color.accentColor.opacity(0.1) : Color.clear)
            )
    }
    
    private var appGrid: some View {
        let apps = viewModel.appsByCategory[viewModel.selectedCategory] ?? []
        
        return ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 100))
            ], spacing: 16) {
                ForEach(Array(apps.enumerated()), id: \.element.bundleIdentifier) { index, app in
                    appIcon(app, isSelected: index == viewModel.selectedAppIndex)
                }
            }
            .padding()
        }
        .background(Color(.textBackgroundColor))
    }
    
    private func appIcon(_ app: AppInfo, isSelected: Bool) -> some View {
        VStack {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
            
            Text(app.name)
                .font(.system(size: 12))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}
