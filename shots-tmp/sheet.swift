import AppKit
let files = Array(CommandLine.arguments.dropFirst(2)); let out = CommandLine.arguments[1]
let imgs = files.map { NSImage(contentsOfFile: $0)! }
let h: CGFloat = 500
let ws = imgs.map { h * $0.size.width / $0.size.height }
let sheet = NSImage(size: NSSize(width: ws.reduce(0, +), height: h))
sheet.lockFocus(); var x: CGFloat = 0
for (i, im) in imgs.enumerated() { im.draw(in: NSRect(x: x, y: 0, width: ws[i], height: h)); x += ws[i] }
sheet.unlockFocus()
try! NSBitmapImageRep(data: sheet.tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
