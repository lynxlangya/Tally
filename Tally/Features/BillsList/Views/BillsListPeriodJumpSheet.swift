import SwiftUI

struct BillsListPeriodJumpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tallyThemeColors) private var themeColors
    @ObservedObject var viewModel: BillsListViewModel

    @State private var selectedDate: Date
    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    init(viewModel: BillsListViewModel) {
        self.viewModel = viewModel
        let anchor = viewModel.anchorDate
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        _selectedDate = State(initialValue: anchor)
        _selectedYear = State(initialValue: calendar.component(.year, from: anchor))
        _selectedMonth = State(initialValue: calendar.component(.month, from: anchor))
    }

    var body: some View {
        VStack(spacing: TallySpacing.s5) {
            header

            switch viewModel.timeRange {
            case .week:
                weekPicker
            case .month:
                monthPicker
            case .year:
                yearPicker
            case .custom:
                Text("自定义区间下一阶段启用")
                    .font(TallyType.body(14, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .frame(maxWidth: .infinity, minHeight: 180)
            }
        }
        .padding(.horizontal, TallySpacing.s5)
        .padding(.bottom, TallySpacing.s5)
        .background(Color.tallySurface.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Text("快速跳转")
                .font(TallyType.body(17, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Button("完成") {
                applySelection()
                dismiss()
            }
            .font(TallyType.body(14, weight: .semibold))
            .foregroundStyle(themeColors.accent)
            .buttonStyle(.plain)
        }
    }

    private var weekPicker: some View {
        DatePicker("选择周内日期", selection: $selectedDate, displayedComponents: [.date])
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(themeColors.accent)
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .clipped()
    }

    private var monthPicker: some View {
        HStack(spacing: TallySpacing.s3) {
            Picker("年份", selection: $selectedYear) {
                ForEach(monthYears, id: \.self) { year in
                    Text("\(year)年").tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("月份", selection: $selectedMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text("\(month)月").tag(month)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 190)
        .clipped()
    }

    private var yearPicker: some View {
        ScrollView {
            LazyVStack(spacing: TallySpacing.s2) {
                ForEach(viewModel.availableYears, id: \.self) { year in
                    Button {
                        selectedYear = year
                        applySelection()
                        dismiss()
                    } label: {
                        HStack {
                            Text("\(year)年")
                                .font(TallyType.body(15, weight: .medium))
                                .foregroundStyle(Color.tallyInk)
                            Spacer()
                            if year == selectedYear {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(themeColors.accent)
                            }
                        }
                        .padding(.horizontal, TallySpacing.s4)
                        .frame(height: 42)
                        .background(year == selectedYear ? themeColors.accentTint : Color.tallySurface2.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.sm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 206)
        .scrollIndicators(.hidden)
    }

    private var monthYears: [Int] {
        Array(Set(viewModel.availableYears + [selectedYear])).sorted()
    }

    private func applySelection() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent

        switch viewModel.timeRange {
        case .week:
            viewModel.jump(to: selectedDate)
        case .month:
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
            break
        }
    }
}
