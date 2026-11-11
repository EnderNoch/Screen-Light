import CoreGraphics
let l = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in l where (w[kCGWindowLayer as String] as? Int) == 0 {
  let b = w[kCGWindowBounds as String] as! [String: Any]
  print(w[kCGWindowOwnerName as String] ?? "?", w[kCGWindowOwnerPID as String]!, b["X"]!, b["Y"]!, b["Width"]!, b["Height"]!)
}
