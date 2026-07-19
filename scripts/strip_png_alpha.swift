#!/usr/bin/env swift
import AppKit
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: strip_png_alpha.swift input.png output.png\n".utf8))
    exit(2)
}

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let context = CGContext(
        data: nil,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: image.width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
      ) else {
    FileHandle.standardError.write(Data("unable to decode input PNG\n".utf8))
    exit(3)
}

context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
guard let flattened = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
        output as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
      ) else {
    FileHandle.standardError.write(Data("unable to create output PNG\n".utf8))
    exit(4)
}

CGImageDestinationAddImage(destination, flattened, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("unable to finalize output PNG\n".utf8))
    exit(5)
}
