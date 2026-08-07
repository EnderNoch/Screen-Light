import SwiftUI
import AppKit

struct OptionsView: View {
    @EnvironmentObject private var state: AppState

    private let ticks = [0, 25, 50, 75, 100]
    private var s: Strings { Strings(lang: state.lang) }

    var body: some View {
        VStack(spacing: 18) {
            topBar
            brightnessCard
            colorCard
            lightButton
            Text(s.hint)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        // Extra top inset clears the overlaid traffic-light buttons (hidden title bar).
        .padding(EdgeInsets(top: 30, leading: 22, bottom: 22, trailing: 22))
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                Text("ScreenLight")
                    .font(.system(size: 26, weight: .semibold))
                Text(s.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("", selection: $state.lang) {
                ForEach(Lang.allCases) { Text($0.short).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        }
    }

    private var brightnessCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(s.brightness).font(.headline)
                    Spacer()
                    Text("\(Int(state.brightness))")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                TickSlider(value: $state.brightness)
                    .frame(height: 26)
                HStack(spacing: 0) {
                    ForEach(Array(ticks.enumerated()), id: \.offset) { index, value in
                        Text("\(value)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if index != ticks.count - 1 { Spacer(minLength: 0) }
                    }
                }
            }
        }
    }

    private var colorCard: some View {
        card {
            HStack(spacing: 12) {
                Text(s.color).font(.headline)
                Spacer()
                ColorPicker("", selection: $state.color, supportsOpacity: false)
                    .labelsHidden()
                Button(s.white) { state.color = .white }
                    .buttonStyle(.glass)
            }
        }
    }

    private var lightButton: some View {
        Button(action: turnOnLight) {
            Label(s.light, systemImage: "sun.max.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
    }

    /// A Liquid Glass card container (macOS 26 / Tahoe).
    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    private func turnOnLight() {
        let window = NSApp.keyWindow
        LightController.shared.showLight(color: NSColor(state.color),
                                         brightness: state.brightness,
                                         optionsWindow: window)
    }
}
