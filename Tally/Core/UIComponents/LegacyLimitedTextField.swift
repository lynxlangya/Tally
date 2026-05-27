import SwiftUI
import UIKit

struct LegacyLimitedTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let maxLength: Int
    var font: UIFont = .systemFont(ofSize: 18, weight: .medium)
    var textColor: UIColor = .label
    var placeholderColor: UIColor = UIColor.secondaryLabel
    var returnKeyType: UIReturnKeyType = .done

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.returnKeyType = returnKeyType
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.font = font
        textField.textColor = textColor
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: placeholderColor,
                .font: font
            ]
        )
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font
        uiView.textColor = textColor
        uiView.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: placeholderColor,
                .font: font
            ]
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: LegacyLimitedTextField

        init(_ parent: LegacyLimitedTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ sender: UITextField) {
            let value = sender.text ?? ""
            if sender.markedTextRange != nil {
                parent.text = value
                return
            }
            if value.count <= parent.maxLength {
                parent.text = value
                return
            }
            let trimmed = String(value.prefix(parent.maxLength))
            sender.text = trimmed
            parent.text = trimmed
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}
