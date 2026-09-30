import SwiftUI

/// Colors worked out from the system accent the way Prosty Timer does it; Multicolor keeps
/// the timer's violet.
struct Palette {
    var ring: Color
    var icon: Color
    var track: Color
    /// Text on a button filled with `ring`: dark on a light accent (yellow), white otherwise.
    var onTint: Color

    init(accent: SIMD3<Double>?, dark: Bool) {
        let white = SIMD3<Double>(1, 1, 1), black = SIMD3<Double>(0, 0, 0)
        let ring: SIMD3<Double>
        if let a = accent {
            ring = dark ? a + (white - a) * 0.25 : a + (black - a) * 0.12
            let icon = dark ? a + (white - a) * 0.55 : a + (black - a) * 0.1
            self.icon = Color(red: icon.x, green: icon.y, blue: icon.z)
        } else {
            ring = dark ? [0x9B, 0x72, 0xF0] / 255 : [0x6B, 0x4F, 0xBF] / 255
            icon = dark ? Color(hex: "#C4A9FF")! : Color(hex: "#6B4FBF")!
        }
        self.ring = Color(red: ring.x, green: ring.y, blue: ring.z)
        track = dark ? .white.opacity(0.16) : Color(red: 60 / 255, green: 40 / 255, blue: 100 / 255).opacity(0.16)
        let luma = 0.2126 * ring.x + 0.7152 * ring.y + 0.0722 * ring.z
        onTint = luma > 0.62 ? Color(hex: "#1B1526")! : .white
    }
}

extension EnvironmentValues {
    @Entry var palette = Palette(accent: nil, dark: true)
}

/// Palette, accent tint, language and reading direction for everything below.
struct Themed: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let m = Model.shared
        let p = Palette(accent: m.accent, dark: scheme == .dark)
        content
            .environment(\.palette, p)
            .tint(p.ring)
            .environment(\.locale, Locale(identifier: m.activeLang))
            .environment(\.layoutDirection, Strings.rtl.contains(m.activeLang) ? .rightToLeft : .leftToRight)
    }
}

/// The options window, laid out like Prosty Timer: the dial on top growing with the window,
/// the two buttons under it like Reset and Start, then one glass pane per section reaching
/// the margins, rows split by thin lines, icons instead of row titles where they are enough.
struct OptionsView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable private var m = Model.shared

    var body: some View {
        let s = m.s
        VStack(spacing: 16) {
            GeometryReader { g in
                Dial(size: min(g.size.width, g.size.height))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minHeight: 200)

            LightButtons().controlSize(.extraLarge)

            Pane {
                Row(icon: "paintpalette") {
                    Swatches()
                    Spacer()
                }
                Row(image: Symbols.photoBooth) {
                    Text("Photo Booth")
                    Spacer()
                    Toggle("Photo Booth", isOn: $m.photoBooth)
                        .labelsHidden().toggleStyle(.switch).controlSize(.small).fixedSize()
                }
                .help(s.boothNote)
                Row(icon: "arrow.left.and.right") {
                    Slider(value: $m.edgeWidth, in: 0.04...0.3) { Text(s.width) }.labelsHidden()
                }
                .help(s.width)
            }

        }
        .padding(20)
        // Bounds like System Settings, as in the timer: one vertical layout, no full screen.
        .frame(minWidth: 420, idealWidth: 460, maxWidth: 560, minHeight: 750, idealHeight: 820, maxHeight: 1100)
        .background { WindowGlass().ignoresSafeArea() }
        .modifier(Themed())
        .onAppear { m.openMain = { openWindow(id: "main") } }
    }
}

/// Brightness as the timer's dial: a glass disc, the arc is the brightness, the middle glows
/// in the light's color. Drag along the ring, or click the number and type one.
struct Dial: View {
    let size: CGFloat
    @Environment(\.palette) private var p
    @Bindable private var m = Model.shared
    @FocusState private var typing: Bool
    /// Brightness at the previous step of a drag; nil when not dragging.
    @State private var dragFrom: Double?
    @State private var text = ""

    var body: some View {
        let line = max(8, size * 0.04)
        let rgb = NSColor(m.color).usingColorSpace(.sRGB)
        let lightLamp = (rgb.map { 0.2126 * $0.redComponent + 0.7152 * $0.greenComponent + 0.0722 * $0.blueComponent } ?? 1) > 0.6
        let ink = lightLamp ? Color(hex: "#1B1526")! : .white
        ZStack {
            Color.clear.glassEffect(.regular, in: .circle)
            Circle()
                .inset(by: line * 3)
                .fill(m.color)
                .shadow(color: m.color.opacity(0.5 * m.brightness / 100), radius: size * 0.08)
            Circle().inset(by: line).stroke(p.track, lineWidth: line)
            Circle()
                .inset(by: line)
                .trim(from: 0, to: m.brightness / 100)
                .stroke(p.ring, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: p.ring.opacity(0.55), radius: 8)
            // Knob at the end of the arc, like a slider's, so the ring reads as something to grab.
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                .frame(width: line * 1.9, height: line * 1.9)
                .offset(y: -(size / 2 - line))
                .rotationEffect(.degrees(m.brightness / 100 * 360))
            // The whole ring band takes clicks and drags, the middle stays a text field.
            // Only the band of the ring, not the lamp inside it.
            Annulus(inner: size / 2 - line * 2.5)
                .fill(Color.clear)
                // Even-odd, so the hole in the middle stays a hole for clicks too.
                .contentShape(Annulus(inner: size / 2 - line * 2.5), eoFill: true)
                .pointerStyle(dragFrom == nil ? .grabIdle : .grabActive)
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged(drag)
                    .onEnded { _ in dragFrom = nil })
            VStack(spacing: size * 0.01) {
                TextField(m.s.bright, text: $text)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: size * 0.2, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(width: size * 0.5)
                .focused($typing)
                // Return or Esc leaves the field; so does a click on the window's empty glass.
                .onSubmit { typing = false }
                .onExitCommand { typing = false }
                // Digits only, at most 100: anything else is taken out as it is typed.
                .onChange(of: text) {
                    let digits = String(text.filter { $0.isASCII && $0.isNumber }.prefix(3))
                    let value = min(Int(digits) ?? 0, 100)
                    let shown = digits.isEmpty ? "" : String(value)
                    if shown != text { text = shown }
                    if !digits.isEmpty { m.brightness = Double(value) }
                }
                .onChange(of: m.brightness, initial: true) { syncText() }
                .onChange(of: typing) { if !typing { syncText() } }
                Text(m.s.bright)
            }
            .foregroundStyle(ink)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .contain)
        .accessibilityAdjustableAction { dir in
            m.brightness = min(100, max(0, m.brightness + (dir == .increment ? 5 : -5)))
        }
    }

    /// Shows the current brightness, except while an emptied field is being typed into.
    private func syncText() {
        let now = Int(m.brightness.rounded())
        if typing && text.isEmpty { return }
        if Int(text) != now { text = String(now) }
    }

    private func drag(_ v: DragGesture.Value) {
        typing = false
        let dx = v.location.x - size / 2, dy = v.location.y - size / 2
        var turn = atan2(dx, -dy) / (2 * .pi)
        if turn < 0 { turn += 1 }
        var value = (turn * 100).rounded()
        // A click jumps straight there; only a drag running past the top stops at the end
        // instead of wrapping from full to empty or back.
        if let last = dragFrom {
            if last > 75, value < 25 { value = 100 }
            if last < 25, value > 75 { value = 0 }
        }
        dragFrom = value
        m.brightness = value
    }
}

/// A ring: the circle minus a hole of radius `inner` in the middle.
struct Annulus: Shape {
    let inner: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path(ellipseIn: rect)
        p.addEllipse(in: rect.insetBy(dx: rect.width / 2 - inner, dy: rect.height / 2 - inner))
        return p
    }
}

enum Symbols {
    /// The system's ring light, new in macOS 27; macOS 26 doesn't have it.
    static let edgeLight = NSImage(systemSymbolName: "ring.light", accessibilityDescription: nil) != nil
        ? "ring.light" : "rectangle.inset.filled"

    static let photoBooth = NSWorkspace.shared.urlForApplication(withBundleIdentifier: PhotoBooth.bundleID)
        .map { NSWorkspace.shared.icon(forFile: $0.path) }
}

/// One section: a single pane of glass, rows split by thin lines like System Settings.
struct Pane<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    if row.id != rows.first?.id { Divider().padding(.leading, 46) }
                    row
                }
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}

struct Row<Content: View>: View {
    var icon: String?
    var image: NSImage?
    @ViewBuilder var content: Content
    @Environment(\.palette) private var p

    init(icon: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.content = content()
    }

    /// A row led by a picture instead of a symbol, e.g. an app's own icon.
    init(image: NSImage?, @ViewBuilder content: () -> Content) {
        self.image = image
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image {
                    Image(nsImage: image).resizable().frame(width: 20, height: 20)
                } else {
                    Image(systemName: icon ?? "circle").foregroundStyle(p.icon)
                }
            }
            .frame(width: 20)
            content
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 40)
    }
}

/// The menu bar panel: the everyday controls and a way back to the window.
struct MenuPanel: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable private var m = Model.shared

    var body: some View {
        let s = m.s
        VStack(alignment: .leading, spacing: 14) {
            Slider(value: $m.brightness, in: 0...100) {
                Text(s.bright)
            } minimumValueLabel: {
                Image(systemName: "sun.min")
            } maximumValueLabel: {
                Image(systemName: "sun.max.fill")
            }
            .labelsHidden()
            Swatches()
            LightButtons().controlSize(.large)
            Divider()
            HStack {
                Button(s.open) {
                    openWindow(id: "main")
                    NSApp.activate()
                }
                Spacer()
                Button(s.quit) { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(width: 300)
        .modifier(Themed())
        .onAppear { m.openMain = { openWindow(id: "main") } }
    }
}

/// Edge light toggles; Light is the main action, filled with the accent like Start in the timer.
struct LightButtons: View {
    @Environment(\.palette) private var p
    private let m = Model.shared
    private let light = Light.shared

    var body: some View {
        HStack(spacing: 10) {
            if light.mode == .edge || light.mode == .booth {
                Button { light.off() } label: { edgeLabel.foregroundStyle(p.onTint) }
                    .buttonStyle(.glassProminent)
            } else {
                Button { light.toggle(.edge) } label: { edgeLabel }
                    .buttonStyle(.glass)
            }
            Button { light.show(.full) } label: {
                Label(m.s.light, systemImage: "sun.max.fill")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(p.onTint)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.glassProminent)
            .keyboardShortcut(.defaultAction)
            .help(m.s.hint)
        }
    }

    private var edgeLabel: some View {
        Label(m.s.edge, systemImage: Symbols.edgeLight).frame(maxWidth: .infinity)
    }
}

/// Quick colors (white, warm, pink, cool), then a rainbow circle for any other color, like
/// the Multicolor circle in System Settings → Appearance. It opens the system color panel and
/// shows the chosen color once one is picked.
struct Swatches: View {
    @Bindable private var m = Model.shared
    @Environment(\.palette) private var p

    var body: some View {
        let current = m.color.hex
        let custom = !Model.swatches.contains(current)
        HStack(spacing: 8) {
            ForEach(Model.swatches, id: \.self) { hex in
                circle(Color(hex: hex) ?? .white, selected: current == hex) { m.color = Color(hex: hex) ?? .white }
            }
            circle(custom ? AnyShapeStyle(m.color) : AnyShapeStyle(AngularGradient(
                colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink, .red], center: .center)),
                   selected: custom) { ColorPanel.shared.open() }
                .help(m.s.color)
        }
    }

    private func circle(_ fill: some ShapeStyle, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle().fill(fill)
                .frame(width: 20, height: 20)
                .overlay { Circle().strokeBorder(.secondary.opacity(0.5), lineWidth: 0.5) }
                .padding(3)
                .overlay {
                    if selected { Circle().strokeBorder(p.ring, lineWidth: 2) }
                }
        }
        .buttonStyle(.plain)
    }
}

/// The system color panel, wired to the light's color.
final class ColorPanel: NSObject {
    static let shared = ColorPanel()

    func open() {
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.color = NSColor(Model.shared.color)
        panel.setTarget(self)
        panel.setAction(#selector(changed(_:)))
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func changed(_ panel: NSColorPanel) {
        Model.shared.color = Color(nsColor: panel.color)
    }
}

/// The whole window is one pane of the system's Liquid Glass, title bar included, like the
/// timer. Being the system's own glass, it follows the Liquid Glass slider in System Settings
/// → Appearance as it moves, with nothing to switch here.
struct WindowGlass: NSViewRepresentable {
    func makeNSView(context: Context) -> Holder { Holder() }
    func updateNSView(_ holder: Holder, context: Context) {}

    final class Holder: NSView {
        override init(frame: NSRect) {
            super.init(frame: frame)
            let glass = NSGlassEffectView()
            glass.style = .regular
            glass.cornerRadius = 0
            glass.frame = bounds
            glass.autoresizingMask = [.width, .height]
            addSubview(glass)
        }

        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let w = window else { return }
            w.isOpaque = false
            w.backgroundColor = .clear
            w.titlebarAppearsTransparent = true
            w.styleMask.insert(.fullSizeContentView)
            // Open with nothing focused; otherwise AppKit puts the caret in the dial's number.
            w.initialFirstResponder = nil
            DispatchQueue.main.async { w.makeFirstResponder(nil) }
        }

        // The glass behind everything gets the clicks that miss the controls: they end
        // typing and still drag the window.
        override func hitTest(_ point: NSPoint) -> NSView? {
            super.hitTest(point) == nil ? nil : self
        }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(nil)
            window?.performDrag(with: event)
        }
    }
}
