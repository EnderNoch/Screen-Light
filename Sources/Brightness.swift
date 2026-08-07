import CoreGraphics
import Darwin

/// Thin wrapper over the private `DisplayServices` framework to read/write the built-in
/// display's backlight. There is no public API for this on Apple Silicon; this is the same
/// approach used by tools like MonitorControl and the `brightness` CLI.
///
/// Everything is guarded: if the framework or symbols ever go away, the calls become no-ops
/// and `isAvailable` reports `false`, so the rest of the app (the on-screen light) still works.
enum Brightness {
    private typealias SetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private typealias GetFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

    private static let handle: UnsafeMutableRawPointer? = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
        RTLD_NOW
    )

    private static let setFn: SetFn? = {
        guard let h = handle, let sym = dlsym(h, "DisplayServicesSetBrightness") else { return nil }
        return unsafeBitCast(sym, to: SetFn.self)
    }()

    private static let getFn: GetFn? = {
        guard let h = handle, let sym = dlsym(h, "DisplayServicesGetBrightness") else { return nil }
        return unsafeBitCast(sym, to: GetFn.self)
    }()

    static var isAvailable: Bool { setFn != nil }

    /// Set the backlight. `value` is 0...100.
    @discardableResult
    static func set(_ value: Double, display: CGDirectDisplayID = CGMainDisplayID()) -> Bool {
        guard let setFn = setFn else { return false }
        let level = Float(max(0, min(100, value)) / 100.0)
        return setFn(display, level) == 0
    }

    /// Current backlight as 0...100, or `nil` if it can't be read.
    static func get(display: CGDirectDisplayID = CGMainDisplayID()) -> Double? {
        guard let getFn = getFn else { return nil }
        var level: Float = 0
        guard getFn(display, &level) == 0 else { return nil }
        return Double(level) * 100.0
    }
}
