import SwiftUI
import Settings

struct GeneralPreferenceView: View {
    @AppStorage("initialRepeatDelay") private var initialRepeatDelay = UserSettings.initialRepeatDelay
    @AppStorage("repeatInterval") private var repeatInterval = UserSettings.repeatInterval
    @AppStorage("windowWidth") private var windowWidth = UserSettings.windowWidth
    @AppStorage("windowHeight") private var windowHeight = UserSettings.windowHeight
    @AppStorage("openAIApiKey") private var openAIApiKey = UserSettings.openAIApiKey
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Timing")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Initial Repeat Delay:")
                            HStack(spacing: 16) {
                                Slider(value: $initialRepeatDelay, in: 0.1...1.0)
                                Text("\(initialRepeatDelay, specifier: "%.2f")s")
                                    .frame(width: 50, alignment: .trailing)
                                    .monospacedDigit()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Repeat Interval:")
                            HStack(spacing: 16) {
                                Slider(value: $repeatInterval, in: 0.1...0.5)
                                Text("\(repeatInterval, specifier: "%.2f")s")
                                    .frame(width: 50, alignment: .trailing)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Window")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Width:")
                            HStack(spacing: 16) {
                                Slider(value: $windowWidth, in: 400...800)
                                Text("\(Int(windowWidth))px")
                                    .frame(width: 50, alignment: .trailing)
                                    .monospacedDigit()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Height:")
                            HStack(spacing: 16) {
                                Slider(value: $windowHeight, in: 100...300)
                                Text("\(Int(windowHeight))px")
                                    .frame(width: 50, alignment: .trailing)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Settings")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OpenAI API Key:")
                        SecureField("sk-...", text: $openAIApiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 