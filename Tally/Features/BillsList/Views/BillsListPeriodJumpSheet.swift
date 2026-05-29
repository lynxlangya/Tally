import SwiftUI

struct BillsListPeriodJumpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tallyThemeColors) private var themeColors
    @ObservedObject var viewModel: BillsListViewModel

    @State private var selectedDate: Date
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var visibleMonth: Date
    @State private var customStart: Date
    @State private var customEnd: Date
    @State private var activeCustomBound: CustomBound = .start

    private let calendar = BillsListCalendarMetrics.calendar

    init(viewModel: BillsListViewModel) {
        self.viewModel = viewModel
        let anchor = viewModel.anchorDate
        let calendar = BillsListCalendarMetrics.calendar
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: anchor)) ?? anchor
        _selectedDate = State(initialValue: anchor)
        _selectedYear = State(initialValue: calendar.component(.year, from: anchor))
        _selectedMonth = State(initialValue: calendar.component(.month, from: anchor))
        _visibleMonth = State(initialValue: monthStart)
        _customStart = State(initialValue: viewModel.customStart)
        _customEnd = State(initialValue: viewModel.customEnd)
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(Color.tallyLine)
                .frame(width: BillsListLayout.sheetHandleWidth, height: BillsListLayout.sheetHandleHeight)
                .padding(.top, TallySpacing.s4)

            header
                .padding(.top, TallySpacing.s7)

            content
                .padding(.top, TallySpacing.s7)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, BillsListLayout.sheetHorizontalPadding)
        .padding(.bottom, TallySpacing.s6)
        .background(Color.tallySurface.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(TallyLocalization.text(.cancel, locale: LanguageManager.shared.currentLocale)) {
                dismiss()
            }
            .font(TallyType.body(18, weight: .medium))
            .foregroundStyle(Color.tallyInkDim)
            .buttonStyle(.plain)

            Spacer()

            Text(sheetTitle)
                .font(TallyType.body(18, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Button(TallyLocalization.text(.done, locale: LanguageManager.shared.currentLocale)) {
                applySelection()
                dismiss()
            }
            .font(TallyType.body(18, weight: .semibold))
            .foregroundStyle(themeColors.accent)
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.timeRange {
        case .week:
            weekPicker
        case .month:
            monthPicker
        case .year:
            yearPicker
        case .custom:
            customRangePicker
        }
    }

    private var weekPicker: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s6) {
            Text(monthHeaderText(for: visibleMonth))
                .font(TallyType.body(20, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            BillsListCalendarGrid(
                visibleMonth: visibleMonth,
                selectedDate: selectedDate,
                highlightedStart: weekRange(for: selectedDate).start,
                highlightedEnd: weekRange(for: selectedDate).end,
                latestSelectableDate: viewModel.latestSelectableDate,
                mode: .week,
                onSelect: { selectedDate = $0 }
            )

            Text(TallyLocalization.text("jump_to_week_hint", locale: LanguageManager.shared.currentLocale))
                .font(TallyType.body(14, weight: .medium))
                .foregroundStyle(Color.tallyInkFaint)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var monthPicker: some View {
        VStack(spacing: TallySpacing.s7) {
            HStack(spacing: TallySpacing.s6) {
                yearArrow(systemName: "chevron.left", enabled: canSelectYear(selectedYear - 1)) {
                    selectedYear -= 1
                    clampSelectedMonth()
                }

                Text(yearText(selectedYear))
                    .font(TallyType.display(24, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                    .frame(minWidth: 132)

                yearArrow(systemName: "chevron.right", enabled: canSelectYear(selectedYear + 1)) {
                    selectedYear += 1
                    clampSelectedMonth()
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: TallySpacing.s4), count: 4), spacing: TallySpacing.s5) {
                ForEach(1...12, id: \.self) { month in
                    let enabled = monthEnabled(year: selectedYear, month: month)
                    Button {
                        guard enabled else { return }
                        selectedMonth = month
                    } label: {
                        Text(monthText(year: selectedYear, month: month))
                            .font(TallyType.body(18, weight: .semibold))
                            .foregroundStyle(monthTextColor(month: month, enabled: enabled))
                            .frame(maxWidth: .infinity)
                            .frame(height: BillsListLayout.monthCellHeight)
                            .background(monthBackground(month: month, enabled: enabled))
                            .clipShape(RoundedRectangle(cornerRadius: BillsListLayout.monthCellRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: BillsListLayout.monthCellRadius, style: .continuous)
                                    .stroke(monthBorder(month: month, enabled: enabled), lineWidth: 0.7)
                            )
                    }
                    .disabled(!enabled)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var yearPicker: some View {
        ScrollView {
            LazyVStack(spacing: TallySpacing.s5) {
                ForEach(viewModel.availableYears, id: \.self) { year in
                    let active = year == selectedYear
                    Button {
                        selectedYear = year
                    } label: {
                        HStack {
                            Text(yearText(year))
                                .font(TallyType.display(26, weight: .semibold))
                                .foregroundStyle(active ? themeColors.accentInk : Color.tallyInk)

                            Spacer()

                            Text(TallyLocalization.text(year == currentYear ? "year_to_date" : "full_year", locale: LanguageManager.shared.currentLocale))
                                .font(TallyType.body(14, weight: .medium))
                                .foregroundStyle(active ? themeColors.accentInk.opacity(0.82) : Color.tallyInkDim)
                        }
                        .padding(.horizontal, TallySpacing.s6)
                        .frame(height: BillsListLayout.yearCellHeight)
                        .background(active ? themeColors.accent : Color.tallySurface2.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: BillsListLayout.yearCellRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: BillsListLayout.yearCellRadius, style: .continuous)
                                .stroke(active ? Color.clear : Color.tallyLine, lineWidth: 0.7)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var customRangePicker: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s6) {
            customBoundPicker

            HStack {
                Text(monthHeaderText(for: visibleMonth))
                    .font(TallyType.body(20, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)

                Spacer()

                HStack(spacing: TallySpacing.s3) {
                    monthArrow(systemName: "chevron.left") {
                        shiftVisibleMonth(by: -1)
                    }
                    monthArrow(systemName: "chevron.right") {
                        shiftVisibleMonth(by: 1)
                    }
                }
            }

            BillsListCalendarGrid(
                visibleMonth: visibleMonth,
                selectedDate: activeCustomBound == .start ? customStart : customEnd,
                highlightedStart: min(customStart, customEnd),
                highlightedEnd: max(customStart, customEnd),
                latestSelectableDate: viewModel.latestSelectableDate,
                mode: .range,
                onSelect: selectCustomDate
            )

            Text(TallyLocalization.text("custom_range_hint", locale: LanguageManager.shared.currentLocale))
                .font(TallyType.body(14, weight: .medium))
                .foregroundStyle(Color.tallyInkFaint)
        }
    }

    private var customBoundPicker: some View {
        HStack(spacing: TallySpacing.s3) {
            customBoundButton(.start, title: TallyLocalization.text("start_date", locale: LanguageManager.shared.currentLocale), date: customStart)

            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tallyInkFaint)

            customBoundButton(.end, title: TallyLocalization.text("end_date", locale: LanguageManager.shared.currentLocale), date: customEnd)
        }
    }

    private func customBoundButton(_ bound: CustomBound, title: String, date: Date) -> some View {
        let active = activeCustomBound == bound
        return Button {
            activeCustomBound = bound
            visibleMonth = monthStart(for: date)
        } label: {
            VStack(alignment: .leading, spacing: TallySpacing.s2) {
                Text(title)
                    .font(TallyType.body(14, weight: .semibold))
                    .foregroundStyle(Color.tallyInkDim)

                Text(longDateText(for: date))
                    .font(TallyType.body(16, weight: .semibold))
                    .foregroundStyle(active ? themeColors.accent : Color.tallyInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(.horizontal, TallySpacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: BillsListLayout.customBoundHeight)
            .background(active ? themeColors.accentTint : Color.tallySurface2.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: BillsListLayout.customBoundRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BillsListLayout.customBoundRadius, style: .continuous)
                    .stroke(active ? themeColors.accent : Color.tallyLine, lineWidth: active ? 1.2 : 0.7)
            )
        }
        .buttonStyle(.plain)
    }

    private var sheetTitle: String {
        switch viewModel.timeRange {
        case .week:
            return viewModel.timeRange.title
        case .month:
            return viewModel.timeRange.title
        case .year:
            return viewModel.timeRange.title
        case .custom:
            return viewModel.timeRange.title
        }
    }

    private var currentYear: Int {
        calendar.component(.year, from: viewModel.latestSelectableDate)
    }

    private var latestSelectableMonth: Int {
        calendar.component(.month, from: viewModel.latestSelectableDate)
    }

    private func applySelection() {
        switch viewModel.timeRange {
        case .week:
            viewModel.jump(to: selectedDate)
        case .month:
            clampSelectedMonth()
            let date = calendar.date(from: DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                year: selectedYear,
                month: selectedMonth,
                day: 1,
                hour: 12
            )) ?? selectedDate
            viewModel.jump(to: date)
        case .year:
            let date = calendar.date(from: DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                year: selectedYear,
                month: 1,
                day: 1,
                hour: 12
            )) ?? selectedDate
            viewModel.jump(to: date)
        case .custom:
            viewModel.updateCustomRange(start: customStart, end: customEnd)
        }
    }

    private func selectCustomDate(_ date: Date) {
        switch activeCustomBound {
        case .start:
            customStart = date
            if customStart > customEnd {
                customEnd = customStart
            }
            activeCustomBound = .end
        case .end:
            customEnd = min(date, viewModel.latestSelectableDate)
            if customEnd < customStart {
                customStart = customEnd
            }
        }
    }

    private func weekRange(for date: Date) -> (start: Date, end: Date) {
        let interval = calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, end: date)
        let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        return (interval.start, end)
    }

    private func monthStart(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func shiftVisibleMonth(by value: Int) {
        guard let next = calendar.date(byAdding: .month, value: value, to: visibleMonth) else { return }
        visibleMonth = min(next, monthStart(for: viewModel.latestSelectableDate))
    }

    private func yearArrow(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(enabled ? Color.tallyInkDim : Color.tallyInkFaint.opacity(0.42))
                .frame(width: 44, height: 44)
                .background(Color.tallySurface2.opacity(enabled ? 0.76 : 0.34))
                .clipShape(Circle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }

    private func monthArrow(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tallyInkDim)
                .frame(width: 42, height: 42)
                .background(Color.tallySurface2.opacity(0.76))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func canSelectYear(_ year: Int) -> Bool {
        year <= currentYear
    }

    private func monthEnabled(year: Int, month: Int) -> Bool {
        if year < currentYear { return true }
        if year > currentYear { return false }
        return month <= latestSelectableMonth
    }

    private func clampSelectedMonth() {
        if selectedYear >= currentYear {
            selectedYear = min(selectedYear, currentYear)
            selectedMonth = min(selectedMonth, latestSelectableMonth)
        }
    }

    private func monthBackground(month: Int, enabled: Bool) -> Color {
        guard enabled else { return .clear }
        if month == selectedMonth {
            return themeColors.accent
        }
        return Color.tallySurface2.opacity(0.58)
    }

    private func monthTextColor(month: Int, enabled: Bool) -> Color {
        guard enabled else { return Color.tallyInkFaint.opacity(0.62) }
        return month == selectedMonth ? themeColors.accentInk : Color.tallyInk
    }

    private func monthBorder(month: Int, enabled: Bool) -> Color {
        guard enabled, month != selectedMonth else { return .clear }
        return Color.tallyLine
    }

    private func monthHeaderText(for date: Date) -> String {
        TallyLocalization.monthYearTitle(for: date, locale: LanguageManager.shared.currentLocale)
    }

    private func longDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func yearText(_ year: Int) -> String {
        let date = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? viewModel.latestSelectableDate
        return TallyLocalization.yearTitle(for: date, locale: LanguageManager.shared.currentLocale)
    }

    private func monthText(year: Int, month: Int) -> String {
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? viewModel.latestSelectableDate
        return TallyLocalization.monthTitle(for: date, locale: LanguageManager.shared.currentLocale)
    }
}

private enum CustomBound {
    case start
    case end
}

private enum BillsListCalendarMode {
    case week
    case range
}

private enum BillsListCalendarMetrics {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()
}

private struct BillsListCalendarGrid: View {
    let visibleMonth: Date
    let selectedDate: Date
    let highlightedStart: Date
    let highlightedEnd: Date
    let latestSelectableDate: Date
    let mode: BillsListCalendarMode
    let onSelect: (Date) -> Void

    @Environment(\.tallyThemeColors) private var themeColors

    private let calendar = BillsListCalendarMetrics.calendar
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private var weekdays: [String] {
        let locale = LanguageManager.shared.currentLocale
        let start = DateComponents(calendar: calendar, year: 2026, month: 5, day: 4).date ?? Date()
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return TallyLocalization.weekdayTitle(for: date, locale: locale)
        }
    }

    var body: some View {
        VStack(spacing: TallySpacing.s3) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(TallyType.body(16, weight: .semibold))
                        .foregroundStyle(Color.tallyInkFaint)
                        .frame(height: 30)
                }
            }

            LazyVGrid(columns: columns, spacing: mode == .range ? TallySpacing.s2 : TallySpacing.s3) {
                ForEach(calendarDays, id: \.id) { day in
                    calendarCell(day)
                }
            }
        }
    }

    private func calendarCell(_ day: CalendarDay) -> some View {
        let disabled = !day.isCurrentMonth || day.date > latestSelectableDate
        let selected = isSameDay(day.date, selectedDate)
        let highlighted = isInHighlightedRange(day.date) && day.isCurrentMonth

        return Button {
            guard !disabled else { return }
            onSelect(day.date)
        } label: {
            ZStack {
                if highlighted {
                    Rectangle()
                        .fill(themeColors.accentTint.opacity(mode == .week ? 0.75 : 0.9))
                        .frame(height: mode == .week ? 36 : 48)
                }

                Text("\(calendar.component(.day, from: day.date))")
                    .font(TallyType.num(17, weight: selected ? .semibold : .medium))
                    .foregroundStyle(cellTextColor(disabled: disabled, selected: selected, highlighted: highlighted))
                    .frame(width: 40, height: 40)
                    .background(selected ? themeColors.accent : Color.clear)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(selected ? Color.clear : (isSameDay(day.date, latestSelectableDate) ? Color.tallyLine : Color.clear), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }

    private var calendarDays: [CalendarDay] {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth)) ?? visibleMonth
        let monthRange = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<2
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let totalCells = Int(ceil(Double(leading + monthRange.count) / 7.0)) * 7
        let start = calendar.date(byAdding: .day, value: -leading, to: monthStart) ?? monthStart
        let currentMonth = calendar.component(.month, from: monthStart)

        return (0..<totalCells).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return CalendarDay(date: date, isCurrentMonth: calendar.component(.month, from: date) == currentMonth)
        }
    }

    private func isInHighlightedRange(_ date: Date) -> Bool {
        let lower = min(highlightedStart, highlightedEnd)
        let upper = max(highlightedStart, highlightedEnd)
        return date >= lower && date <= upper
    }

    private func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    private func cellTextColor(disabled: Bool, selected: Bool, highlighted: Bool) -> Color {
        if selected { return themeColors.accentInk }
        if disabled { return Color.tallyInkFaint.opacity(0.58) }
        if highlighted { return themeColors.accent }
        return Color.tallyInk
    }
}

private struct CalendarDay: Identifiable {
    let date: Date
    let isCurrentMonth: Bool

    var id: TimeInterval {
        date.timeIntervalSinceReferenceDate
    }
}
