// Patch.swift — removes the simulator's DEBUG ribbon from ASC captures.
//
// All buffers are top-down (row 0 = top of image), via NSBitmapImageRep
// + NSGraphicsContext draw (no manual row flipping).
//
//   portrait:  1) pastes the top 170px status-bar strip of the accepted
//               reference (screenshots/ios/home.png — clock, Dynamic Island,
//               icons, flat #2D2D2D, no ribbon) onto the capture;
//              2) erases the thin diagonal ribbon stripe that can extend a
//               few rows below the pasted strip (band along the line
//               (1035,0)->(1206,162), ~60px wide, up to y=200).
//   landscape: paints the top-right corner zone (x 2400..w, y 0..320) with
//               per-column colors sampled from y=340 — that zone is the
//               black screen-corner curve (+ ribbon), so the result is
//               seamless.
//
// Usage:
//   swift Patch.swift portrait  <input.png> <output.png> <reference.png>
//   swift Patch.swift landscape <input.png> <output.png>

import Cocoa

func loadBuffer(_ path: String) -> [UInt8] {
  guard let img = NSImage(contentsOfFile: path),
        let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("cannot load \(path)\n".data(using: .utf8)!)
    exit(1)
  }
  let w = cg.width, h = cg.height
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                             isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: w * 4, bitsPerPixel: 32)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  img.draw(in: NSRect(x: 0, y: 0, width: w, height: h),
           from: .zero, operation: .copy, fraction: 1)
  NSGraphicsContext.restoreGraphicsState()
  guard let data = rep.bitmapData else { exit(1) }
  return Array(UnsafeBufferPointer(start: data, count: h * w * 4))
}

func saveBuffer(_ buf: [UInt8], _ w: Int, _ h: Int, _ path: String) {
  // 24-bit RGB, NO alpha channel — App Store Connect rejects PNGs that carry
  // an alpha channel, even when fully opaque.
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                             bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
                             isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: w * 3, bitsPerPixel: 24)!
  var rgb = [UInt8](repeating: 0, count: h * w * 3)
  for i in 0..<(h * w) {
    let s = i * 4
    rgb[i * 3] = buf[s]
    rgb[i * 3 + 1] = buf[s + 1]
    rgb[i * 3 + 2] = buf[s + 2]
  }
  rgb.withUnsafeBufferPointer { p in
    memcpy(rep.bitmapData!, p.baseAddress!, h * w * 3)
  }
  let data = rep.representation(using: .png, properties: [:])!
  try! data.write(to: URL(fileURLWithPath: path))
  print("wrote \(path) (\(w)x\(h))")
}

let a = CommandLine.arguments
guard a.count == 4 || a.count == 5 else {
  FileHandle.standardError.write("see header for usage\n".data(using: .utf8)!)
  exit(1)
}
let mode = a[1]
let img0 = NSImage(contentsOfFile: a[2])!
let w = Int(img0.size.width)
let h = Int(img0.size.height)
var buf = loadBuffer(a[2])
@inline(__always) func idx(_ x: Int, _ y: Int) -> Int { (y * w + x) * 4 }

if mode == "portrait" {
  guard a.count == 5 else { exit(1) }
  let ref = loadBuffer(a[4])
  // 1) status-bar strip from the accepted reference (flat #2D2D2D, no ribbon).
  let stripH = 170
  for y in 0..<stripH {
    let off = y * w * 4
    for x in 0..<(w * 4) { buf[off + x] = ref[off + x] }
  }
  // 2) erase the diagonal ribbon stripe tail that extends below the pasted
  //    strip (rows 160..210, top-right corner only — status-bar icons live
  //    above row 120 and are untouched). Reddish runs are replaced by the
  //    flat #2D2D2D background, with an 8px margin for anti-aliased edges.
  for y in 160..<210 {
    var x = 1050
    while x < w {
      let o = idx(x, y)
      let r = Int(buf[o]), g = Int(buf[o + 1]), b = Int(buf[o + 2])
      if r > 100 && r > g + 30 && r > b + 30 {
        var x1 = x
        while x1 + 1 < w {
          let o1 = idx(x1 + 1, y)
          let r1 = Int(buf[o1]), g1 = Int(buf[o1 + 1]), b1 = Int(buf[o1 + 2])
          if !(r1 > 100 && r1 > g1 + 30 && r1 > b1 + 30) { break }
          x1 += 1
        }
        let f0 = max(0, x - 8), f1 = min(w - 1, x1 + 8)
        for xf in f0...f1 {
          let ox = idx(xf, y)
          buf[ox] = 0x2D; buf[ox + 1] = 0x2D; buf[ox + 2] = 0x2D; buf[ox + 3] = 0xFF
        }
        x = x1 + 1
      } else {
        x += 1
      }
    }
  }
  saveBuffer(buf, w, h, a[3])
} else if mode == "landscape" {
  let x0 = 2400
  let y1 = 320
  let ySample = 340
  guard y1 < h, ySample < h, x0 < w else { exit(1) }
  for x in x0..<w {
    let s = idx(x, ySample)
    let r = buf[s], g = buf[s + 1], b = buf[s + 2], al = buf[s + 3]
    for y in 0..<y1 {
      let o = idx(x, y)
      buf[o] = r; buf[o + 1] = g; buf[o + 2] = b; buf[o + 3] = al
    }
  }
  saveBuffer(buf, w, h, a[3])
} else {
  FileHandle.standardError.write("unknown mode \(mode)\n".data(using: .utf8)!)
  exit(1)
}
