import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var chatViewModel: ChatViewModel
    @ObservedObject var themeService = ThemeService.shared
    @State private var showClearHistoryConfirmation = false
    @State private var showAbout = false
    @State private var testMode = AppDelegate.isTestMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chat")) {
                    Button(action: {
                        showClearHistoryConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear Chat History")
                                .foregroundColor(.red)
                        }
                    }
                    .alert(isPresented: $showClearHistoryConfirmation) {
                        Alert(
                            title: Text("Clear History"),
                            message: Text("Are you sure you want to clear your chat history? This action cannot be undone."),
                            primaryButton: .destructive(Text("Clear")) {
                                chatViewModel.clearHistory()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                // Add appearance section
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $themeService.currentTheme) {
                        ForEach(ThemeService.ColorTheme.allCases) { theme in
                            Text(theme.name).tag(theme)
                        }
                    }
                    .onChange(of: themeService.currentTheme) { newValue in
                        themeService.setTheme(newValue)
                    }
                    
                    // Color picker for accent color
                    HStack {
                        Text("Accent Color")
                        Spacer()
                        ColorPicker("", selection: $themeService.accentColor)
                            .labelsHidden()
                            .onChange(of: themeService.accentColor) { newValue in
                                themeService.setAccentColor(newValue)
                            }
                    }
                    
                    // Reset to default color
                    Button(action: {
                        themeService.resetToDefaultColor()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Default Colors")
                        }
                    }
                }
                
                Section(header: Text("App Settings")) {
                    Toggle("Test Mode", isOn: $testMode)
                        .disabled(true) // Can only be changed in code
                    
                    if testMode {
                        Text("App is using mock data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("About Helping Hand")
                        }
                    }
                    .sheet(isPresented: $showAbout) {
                        AboutView()
                    }
                }
                
                Section(header: Text("Feedback")) {
                    Link(destination: URL(string: "mailto:feedback@helpinghand.example")!) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Send Feedback")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "hand.raised.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color("AccentColor"))
                    .padding()
                
                Text("Helping Hand")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version \(appVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                    .frame(height: 30)
                
                Text("Helping Hand is an interactive assistant designed to help you find local services and businesses quickly and easily.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("© 2025 Helping Hand App")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
