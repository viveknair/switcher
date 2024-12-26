import Foundation
import SwiftOpenAI
import AppKit

protocol AppCategorizerDelegate: AnyObject {
    func showPanel()
    func hidePanel()
    func cycleToNextApp()
    func cycleToPreviousApp()
    func jumpToNextCategory()
}

class AppCategorizer {
    weak var delegate: AppCategorizerDelegate?
    private let defaults = UserDefaults.standard
    private let categoryCacheKey = "appCategoryCache"
    private var service: OpenAIService?
    
    private var categoryCache: [String: AppCategory] {
        get {
            guard let data = defaults.data(forKey: categoryCacheKey),
                  let cache = try? JSONDecoder().decode([String: AppCategory].self, from: data) else {
                return [:]
            }
            return cache
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: categoryCacheKey)
            }
        }
    } 																									        						
    
    private var currentCategory: AppCategory = .productivity
    private var categorizedApps: [AppCategory: [String]] = [:] // Category -> [BundleId]
    
    init() {
        updateService()
        NotificationCenter.default.addObserver(self, 
            selector: #selector(handleApiKeyChange), 
            name: UserDefaults.didChangeNotification, 
            object: nil)
    }
    
    @objc private func handleApiKeyChange() {
        updateService()
    }
    
    private func updateService() {
        let apiKey = UserDefaults.standard.string(forKey: "openAIApiKey") ?? ""
        if !apiKey.isEmpty {
            self.service = OpenAIServiceFactory.service(apiKey: apiKey)
        } else {
            self.service = nil
        }
    }
    
    func categorizeApp(name: String, bundleId: String) async throws -> AppCategory {
        // Check cache first
        if let cachedCategory = categoryCache[bundleId] {
            // Update categorizedApps dictionary
            updateCategorizedApps(bundleId: bundleId, category: cachedCategory)
            return cachedCategory
        }
        
        guard let service = self.service else {
            return fallbackCategorization(bundleId: bundleId)
        }
        
        // Prepare the prompt
        let prompt = """
        Categorize this macOS app into exactly one of these categories: Productivity, Development, Communication, Media, Other
        App Name: \(name)
        Bundle ID: \(bundleId)
        
        Respond with ONLY the category name, nothing else.
        """
        
        // Call OpenAI API
        let parameters = ChatCompletionParameters(
            messages: [
                .init(
                    role: .user,
                    content: .text(prompt)
                )
            ],
            model: .gpt4,
            temperature: 0.7
        )
        
        do {
            let chatCompletion = try await service.startChat(parameters: parameters)
            let response = chatCompletion.choices.first?.message.content ?? ""
            
            let categoryString = response.trimmingCharacters(in: .whitespacesAndNewlines)
            if let category = AppCategory(rawValue: categoryString) {
                // Cache the result
                categoryCache[bundleId] = category
                updateCategorizedApps(bundleId: bundleId, category: category)
                return category
            }
        } catch {
            return fallbackCategorization(bundleId: bundleId)
        }
        
        return fallbackCategorization(bundleId: bundleId)
    }
    
    private func fallbackCategorization(bundleId: String) -> AppCategory {
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
    
    private func updateCategorizedApps(bundleId: String, category: AppCategory) {
        // Create a mutable copy of the dictionary
        var newCategorizedApps = categorizedApps
        
        // Remove the bundleId from all categories
        for existingCategory in AppCategory.allCases {
            if var apps = newCategorizedApps[existingCategory] {
                apps.removeAll(where: { $0 == bundleId })
                newCategorizedApps[existingCategory] = apps
            }
        }
        
        // Add to the new category
        if var apps = newCategorizedApps[category] {
            apps.append(bundleId)
            newCategorizedApps[category] = apps
        } else {
            newCategorizedApps[category] = [bundleId]
        }
        
        // Update the stored dictionary
        categorizedApps = newCategorizedApps
    }
    
    func moveToNextApp() {
        delegate?.showPanel()
        delegate?.cycleToNextApp()
    }
    
    func moveToPreviousApp() {
        delegate?.showPanel()
        delegate?.cycleToPreviousApp()
    }
    
    func moveToNextCategory() {
        delegate?.showPanel()
        delegate?.jumpToNextCategory()
    }
    
    private func activateApp(bundleId: String) {
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            runningApp.activate(options: [.activateIgnoringOtherApps])
        }
    }
}
