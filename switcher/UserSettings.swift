import Foundation

enum UserSettings {
    enum Keys {
        static let openAIApiKey = "openAIApiKey"
        static let initialRepeatDelay = "initialRepeatDelay"
        static let repeatInterval = "repeatInterval"
        static let windowWidth = "windowWidth"
        static let windowHeight = "windowHeight"
    }
    
    @UserDefault(key: Keys.openAIApiKey, defaultValue: "")
    static var openAIApiKey: String
    
    @UserDefault(key: Keys.initialRepeatDelay, defaultValue: 0.5)
    static var initialRepeatDelay: Double
    
    @UserDefault(key: Keys.repeatInterval, defaultValue: 0.2)
    static var repeatInterval: Double
    
    @UserDefault(key: Keys.windowWidth, defaultValue: 600.0)
    static var windowWidth: Double
    
    @UserDefault(key: Keys.windowHeight, defaultValue: 300.0)
    static var windowHeight: Double
}

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
} 