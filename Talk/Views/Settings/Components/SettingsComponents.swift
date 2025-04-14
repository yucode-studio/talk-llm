import SwiftUI

struct SettingsTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ColorTheme.secondaryTextColor())

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    .background(ColorTheme.backgroundColor())
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ColorTheme.borderColor(), lineWidth: 0.5)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    .background(ColorTheme.backgroundColor())
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ColorTheme.borderColor(), lineWidth: 0.5)
                    )
            }
        }
        .padding(.vertical, 3)
    }
}

struct SettingsSlider: View {
    var title: String
    @Binding var value: Float
    var range: ClosedRange<Float>
    var step: Float = 0.1

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorTheme.secondaryTextColor())

                Spacer()

                Text(String(format: "%.1f", value))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ColorTheme.textColor())
            }

            Slider(value: $value, in: range, step: step)
                .frame(height: 20)
        }
        .padding(.vertical, 3)
        .tint(ColorTheme.textColor())
    }
}

struct SettingsPicker<T: RawRepresentable & CaseIterable & Identifiable & Hashable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    var title: String
    @Binding var selection: T

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ColorTheme.secondaryTextColor())

            Picker("", selection: $selection) {
                ForEach(T.allCases) { option in
                    Text(option.rawValue)
                        .font(.system(size: 14))
                        .tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(height: 32)
        }
        .padding(.vertical, 3)
    }
}

#Preview("SettingsTextField") {
    VStack(spacing: 16) {
        SettingsTextField(
            title: "API Key",
            text: .constant("sample-api-key-12345"),
            placeholder: "Enter your API key"
        )

        SettingsTextField(
            title: "Password",
            text: .constant("password123"),
            placeholder: "Enter your password",
            isSecure: true
        )
    }
    .padding()
}

#Preview("SettingsSlider") {
    VStack(spacing: 16) {
        SettingsSlider(
            title: "Temperature",
            value: .constant(0.7),
            range: 0.0 ... 1.0
        )

        SettingsSlider(
            title: "Speaking Rate",
            value: .constant(1.5),
            range: 0.5 ... 2.0,
            step: 0.1
        )
    }
    .padding()
}
