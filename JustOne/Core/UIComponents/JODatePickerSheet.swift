import SwiftUI
import UIKit

struct JODatePickerSheet: View {
    enum Mode {
        case year
        case yearMonth
        case yearWeek
        case yearMonthDay
    }

    let mode: Mode
    let title: String
    let years: [Int]
    @Binding var selection: Date

    @Environment(\.dismiss) private var dismiss
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int
    @State private var selectedWeek: Int

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    init(
        mode: Mode,
        years: [Int],
        selection: Binding<Date>,
        title: String = "选择时间"
    ) {
        self.mode = mode
        self.title = title
        self._selection = selection

        let calendar = Self.baseCalendar
        let date = selection.wrappedValue
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let week = calendar.component(.weekOfYear, from: date)

        let normalizedYears = Array(Set(years + [year])).sorted()
        self.years = normalizedYears.isEmpty ? [year] : normalizedYears

        _selectedYear = State(initialValue: year)
        _selectedMonth = State(initialValue: month)
        _selectedDay = State(initialValue: day)
        _selectedWeek = State(initialValue: week)
    }

    var body: some View {
        JOSheetContainer(
            cornerRadius: Layout.sheetCornerRadius,
            background: JOColors.surface.opacity(Layout.sheetBackgroundOpacity),
            borderOpacity: Layout.sheetBorderOpacity
        ) {
            VStack(spacing: 0) {
                header
                pickerBody
            }
            .padding(.top, Layout.contentTopPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(JOColors.surface.opacity(1.0))
        .compositingGroup()
        .clipped()
        .ignoresSafeArea()
        .onChange(of: selectedYear) {
            clampWeekIfNeeded()
            clampDayIfNeeded()
        }
        .onChange(of: selectedMonth) {
            clampDayIfNeeded()
        }
    }

    private var header: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .font(JOTypography.body)
            .foregroundStyle(JOColors.textSecondary)

            Spacer()

            Text(title)
                .font(JOTypography.body)
                .foregroundStyle(JOColors.textPrimary)

            Spacer()

            Button("确定") {
                applySelection()
                dismiss()
            }
            .font(JOTypography.body)
            .fontWeight(.semibold)
            .foregroundStyle(JOColors.accent)
        }
        .padding(.horizontal, Layout.headerHorizontalPadding)
        .padding(.vertical, Layout.headerVerticalPadding)
        .background(
            Divider()
                .overlay(Color.white.opacity(0.08))
                .offset(y: Layout.headerDividerOffset),
            alignment: .bottom
        )
    }

    private var pickerBody: some View {
        GeometryReader { proxy in
            let columnCount = pickerColumnCount
            let totalSpacing = Layout.columnSpacing * CGFloat(max(columnCount - 1, 0))
            let availableWidth = max(proxy.size.width - Layout.pickerHorizontalPadding * 2 - totalSpacing, 0)
            let columnWidth = columnCount > 0 ? availableWidth / CGFloat(columnCount) : 0

            ZStack {
                RoundedRectangle(cornerRadius: Layout.highlightCornerRadius, style: .continuous)
                    .fill(Layout.highlightColor)
                    .frame(height: Layout.rowHeight)
                    .padding(.horizontal, Layout.highlightHorizontalPadding)
                    .shadow(color: Layout.highlightShadowColor, radius: Layout.highlightShadowRadius, y: Layout.highlightShadowOffset)
                    .allowsHitTesting(false)

                HStack(spacing: Layout.columnSpacing) {
                    yearPicker
                        .frame(width: columnWidth, height: Layout.pickerHeight)

                    if mode == .yearMonth || mode == .yearMonthDay {
                        monthPicker
                            .frame(width: columnWidth, height: Layout.pickerHeight)
                    }

                    if mode == .yearWeek {
                        weekPicker
                            .frame(width: columnWidth, height: Layout.pickerHeight)
                    }

                    if mode == .yearMonthDay {
                        dayPicker
                            .frame(width: columnWidth, height: Layout.pickerHeight)
                    }
                }
                .frame(height: Layout.pickerHeight)
                .padding(.horizontal, Layout.pickerHorizontalPadding)

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            JOColors.surface.opacity(0.95),
                            JOColors.surface.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Layout.gradientHeight)

                    Spacer()

                    LinearGradient(
                        colors: [
                            JOColors.surface.opacity(0.0),
                            JOColors.surface.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Layout.gradientHeight)
                }
                .allowsHitTesting(false)
                .zIndex(4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: Layout.pickerHeight)
    }

    private var pickerColumnCount: Int {
        switch mode {
        case .year:
            return 1
        case .yearMonth:
            return 2
        case .yearWeek:
            return 2
        case .yearMonthDay:
            return 3
        }
    }

    private var yearPicker: some View {
        JOWheelPicker(
            items: years,
            selection: $selectedYear,
            title: { "\($0)年" },
            textColor: UIColor(JOColors.textPrimary),
            font: Layout.pickerFont,
            rowHeight: Layout.rowHeight
        )
    }

    private var monthPicker: some View {
        JOWheelPicker(
            items: Array(1...12),
            selection: $selectedMonth,
            title: { "\($0)月" },
            textColor: UIColor(JOColors.textPrimary),
            font: Layout.pickerFont,
            rowHeight: Layout.rowHeight
        )
    }

    private var weekPicker: some View {
        JOWheelPicker(
            items: weekValues,
            selection: $selectedWeek,
            title: { "第 \($0) 周" },
            textColor: UIColor(JOColors.textPrimary),
            font: Layout.pickerFont,
            rowHeight: Layout.rowHeight
        )
    }

    private var dayPicker: some View {
        JOWheelPicker(
            items: dayValues,
            selection: $selectedDay,
            title: { "\($0)日" },
            textColor: UIColor(JOColors.textPrimary),
            font: Layout.pickerFont,
            rowHeight: Layout.rowHeight
        )
    }

    private var weekValues: [Int] {
        guard let date = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)),
              let range = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: date) else {
            return Array(1...52)
        }
        return Array(range)
    }

    private var dayValues: [Int] {
        guard let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return [1]
        }
        return Array(range)
    }

    private func clampDayIfNeeded() {
        guard mode == .yearMonthDay else { return }
        let days = dayValues
        if let last = days.last, selectedDay > last {
            selectedDay = last
        }
        if let first = days.first, selectedDay < first {
            selectedDay = first
        }
    }

    private func clampWeekIfNeeded() {
        guard mode == .yearWeek else { return }
        let weeks = weekValues
        if let last = weeks.last, selectedWeek > last {
            selectedWeek = last
        }
        if let first = weeks.first, selectedWeek < first {
            selectedWeek = first
        }
    }

    private func applySelection() {
        let selectedDate: Date?
        switch mode {
        case .year:
            selectedDate = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))
        case .yearMonth:
            selectedDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))
        case .yearWeek:
            selectedDate = calendar.date(from: DateComponents(
                weekday: calendar.firstWeekday,
                weekOfYear: selectedWeek,
                yearForWeekOfYear: selectedYear
            ))
        case .yearMonthDay:
            selectedDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay))
        }

        if let selectedDate {
            selection = selectedDate
        }
    }

    private enum Layout {
        static let sheetCornerRadius: CGFloat = 24
        static let sheetBackgroundOpacity: Double = 0.9
        static let sheetBorderOpacity: Double = 0.06
        static let contentTopPadding: CGFloat = 8
        static let sheetBottomPadding: CGFloat = 0
        static let headerHorizontalPadding: CGFloat = 16
        static let headerVerticalPadding: CGFloat = 12
        static let headerDividerOffset: CGFloat = 12
        static let pickerHeight: CGFloat = 184
        static let rowHeight: CGFloat = 46
        static let highlightHorizontalPadding: CGFloat = 12
        static let highlightCornerRadius: CGFloat = 14
        static let highlightColor: Color = JOColors.accent.opacity(0.08)
        static let highlightShadowColor: Color = JOColors.accent.opacity(0.12)
        static let highlightShadowRadius: CGFloat = 6
        static let highlightShadowOffset: CGFloat = 2
        static let columnSpacing: CGFloat = 4
        static let pickerHorizontalPadding: CGFloat = 12
        static let gradientHeight: CGFloat = 38
        static let pickerFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let debugOverlayEnabled = false
    }

    private static let baseCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()
}
