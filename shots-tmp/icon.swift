import AppKit
let (app, out) = (CommandLine.arguments[1], CommandLine.arguments[2])
let S = 256
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus(); NSWorkspace.shared.icon(forFile: app).draw(in: NSRect(x: 0, y: 0, width: S, height: S)); img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
