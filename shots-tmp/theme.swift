// theme get | dark | light | auto   (SkyLight, the same calls System Settings uses)
import Foundation
let h = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)
typealias GetB = @convention(c) () -> Bool
typealias SetB = @convention(c) (Bool) -> Void
func sym<T>(_ n: String, _ t: T.Type) -> T? { dlsym(h, n).map { unsafeBitCast($0, to: t) } }
let getDark = sym("SLSGetAppearanceThemeLegacy", GetB.self)
let setDark = sym("SLSSetAppearanceThemeLegacy", SetB.self)
let getAuto = sym("SLSGetAppearanceThemeSwitchesAutomatically", GetB.self)
let setAuto = sym("SLSSetAppearanceThemeSwitchesAutomatically", SetB.self)
print("symbols:", getDark != nil, setDark != nil, getAuto != nil, setAuto != nil)
switch CommandLine.arguments.dropFirst().first ?? "get" {
case "dark": setAuto?(false); setDark?(true)
case "light": setAuto?(false); setDark?(false)
case "auto": setAuto?(true)
default: break
}
print("dark:", getDark?() as Any, "auto:", getAuto?() as Any)
