// swift-tools-version: 6.1
import PackageDescription
import Foundation

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
let appSwiftSettings: [SwiftSetting] = [
    .unsafeFlags(
        homebrewIncludePaths.flatMap { ["-Xcc", "-I\($0)"] },
        .when(platforms: [.macOS])
    ),
]
let appLinkerSettings: [LinkerSetting] = [
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
#else
let appSwiftSettings: [SwiftSetting] = []
let appLinkerSettings: [LinkerSetting] = []
#endif

let package = Package(
    name: "SystemInsightsAdwaita",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "system-insights-ui", targets: ["SystemInsightsAdwaita"])
    ],
    dependencies: [
        .package(name: "SystemInsights", path: "../../.."),
        // Pinned upstream d928b464f1 with a local Swift 6.3 GLib constants compatibility patch.
        .package(path: "../../../Vendor/adwaita-swift")
    ],
    targets: [
        .executableTarget(
            name: "SystemInsightsAdwaita",
            dependencies: [
                .product(name: "SystemInsightCore", package: "SystemInsights"),
                .product(name: "Adwaita", package: "adwaita-swift")
            ],
            swiftSettings: appSwiftSettings,
            linkerSettings: appLinkerSettings
        )
    ],
    swiftLanguageModes: [.v6]
)
