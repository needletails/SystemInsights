// swift-tools-version: 6.1
//
//  Package.swift
//  Adwaita
//
//  Created by david-swift on 08.06.23.
//

import PackageDescription
import Foundation

/// The dependencies.
var dependencies: [Package.Dependency] = [
    .package(url: "https://git.aparoksha.dev/aparoksha/meta", branch: "main"),
    .package(url: "https://git.aparoksha.dev/aparoksha/meta-sqlite", branch: "main"),
    .package(
        url: "https://git.aparoksha.dev/aparoksha/levenshtein-transformations",
        branch: "main"
    ),
    .package(url: "https://github.com/CoreOffice/XMLCoder", from: "0.17.1")
]

#if os(Linux)
dependencies.append(.package(url: "https://github.com/stephencelis/CSQLite", from: "3.50.4"))
#endif

#if os(macOS)
let homebrewPrefixes = ["/opt/homebrew", "/usr/local"]
let homebrewIncludeSubpaths = [
    "opt/libadwaita/include/libadwaita-1",
    "opt/gtk4/include/gtk-4.0",
    "opt/pango/include/pango-1.0",
    "opt/harfbuzz/include/harfbuzz",
    "opt/graphite2/include",
    "include/gdk-pixbuf-2.0",
    "opt/libtiff/include",
    "opt/jpeg-turbo/include",
    "opt/cairo/include/cairo",
    "opt/fontconfig/include",
    "opt/freetype/include/freetype2",
    "opt/libpng/include/libpng16",
    "opt/libxext/include",
    "opt/xorgproto/include",
    "opt/libxrender/include",
    "opt/libx11/include",
    "opt/libxcb/include",
    "opt/libxau/include",
    "opt/libxdmcp/include",
    "opt/pixman/include/pixman-1",
    "opt/graphene/include/graphene-1.0",
    "opt/graphene/lib/graphene-1.0/include",
    "opt/fribidi/include/fribidi",
    "opt/appstream/include/appstream",
    "opt/libxmlb/include/libxmlb-2",
    "opt/glib/include",
    "opt/glib/include/glib-2.0",
    "opt/glib/lib/glib-2.0/include",
    "opt/gettext/include",
    "opt/pcre2/include",
    "opt/xz/include",
    "opt/libfyaml/include",
    "opt/zstd/include",
]
let homebrewLibrarySubpaths = [
    "lib",
    "opt/libadwaita/lib",
    "opt/gtk4/lib",
    "opt/pango/lib",
    "opt/harfbuzz/lib",
    "opt/gdk-pixbuf/lib",
    "opt/cairo/lib",
    "opt/graphene/lib",
    "opt/glib/lib",
    "opt/gettext/lib",
]
let homebrewIncludePaths = homebrewPrefixes.flatMap { prefix in
    homebrewIncludeSubpaths
        .map { "\(prefix)/\($0)" }
        .filter { FileManager.default.fileExists(atPath: $0) }
}
let homebrewLibraryPaths = homebrewPrefixes.flatMap { prefix in
    homebrewLibrarySubpaths
        .map { "\(prefix)/\($0)" }
        .filter { FileManager.default.fileExists(atPath: $0) }
}
let adwaitaSwiftSettings: [SwiftSetting] = [
    .unsafeFlags(
        homebrewIncludePaths.flatMap { ["-Xcc", "-I\($0)"] },
        .when(platforms: [.macOS])
    ),
]
let cAdwCSettings: [CSetting] = [
    .unsafeFlags(
        homebrewIncludePaths.map { "-I\($0)" },
        .when(platforms: [.macOS])
    ),
]
let adwaitaLinkerSettings: [LinkerSetting] = [
    .unsafeFlags(
        homebrewLibraryPaths.map { "-L\($0)" } + [
            "-ladwaita-1",
            "-lgtk-4",
            "-lpangocairo-1.0",
            "-lpango-1.0",
            "-lharfbuzz",
            "-lgdk_pixbuf-2.0",
            "-lcairo-gobject",
            "-lcairo",
            "-lgraphene-1.0",
            "-lgio-2.0",
            "-lgobject-2.0",
            "-lglib-2.0",
            "-lintl",
        ],
        .when(platforms: [.macOS])
    ),
]
let cAdwTarget: Target = .target(
    name: "CAdw",
    path: "Sources/CAdw",
    sources: ["dummy.c"],
    publicHeadersPath: ".",
    cSettings: cAdwCSettings,
    linkerSettings: adwaitaLinkerSettings
)
#else
let adwaitaSwiftSettings: [SwiftSetting] = []
let adwaitaLinkerSettings: [LinkerSetting] = []
let cAdwTarget: Target = .systemLibrary(
    name: "CAdw",
    pkgConfig: "libadwaita-1"
)
#endif

/// The Adwaita package.
let package = Package(
    name: "Adwaita",
    platforms: [.macOS(.v13), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "Adwaita",
            targets: ["Adwaita"]
        ),
        .library(
            name: "CAdw",
            targets: ["CAdw"]
        )
    ],
    traits: [.trait(name: "exposeGeneratedAppearUpdateFunctions")],
    dependencies: dependencies,
    targets: [
        cAdwTarget,
        .target(
            name: "Adwaita",
            dependencies: [
                "CAdw",
                .product(name: "LevenshteinTransformations", package: "levenshtein-transformations"),
                .product(name: "Meta", package: "meta"),
                .product(name: "MetaSQLite", package: "meta-sqlite")
            ],
            swiftSettings: adwaitaSwiftSettings,
            linkerSettings: adwaitaLinkerSettings
        ),
        .executableTarget(
            name: "Generation",
            dependencies: [
                .product(name: "XMLCoder", package: "XMLCoder")
            ]
        ),
        .executableTarget(
            name: "Demo",
            dependencies: ["Adwaita"]
        )
    ],
    swiftLanguageModes: [.v5]
)
