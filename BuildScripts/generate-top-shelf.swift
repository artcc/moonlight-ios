// Run from the project root: swift BuildScripts/generate-top-shelf.swift
// Regenerates the static tvOS Top Shelf images from the current app icon artwork.

import CoreGraphics
import Foundation
import ImageIO

enum ArtworkError: Error {
    case invalidImage(URL)
    case renderFailed
    case writeFailed(URL)
}

struct ImageSet: Decodable {
    struct Image: Decodable {
        let filename: String
        let scale: String
    }

    let images: [Image]
}

func loadImage(at url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw ArtworkError.invalidImage(url)
    }
    return image
}

func centeredRect(for image: CGImage, in bounds: CGRect, fill: Bool) -> CGRect {
    let widthScale = bounds.width / CGFloat(image.width)
    let heightScale = bounds.height / CGFloat(image.height)
    let scale = fill ? max(widthScale, heightScale) : min(widthScale, heightScale)
    let width = CGFloat(image.width) * scale
    let height = CGFloat(image.height) * scale
    return CGRect(x: bounds.midX - width / 2, y: bounds.midY - height / 2, width: width, height: height)
}

func render(background: CGImage, logo: CGImage, width: Int, scale: Int, to url: URL) throws {
    let pixelWidth = width * scale
    let pixelHeight = 720 * scale
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(data: nil, width: pixelWidth, height: pixelHeight,
                                  bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw ArtworkError.renderFailed
    }

    let bounds = CGRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
    context.interpolationQuality = .high
    context.draw(background, in: centeredRect(for: background, in: bounds, fill: true))

    // Keep the logo centered and comfortably inside the visible area in both formats.
    let logoWidth = 512 * scale
    let logoHeight = CGFloat(logoWidth) * 0.6
    let logoBounds = CGRect(x: bounds.midX - CGFloat(logoWidth) / 2,
                            y: bounds.midY - logoHeight / 2,
                            width: CGFloat(logoWidth), height: logoHeight)
    context.draw(logo, in: centeredRect(for: logo, in: logoBounds, fill: false))

    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        throw ArtworkError.writeFailed(url)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw ArtworkError.writeFailed(url)
    }
}

let project = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let artwork = project.appendingPathComponent("Limelight/AppIcon.icon/Assets")
let background = try loadImage(at: artwork.appendingPathComponent("background.png"))
let logo = try loadImage(at: artwork.appendingPathComponent("logo.png"))
let assets = project.appendingPathComponent("Moonlight TV/Assets.xcassets/App Icon & Top Shelf Image.brandassets")

for (name, width) in [("Top Shelf Image.imageset", 1920), ("Top Shelf Image Wide.imageset", 2320)] {
    let folder = assets.appendingPathComponent(name)
    let contents = try Data(contentsOf: folder.appendingPathComponent("Contents.json"))
    let imageSet = try JSONDecoder().decode(ImageSet.self, from: contents)
    for image in imageSet.images {
        let scale = image.scale == "2x" ? 2 : 1
        try render(background: background, logo: logo, width: width, scale: scale,
                   to: folder.appendingPathComponent(image.filename))
    }
}
