import SwiftUI
import AppKit

/// An `NSSlider` (0...100) with real tick "notches" every 25, bridged into SwiftUI.
struct TickSlider: NSViewRepresentable {
    @Binding var value: Double

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(value: value,
                              minValue: 0,
                              maxValue: 100,
                              target: context.coordinator,
                              action: #selector(Coordinator.changed(_:)))
        slider.numberOfTickMarks = 5            // 0, 25, 50, 75, 100
        slider.allowsTickMarkValuesOnly = false // continuous, ticks are visual guides
        slider.tickMarkPosition = .below
        slider.isContinuous = true
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {
        if nsView.doubleValue != value {
            nsView.doubleValue = value
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        let parent: TickSlider
        init(_ parent: TickSlider) { self.parent = parent }

        @objc func changed(_ sender: NSSlider) {
            parent.value = sender.doubleValue
        }
    }
}
