import SwiftUI
import UIKit

/// Role: Plate. UIView pugillares hinge. Two CALayer wax recesses; shutters stay down until Seal; CATransform3D opens the seam.
final class PugillaresHingeView: UIView, UITextViewDelegate {
    var onInk: ((HandSide, String) -> Void)?
    var onHand: ((HandSide) -> Void)?
    var snapshot = DiptychSnapshot(
        leafID: UUID(),
        dayKey: LeafDayKey.from(Date(), calendar: .current),
        writing: .alpha,
        alpha: .drafting(""),
        beta: .shuttered,
        prompt: nil,
        canSeal: false,
        isSealed: false,
        isEmpty: true,
        isRevealing: false
    )

    private let leftBoard = CALayer()
    private let rightBoard = CALayer()
    private let leftRecess = CALayer()
    private let rightRecess = CALayer()
    private let leftShutter = CALayer()
    private let rightShutter = CALayer()
    private let hingeRail = CALayer()
    private let hingeRingTop = CALayer()
    private let hingeRingBottom = CALayer()
    private let leftInk = UITextView()
    private let rightInk = UITextView()
    private let leftInkLabel = UILabel()
    private let rightInkLabel = UILabel()
    private let leftHint = UILabel()
    private let rightHint = UILabel()
    private let leftCover = UIButton(type: .custom)
    private let rightCover = UIButton(type: .custom)
    private let leftName = UILabel()
    private let rightName = UILabel()
    private let shutterVoice = UILabel()
    private var reduceMotion = false
    private var lastWriting: HandSide?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        backgroundColor = .clear
        clipsToBounds = false

        for layer in [leftBoard, rightBoard] {
            layer.backgroundColor = WaxFace.Palette.surfaceUI.cgColor
            layer.borderColor = WaxFace.Palette.accentUI.withAlphaComponent(0.7).cgColor
            layer.borderWidth = 1
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            self.layer.addSublayer(layer)
        }
        for recess in [leftRecess, rightRecess] {
            recess.backgroundColor = WaxFace.Palette.backgroundUI.cgColor
            recess.borderColor = WaxFace.Palette.accentUI.cgColor
            recess.borderWidth = 2
        }
        leftBoard.addSublayer(leftRecess)
        rightBoard.addSublayer(rightRecess)

        for shutter in [leftShutter, rightShutter] {
            shutter.backgroundColor = WaxFace.Palette.surfaceUI.cgColor
            shutter.borderColor = WaxFace.Palette.accentUI.cgColor
            shutter.borderWidth = 2
        }
        leftBoard.addSublayer(leftShutter)
        rightBoard.addSublayer(rightShutter)

        hingeRail.backgroundColor = WaxFace.Palette.accentUI.cgColor
        layer.addSublayer(hingeRail)
        for ring in [hingeRingTop, hingeRingBottom] {
            ring.backgroundColor = WaxFace.Palette.accentUI.cgColor
            ring.borderColor = WaxFace.Palette.inkUI.withAlphaComponent(0.2).cgColor
            ring.borderWidth = 1
            ring.cornerRadius = 7
            layer.addSublayer(ring)
        }

        configureName(leftName, text: "North plate")
        configureName(rightName, text: "South plate")
        addSubview(leftName)
        addSubview(rightName)
        configureInk(leftInk, hand: .alpha)
        configureInk(rightInk, hand: .beta)
        addSubview(leftInk)
        addSubview(rightInk)
        configureInkLabel(leftInkLabel, hand: .alpha)
        configureInkLabel(rightInkLabel, hand: .beta)
        addSubview(leftInkLabel)
        addSubview(rightInkLabel)
        configureHint(leftHint, text: "Tap here and write the north half.")
        configureHint(rightHint, text: "Tap here and write the south half.")
        addSubview(leftHint)
        addSubview(rightHint)
        configureCover(leftCover, title: "Hidden. Tap if you are North.", hand: .alpha)
        configureCover(rightCover, title: "Hidden. Tap if you are South.", hand: .beta)
        addSubview(leftCover)
        addSubview(rightCover)

        shutterVoice.isHidden = true
        shutterVoice.accessibilityTraits = .none
        addSubview(shutterVoice)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func apply(
        _ snapshot: DiptychSnapshot,
        reduceMotion: Bool,
        alphaName: String = "North",
        betaName: String = "South"
    ) {
        self.snapshot = snapshot
        self.reduceMotion = reduceMotion
        leftName.text = "\(alphaName)’s note"
        rightName.text = "\(betaName)’s note"
        leftHint.text = "Tap here and write \(alphaName)’s note."
        rightHint.text = "Tap here and write \(betaName)’s note."
        applyCoverTitle(leftCover, text: "Hidden. Tap if you are \(alphaName).")
        applyCoverTitle(rightCover, text: "Hidden. Tap if you are \(betaName).")
        let left = snapshot.alpha.readableInk ?? ""
        let right = snapshot.beta.readableInk ?? ""
        if leftInk.text != left, !leftInk.isFirstResponder {
            leftInk.text = left
        }
        if rightInk.text != right, !rightInk.isFirstResponder {
            rightInk.text = right
        }
        leftInk.isEditable = snapshot.alpha.isDrafting && !snapshot.isSealed
        rightInk.isEditable = snapshot.beta.isDrafting && !snapshot.isSealed
        leftInk.isUserInteractionEnabled = leftInk.isEditable
        rightInk.isUserInteractionEnabled = rightInk.isEditable
        leftInk.accessibilityElementsHidden = snapshot.alpha.isShuttered
        rightInk.accessibilityElementsHidden = snapshot.beta.isShuttered
        leftHint.isHidden = !showsHint(snapshot.alpha)
        rightHint.isHidden = !showsHint(snapshot.beta)
        leftCover.isHidden = !snapshot.alpha.isShuttered
        rightCover.isHidden = !snapshot.beta.isShuttered
        leftShutter.opacity = snapshot.alpha.isShuttered ? 1 : 0
        rightShutter.opacity = snapshot.beta.isShuttered ? 1 : 0
        paintInkLabels()
        shutterVoice.accessibilityLabel = shutterCaption
        layoutBoards(in: bounds)
        moveShutters(animated: !reduceMotion)
        openHinge(snapshot.isSealed || snapshot.isRevealing, animated: !reduceMotion)
        accessibilityElements = snapshot.isSealed || snapshot.isRevealing
            ? [leftInk, rightInk]
            : visibleChrome
        let writingChanged = lastWriting != snapshot.writing
        lastWriting = snapshot.writing
        if writingChanged {
            focusWritingPlate()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutBoards(in: bounds)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if snapshot.isSealed || snapshot.isRevealing || snapshot.canSeal {
            return super.hitTest(point, with: event)
        }
        for cover in [leftCover, rightCover] where !cover.isHidden {
            let local = cover.convert(point, from: self)
            if cover.bounds.contains(local) {
                return cover
            }
        }
        let own = ownInk
        let local = own.convert(point, from: self)
        if own.bounds.contains(local) {
            return own
        }
        return nil
    }

    func textViewDidChange(_ textView: UITextView) {
        let hand: HandSide = textView === leftInk ? .alpha : .beta
        onInk?(hand, textView.text ?? "")
        if textView === leftInk {
            leftHint.isHidden = !showsHint(snapshot.replacing(hand: .alpha, ink: textView.text ?? "").alpha)
        } else {
            rightHint.isHidden = !showsHint(snapshot.replacing(hand: .beta, ink: textView.text ?? "").beta)
        }
        paintInkLabels()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.textColor = WaxFace.Palette.inkUI
        paintInkLabels()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        paintInkLabels()
    }

    private var ownInk: UITextView {
        snapshot.writing == .alpha ? leftInk : rightInk
    }

    private func focusWritingPlate() {
        guard !snapshot.isSealed else { return }
        let target = ownInk
        guard target.isEditable else { return }
        Task { @MainActor [weak self] in
            guard let self, target.isEditable, self.ownInk === target else { return }
            _ = target.becomeFirstResponder()
        }
    }

    private var visibleChrome: [UIView] {
        var items: [UIView] = []
        if !leftCover.isHidden { items.append(leftCover) } else { items.append(leftInk) }
        if !rightCover.isHidden { items.append(rightCover) } else { items.append(rightInk) }
        items.append(shutterVoice)
        return items
    }

    private var shutterCaption: String {
        if snapshot.canSeal {
            return "Both plates hold ink. Seal the seam."
        }
        let other = snapshot.writing == .alpha ? "South" : "North"
        return "\(other) plate is shuttered. Tap it to write that half."
    }

    private func showsHint(_ face: PlateFace) -> Bool {
        guard face.isDrafting else { return false }
        return (face.readableInk ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func paintInkLabels() {
        leftInkLabel.text = leftInk.text
        rightInkLabel.text = rightInk.text
        leftInkLabel.isHidden = true
        rightInkLabel.isHidden = true
        leftInk.textColor = WaxFace.Palette.inkUI
        rightInk.textColor = WaxFace.Palette.inkUI
    }

    private func configureCover(_ button: UIButton, title: String, hand: HandSide) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WaxFace.plateFont(italic: true)
            outgoing.foregroundColor = WaxFace.Palette.accentUI
            return outgoing
        }
        config.titleAlignment = .center
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        button.configuration = config
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.accessibilityLabel = hand == .alpha ? "North plate shuttered" : "South plate shuttered"
        button.accessibilityHint = "Opens this plate to write"
        button.addAction(UIAction { [weak self] _ in
            self?.onHand?(hand)
        }, for: .touchUpInside)
    }

    private func applyCoverTitle(_ button: UIButton, text: String) {
        var config = button.configuration ?? .plain()
        config.title = text
        button.configuration = config
    }

    private func configureHint(_ label: UILabel, text: String) {
        label.text = text
        label.textColor = WaxFace.Palette.inkUI
        label.font = WaxFace.plateFont(italic: true)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.isUserInteractionEnabled = false
        label.adjustsFontForContentSizeCategory = true
    }

    private func configureInkLabel(_ label: UILabel, hand: HandSide) {
        label.textColor = WaxFace.Palette.inkUI
        label.font = WaxFace.plateFont()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.isUserInteractionEnabled = false
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = hand == .alpha ? "North plate" : "South plate"
    }

    private func configureName(_ label: UILabel, text: String) {
        label.text = text
        label.textColor = WaxFace.Palette.inkUI
        label.font = WaxFace.plateFont(italic: true)
        label.numberOfLines = 1
        label.isUserInteractionEnabled = false
        label.adjustsFontForContentSizeCategory = true
    }

    private func configureInk(_ view: UITextView, hand: HandSide) {
        view.delegate = self
        view.backgroundColor = .clear
        view.textColor = WaxFace.Palette.inkUI
        view.tintColor = WaxFace.Palette.accentUI
        view.font = WaxFace.plateFont()
        view.keyboardAppearance = .dark
        view.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        view.adjustsFontForContentSizeCategory = true
        view.accessibilityLabel = hand == .alpha ? "North plate" : "South plate"
    }

    private func layoutBoards(in rect: CGRect) {
        guard rect.width > 8, rect.height > 8 else { return }
        let gap = WaxFace.space
        let wood = WaxFace.space * 2
        let rail = WaxFace.space * 2
        let nameBand = WaxFace.space * 3
        let boardWidth = (rect.width - rail - gap * 2) / 2
        let height = rect.height
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        leftBoard.bounds = CGRect(x: 0, y: 0, width: boardWidth, height: height)
        rightBoard.bounds = CGRect(x: 0, y: 0, width: boardWidth, height: height)
        leftBoard.position = CGPoint(x: gap + boardWidth / 2, y: height / 2)
        rightBoard.position = CGPoint(x: rect.width - gap - boardWidth / 2, y: height / 2)
        let recess = CGRect(
            x: wood,
            y: wood + nameBand,
            width: boardWidth - wood * 2,
            height: max(44, height - wood * 2 - nameBand)
        )
        leftRecess.frame = recess
        rightRecess.frame = recess
        leftShutter.frame = recess
        rightShutter.frame = recess
        hingeRail.frame = CGRect(x: (rect.width - 4) / 2, y: gap, width: 4, height: height - gap * 2)
        hingeRingTop.frame = CGRect(x: (rect.width - 14) / 2, y: gap * 2, width: 14, height: 14)
        hingeRingBottom.frame = CGRect(x: (rect.width - 14) / 2, y: height - gap * 2 - 14, width: 14, height: 14)
        CATransaction.commit()

        let leftInkFrame = CGRect(
            x: gap + wood,
            y: wood + nameBand,
            width: boardWidth - wood * 2,
            height: max(44, height - wood * 2 - nameBand)
        )
        leftInk.frame = leftInkFrame
        let rightInkFrame = CGRect(
            x: rect.width - gap - boardWidth + wood,
            y: wood + nameBand,
            width: boardWidth - wood * 2,
            height: max(44, height - wood * 2 - nameBand)
        )
        rightInk.frame = rightInkFrame
        let labelInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        leftInkLabel.frame = leftInkFrame.inset(by: labelInset)
        rightInkLabel.frame = rightInkFrame.inset(by: labelInset)
        leftHint.frame = leftInkFrame.insetBy(dx: 10, dy: 12)
        rightHint.frame = rightInkFrame.insetBy(dx: 10, dy: 12)
        leftCover.frame = leftInkFrame
        rightCover.frame = rightInkFrame
        leftName.frame = CGRect(x: gap + wood, y: wood, width: boardWidth - wood * 2, height: nameBand)
        rightName.frame = CGRect(
            x: rect.width - gap - boardWidth + wood,
            y: wood,
            width: boardWidth - wood * 2,
            height: nameBand
        )
        shutterVoice.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    private func moveShutters(animated: Bool) {
        let duration: CFTimeInterval = animated ? 0.28 : 0
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        leftShutter.opacity = snapshot.alpha.isShuttered ? 1 : 0
        rightShutter.opacity = snapshot.beta.isShuttered ? 1 : 0
        CATransaction.commit()
    }

    private func openHinge(_ open: Bool, animated: Bool) {
        var identity = CATransform3DIdentity
        identity.m34 = -1 / 800
        let angle: CGFloat = open ? .pi / 14 : 0
        let left = CATransform3DRotate(identity, -angle, 0, 1, 0)
        let right = CATransform3DRotate(identity, angle, 0, 1, 0)
        let duration: CFTimeInterval = animated ? 0.28 : 0
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        if reduceMotion {
            leftBoard.transform = CATransform3DIdentity
            rightBoard.transform = CATransform3DIdentity
            leftBoard.opacity = 1
            rightBoard.opacity = 1
        } else {
            leftBoard.transform = left
            rightBoard.transform = right
        }
        CATransaction.commit()
    }
}

/// Role: Plate. SwiftUI host for the one pugillares hinge. Not a split view. Not two TextEditors.
struct PugillaresHinge: UIViewRepresentable {
    var snapshot: DiptychSnapshot
    var alphaName: String = "North"
    var betaName: String = "South"
    var onInk: (HandSide, String) -> Void
    var onHand: (HandSide) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> PugillaresHingeView {
        let view = PugillaresHingeView()
        view.onInk = onInk
        view.onHand = onHand
        view.apply(snapshot, reduceMotion: reduceMotion, alphaName: alphaName, betaName: betaName)
        return view
    }

    func updateUIView(_ view: PugillaresHingeView, context: Context) {
        view.onInk = onInk
        view.onHand = onHand
        view.apply(snapshot, reduceMotion: reduceMotion, alphaName: alphaName, betaName: betaName)
    }
}
