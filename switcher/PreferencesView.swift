import SwiftUI

struct PreferencesView: View {
    @AppStorage(UserSettings.Keys.openAIApiKey) private var apiKey = ""
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI API")) {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                
                Text("Enter your OpenAI API key to enable app categorization")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 200)
    }
} 