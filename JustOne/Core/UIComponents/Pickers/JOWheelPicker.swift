import SwiftUI
import UIKit

struct JOWheelPicker: UIViewRepresentable {
    var items: [Int]
    @Binding var selection: Int
    var title: (Int) -> String
    var textColor: UIColor
    var font: UIFont
    var rowHeight: CGFloat
    var debugUseSystemColors: Bool = true

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
        pickerView.delegate = context.coordinator
        pickerView.dataSource = context.coordinator
        pickerView.backgroundColor = .clear
        pickerView.isOpaque = false
        syncSelection(in: pickerView)
        pickerView.reloadAllComponents()
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
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.textAlignment = .center
            label.backgroundColor = .clear
            label.isOpaque = false
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.6
            guard parent.items.indices.contains(row) else {
                label.text = nil
                return label
            }

            let isSelected = row == pickerView.selectedRow(inComponent: component)
            let weight: UIFont.Weight = isSelected ? .semibold : .regular
            label.font = UIFont.systemFont(ofSize: parent.font.pointSize, weight: weight)
            if parent.debugUseSystemColors {
                label.textColor = isSelected
                    ? UIColor.systemRed
                    : UIColor.systemYellow.withAlphaComponent(0.4)
            } else {
                let resolved = parent.textColor.resolvedColor(with: pickerView.traitCollection)
                label.textColor = resolved.withAlphaComponent(isSelected ? 1.0 : 0.4)
            }

            label.text = parent.title(parent.items[row])
            label.frame = CGRect(x: 0, y: 0, width: pickerView.bounds.width, height: parent.rowHeight)
            label.alpha = 1.0
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            guard parent.items.indices.contains(row) else { return }
            let value = parent.items[row]
            if parent.selection != value {
                parent.selection = value
            }
            pickerView.reloadAllComponents()
        }

        // 不再清理 subviews，避免误伤内部内容视图（iOS 26 结构变化）
    }
}
