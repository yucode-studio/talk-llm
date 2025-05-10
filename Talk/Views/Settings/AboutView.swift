import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                Link(destination: URL(string: "https://github.com/zm-soft/talk-llm/blob/main/PRIVACY.md")!) {
                    SettingRow(
                        title: "Privacy Policy",
                        subtitle: "Read our privacy policy",
                        iconName: "lock.shield"
                    )
                }
                .foregroundColor(ColorTheme.textColor())

                Link(destination: URL(string: "https://github.com/zm-soft/talk-llm/issues")!) {
                    SettingRow(
                        title: "Report an Issue",
                        subtitle: "Help us improve",
                        iconName: "exclamationmark.bubble"
                    )
                }
                .foregroundColor(ColorTheme.textColor())

                Link(destination: URL(string: "https://github.com/zm-soft/talk-llm")!) {
                    SettingRow(
                        title: "Open Source",
                        subtitle: "View on GitHub",
                        iconName: "chevron.left.forwardslash.chevron.right"
                    )
                }
                .foregroundColor(ColorTheme.textColor())

                HStack {
                    SettingRow(
                        title: "Version",
                        subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                        iconName: "info.circle"
                    )
                }
            } footer: {
                Text("Talk LLM is an open-source app")
                    .font(.footnote)
                    .foregroundColor(ColorTheme.secondaryTextColor())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .background(ColorTheme.backgroundColor())
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
