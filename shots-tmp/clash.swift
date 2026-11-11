// clash <owner> x y w h  -> prints owners of other normal windows intersecting the rect
import CoreGraphics
import Foundation
let a = CommandLine.arguments
let owner = a[1]
let r = CGRect(x: Double(a[2])!, y: Double(a[3])!, width: Double(a[4])!, height: Double(a[5])!)
let l = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
var seen = Set<String>()
for w in l where (w[kCGWindowLayer as String] as? Int) == 0 {
  let o = w[kCGWindowOwnerName as String] as? String ?? "?"
  guard o != owner, let b = w[kCGWindowBounds as String] as? NSDictionary, let f = CGRect(dictionaryRepresentation: b) else { continue }
  if f.intersects(r) && f.width > 1 && f.height > 1 && !seen.contains(o) { seen.insert(o); print(o) }
}
