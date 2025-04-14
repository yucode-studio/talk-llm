import SwiftUI

struct SettingRow: View {
    var title: String
    var subtitle: String
    var iconName: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .font(.system(size: 22))
                .foregroundColor(ColorTheme.accentColor())
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorTheme.textColor())

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(ColorTheme.secondaryTextColor())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        SettingRow(
            title: "Large Language Model",
            subtitle: "OpenAI",
            iconName: "brain"
        )

        SettingRow(
            title: "Speech Recognition",
            subtitle: "WhisperKit",
            iconName: "waveform"
        )

        SettingRow(
            title: "Text-to-Speech",
            subtitle: "Microsoft",
            iconName: "speaker.wave.2"
        )
    }
    .listStyle(InsetGroupedListStyle())
}
