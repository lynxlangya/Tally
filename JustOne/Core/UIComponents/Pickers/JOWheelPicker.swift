import SwiftUI
import UIKit

struct JOWheelPicker: UIViewRepresentable {
    var items: [Int]
    @Binding var selection: Int
    var title: (Int) -> String
    var textColor: UIColor
    var font: UIFont
    var rowHeight: CGFloat

    func makeUIView(context: Context) -> UIPickerView {
        let pickerView = UIPickerView()
        pickerView.backgroundColor = .clear
        pickerView.isOpaque = false
        pickerView.delegate = context.coordinator
        pickerView.dataSource = context.coordinator
        return pickerView
    }

    func updateUIView(_ pickerView: UIPickerView, context: Context) {
        context.coordinator.update(self)
        context.coordinator.clearBackgrounds(in: pickerView)
        syncSelection(in: pickerView)
        pickerView.reloadAllComponents()
        context.coordinator.hideSeparators(in: pickerView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func syncSelection(in pickerView: UIPickerView) {
        guard !items.isEmpty else { return }
        if let index = items.firstIndex(of: selection) {
            if pickerView.selectedRow(inComponent: 0) != index {
                pickerView.selectRow(index, inComponent: 0, animated: false)
            }
        } else {
            let fallback = items[0]
            DispatchQueue.main.async {
                selection = fallback
            }
            pickerView.selectRow(0, inComponent: 0, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        private var parent: JOWheelPicker

        init(_ parent: JOWheelPicker) {
            self.parent = parent
        }

        func update(_ parent: JOWheelPicker) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            parent.items.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            parent.rowHeight
        }

        func pickerView(
            _ pickerView: UIPickerView,
            attributedTitleForRow row: Int,
            forComponent component: Int
        ) -> NSAttributedString? {
            guard parent.items.indices.contains(row) else { return nil }
            let title = parent.title(parent.items[row])
            let isSelected = row == pickerView.selectedRow(inComponent: component)
            let alpha: CGFloat = isSelected ? 1.0 : 0.4
            let weight: UIFont.Weight = isSelected ? .semibold : .regular
            let font = UIFont.systemFont(ofSize: parent.font.pointSize, weight: weight)
            let resolved = parent.textColor.resolvedColor(with: pickerView.traitCollection)
            let color = resolved.withAlphaComponent(alpha)

            return NSAttributedString(
                string: title,
                attributes: [
                    .font: font,
                    .foregroundColor: color
                ]
            )
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            guard parent.items.indices.contains(row) else { return }
            let value = parent.items[row]
            if parent.selection != value {
                parent.selection = value
            }
            pickerView.reloadAllComponents()
        }

        func clearBackgrounds(in pickerView: UIPickerView) {
            pickerView.backgroundColor = .clear
            pickerView.isOpaque = false
            clearSubviews(of: pickerView)
        }

        private func clearSubviews(of view: UIView) {
            view.subviews.forEach { subview in
                subview.backgroundColor = .clear
                subview.isOpaque = false
                clearSubviews(of: subview)
            }
        }

        func hideSeparators(in pickerView: UIPickerView) {
            for subview in pickerView.subviews where subview.bounds.height <= 1.0 {
                subview.isHidden = true
                subview.backgroundColor = .clear
                subview.alpha = 0
            }
        }
    }
}
