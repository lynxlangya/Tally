import CoreGraphics

enum QuickEntryLayout {
    static let categoryDetent: CGFloat = 0.66
    static let amountDetent: CGFloat = 0.84
    static let sheetCornerRadius: CGFloat = 32
    static let sheetBorderOpacity: CGFloat = 0.06
    static let sheetBackgroundOpacity: CGFloat = 0.45
    static let handleWidth: CGFloat = 40
    static let handleHeight: CGFloat = 6

    static let headerHorizontalPadding: CGFloat = 24
    static let headerVerticalPadding: CGFloat = 16

    static let categoryIconSize: CGFloat = 56
    static let categoryGridColumns: Int = 4
    static let categoryGridSpacingX: CGFloat = 8
    static let categoryGridSpacingY: CGFloat = 24

    static let amountIconSize: CGFloat = 80
    static let amountNoteHeight: CGFloat = 44

    static let keypadKeyHeight: CGFloat = 64
    static let keypadCornerRadius: CGFloat = 16
    static let keypadSpacing: CGFloat = 12
    static let keypadFontSize: CGFloat = 22
    static let keypadSectionPadding: CGFloat = 12

    static let confirmButtonHeight: CGFloat = 56
    static let noteLimit: Int = 6
    static let noteWidthRatio: CGFloat = 0.5
    static let datePickerDetent: CGFloat = 0.45
}
