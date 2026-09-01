import CoreText
import SwiftUI
import UIKit

/// Role: Seam. One typed wax accessor. Hex lives only here: #100C08 #261E14 #EDE3CF #C08A3E #8A7B62.
enum WaxFace {
    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("accent")
        static let muted = Color("muted")

        static var backgroundUI: UIColor { named("background", hex: 0x100C08) }
        static var surfaceUI: UIColor { named("surface", hex: 0x261E14) }
        static var inkUI: UIColor { named("ink", hex: 0xEDE3CF) }
        static var accentUI: UIColor { named("accent", hex: 0xC08A3E) }
        static var mutedUI: UIColor { named("muted", hex: 0x8A7B62) }

        private static func named(_ name: String, hex: UInt32) -> UIColor {
            if let color = UIColor(named: name) { return color }
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        }
    }

    enum Step: CaseIterable {
        case display
        case title
        case body
        case caption
        case figure
        case seal

        var textStyle: Font.TextStyle {
            switch self {
            case .display: .largeTitle
            case .title: .title2
            case .body: .body
            case .caption: .caption
            case .figure: .title2
            case .seal: .headline
            }
        }

        var baseSize: CGFloat {
            switch self {
            case .display: 28
            case .title: 22
            case .body: 17
            case .caption: 13
            case .figure: 22
            case .seal: 17
            }
        }

        var faceName: String {
            switch self {
            case .seal: "HoeflerText-Black"
            case .caption: "HoeflerText-Regular"
            default: "HoeflerText-Regular"
            }
        }
    }

    static let family = "Hoefler Text"
    static let space: CGFloat = 8
    static let tap: CGFloat = 44
    static let motion = Animation.easeInOut(duration: 0.28)

    static func space(_ units: Int) -> CGFloat {
        space * CGFloat(units)
    }

    static func font(_ step: Step, italic: Bool = false, category: ContentSizeCategory = .large) -> Font {
        if category.isAccessibilityCategory {
            return Font.custom("New York", size: max(12, step.baseSize), relativeTo: step.textStyle)
        }
        if step == .figure {
            return Font(oldStyleFigure(size: max(12, step.baseSize)))
        }
        let name = italic ? "HoeflerText-Italic" : step.faceName
        return Font.custom(name, size: max(12, step.baseSize), relativeTo: step.textStyle)
    }

    static func plateFont(italic: Bool = false) -> UIFont {
        let name = italic ? "HoeflerText-Italic" : "HoeflerText-Regular"
        let metrics = UIFontMetrics(forTextStyle: .body)
        let base = UIFont(name: name, size: 17) ?? UIFont.systemFont(ofSize: 17)
        return metrics.scaledFont(for: base)
    }

    @MainActor
    static func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private static func oldStyleFigure(size: CGFloat) -> UIFont {
        let base = UIFont(name: "HoeflerText-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
        let featured = UIFont(
            descriptor: base.fontDescriptor.addingAttributes([
                .featureSettings: [[
                    UIFontDescriptor.FeatureKey.type: kNumberCaseType,
                    UIFontDescriptor.FeatureKey.selector: kLowerCaseNumbersSelector,
                ]],
            ]),
            size: size
        )
        return UIFontMetrics(forTextStyle: .title2).scaledFont(for: featured)
    }
}

enum WaxFigures {
    static let integers: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func integer(_ value: Int) -> String {
        integers.string(from: NSNumber(value: value)) ?? "—"
    }

    static func day(_ date: Date) -> String {
        day.string(from: date)
    }
}

struct WaxText: ViewModifier {
    let step: WaxFace.Step
    var italic = false
    @Environment(\.sizeCategory) private var category

    func body(content: Content) -> some View {
        content.font(WaxFace.font(step, italic: italic, category: category))
    }
}

extension View {
    func wax(_ step: WaxFace.Step, italic: Bool = false) -> some View {
        modifier(WaxText(step: step, italic: italic))
    }
}
