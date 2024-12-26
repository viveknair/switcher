import Foundation

public enum UserSettings {
    @UserDefault("initialRepeatDelay", defaultValue: 0.5)
    public static var initialRepeatDelay: Double
    
    @UserDefault("repeatInterval", defaultValue: 0.2) // 5 FPS
    public static var repeatInterval: Double
    
    @UserDefault("windowWidth", defaultValue: 600.0)
    public static var windowWidth: Double
    
    @UserDefault("windowHeight", defaultValue: 160.0)
    public static var windowHeight: Double
    
    @UserDefault("openAIApiKey", defaultValue: "")
    static var openAIApiKey: String
}

@propertyWrapper
public struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
} 