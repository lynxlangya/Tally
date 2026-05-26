import SwiftUI
import UIKit

struct NavigationPopEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        NavigationPopEnablerController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? NavigationPopEnablerController)?.enableInteractivePop()
    }
}

private final class NavigationPopEnablerController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableInteractivePop()
    }

    func enableInteractivePop() {
        guard let navigationController else { return }
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = nil
    }
}

extension View {
    func enableInteractivePop() -> some View {
        background(NavigationPopEnabler())
    }
}
