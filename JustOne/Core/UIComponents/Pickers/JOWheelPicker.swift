import SwiftUI
import UIKit

struct JOWheelPicker: UIViewRepresentable {
    var items: [Int]
    @Binding var selection: Int
    var title: (Int) -> String
    var textColor: UIColor
    var font: UIFont
    var rowHeight: CGFloat
    var debugUseSystemColors: Bool = false

    func makeUIView(context: Context) -> PickerContainer {
        let container = PickerContainer()
        let pickerView = container.pickerView
        pickerView.backgroundColor = .clear
        pickerView.isOpaque = false
        pickerView.delegate = context.coordinator
        pickerView.dataSource = context.coordinator
        return container
    }

    func updateUIView(_ container: PickerContainer, context: Context) {
        context.coordinator.update(self)
        let pickerView = container.pickerView
        pickerView.delegate = context.coordinator
        pickerView.dataSource = context.coordinator
        pickerView.backgroundColor = .clear
        pickerView.isOpaque = false
        syncSelection(in: pickerView)
        pickerView.reloadAllComponents()
        clearBackgrounds(in: pickerView)
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

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            let width = pickerView.bounds.width
            return width > 0 ? width : 1
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
            label.adjustsFontSizeToFitWidth = false
            label.minimumScaleFactor = 1.0
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
            let rawWidth = pickerView.rowSize(forComponent: component).width
            let componentWidth = rawWidth > 0 ? rawWidth : pickerView.bounds.width
            label.frame = CGRect(x: 0, y: 0, width: componentWidth, height: parent.rowHeight)
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

    private func clearBackgrounds(in pickerView: UIPickerView) {
        pickerView.backgroundColor = .clear
        pickerView.isOpaque = false
        pickerView.subviews.forEach { subview in
            subview.backgroundColor = .clear
            subview.isOpaque = false
            if let tableView = subview as? UITableView {
                tableView.backgroundColor = .clear
                tableView.isOpaque = false
                tableView.backgroundView = nil
                tableView.separatorStyle = .none
            }
            subview.subviews.forEach { child in
                child.backgroundColor = .clear
                child.isOpaque = false
            }
        }
    }
}

final class PickerContainer: UIView {
    let pickerView = UIPickerView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(pickerView)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pickerView.topAnchor.constraint(equalTo: topAnchor),
            pickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
