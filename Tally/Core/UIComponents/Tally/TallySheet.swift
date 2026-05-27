import SwiftUI

private struct TallySheetContent<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(Color.tallyLineHi)
                .frame(width: 36, height: 4)
                .padding(.top, TallySpacing.s2)
                .padding(.bottom, TallySpacing.s2)

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.tallySurface)
    }
}

extension View {
    func tallySheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        heightFraction: CGFloat = 0.88,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item) { value in
            TallySheetContent {
                content(value)
            }
            .presentationDetents([.fraction(heightFraction)])
            .presentationCornerRadius(TallyRadii.xxl)
            .presentationBackground(Color.tallySurface)
            .presentationDragIndicator(.hidden)
        }
    }

    func tallySheet<Content: View>(
        isPresented: Binding<Bool>,
        heightFraction: CGFloat = 0.88,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented) {
            TallySheetContent {
                content()
            }
            .presentationDetents([.fraction(heightFraction)])
            .presentationCornerRadius(TallyRadii.xxl)
            .presentationBackground(Color.tallySurface)
            .presentationDragIndicator(.hidden)
        }
    }
}

#Preview("TallySheet Light") {
    TallySheetPreview()
        .preferredColorScheme(.light)
}

#Preview("TallySheet Dark") {
    TallySheetPreview()
        .preferredColorScheme(.dark)
}

private struct TallySheetPreview: View {
    @State private var presented = false

    var body: some View {
        Button("保存") {
            presented = true
        }
        .font(TallyType.body(17, weight: .semibold))
        .foregroundStyle(Color.tallyAccentInk)
        .padding(.horizontal, TallySpacing.s6)
        .padding(.vertical, TallySpacing.s4)
        .background(Color.tallyAccent)
        .clipShape(Capsule(style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tallyBg)
        .tallySheet(isPresented: $presented, heightFraction: 0.5) {
            VStack(spacing: TallySpacing.s4) {
                Eyebrow("sheet")
                Text("一根刻痕，一笔账。")
                    .font(TallyType.display(24, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                Button("关闭") {
                    presented = false
                }
                .font(TallyType.body(15, weight: .semibold))
                .foregroundStyle(Color.tallyAccent)
            }
            .padding(TallySpacing.s6)
        }
    }
}
