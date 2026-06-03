import CoreGraphics

enum QuickEntryLayout {
    static let sheetDetent: CGFloat = 0.92
    static let categoryPickerDetent: CGFloat = 0.78
    static let sheetCornerRadius: CGFloat = 32

    static let headerHorizontalPadding: CGFloat = 20
    static let contentHorizontalPadding: CGFloat = 24
    static let keypadHorizontalPadding: CGFloat = 16

    static let categoryGridColumns: Int = 4
    static let categoryGridSpacingX: CGFloat = 8
    static let categoryGridSpacingY: CGFloat = 20
    static let pickerTileSize: CGFloat = 52

    static let keypadKeyHeight: CGFloat = 56
    static let keypadCornerRadius: CGFloat = 14
    static let keypadSpacing: CGFloat = 6
    static let keypadFontSize: CGFloat = 22

    static let confirmButtonVerticalPadding: CGFloat = 18
    static let confirmButtonCornerRadius: CGFloat = 24
    static let noteLimit: Int = 6
    static let datePickerSheetHeight: CGFloat = 248

    // 键盘上方的横向快捷分类行
    static let suggestionRowTileSize: CGFloat = 44
    static let suggestionRowSpacing: CGFloat = 14
    static let suggestionRowLimit: Int = 6
    static let suggestionRowVerticalPadding: CGFloat = 10
    static let suggestionRowHorizontalPadding: CGFloat = 20
    static let suggestionCaptionHeight: CGFloat = 18
    static let suggestionEdgeFadeWidth: CGFloat = 24
    // 选中描边环向外扩 inset；stroke 居中对齐，最外缘 = inset + lineWidth/2 ≈ 3.75。
    // clearance 是 item 为容纳环预留的内边距，须 ≥ 最外缘，否则环顶被 ScrollView/mask 裁掉。
    static let suggestionSelectionRingInset: CGFloat = 3
    static let suggestionSelectionRingClearance: CGFloat = 5

    // 全量 picker 的「常用 / 全部」分区
    static let pickerSectionSpacing: CGFloat = 18
    static let pickerSectionHeaderBottomPadding: CGFloat = 10
}
