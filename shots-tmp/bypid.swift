import CoreGraphics
let pid = Int32(CommandLine.arguments[1])!
let opt: CGWindowListOption = CommandLine.arguments.count > 2 ? [.optionAll] : [.optionOnScreenOnly]
let l = CGWindowListCopyWindowInfo(opt, kCGNullWindowID) as! [[String: Any]]
for w in l where (w[kCGWindowOwnerPID as String] as? Int32) == pid {
  let b = w[kCGWindowBounds as String] as! [String: Any]
  print(w[kCGWindowNumber as String]!, w[kCGWindowLayer as String]!, b["X"]!, b["Y"]!, b["Width"]!, b["Height"]!, w[kCGWindowOwnerName as String] ?? "", w[kCGWindowIsOnscreen as String] ?? "-")
}
