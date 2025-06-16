import UIKit

/// ToastView를 띄우는 객체입니다. 싱글톤으로 호출합니다.
@MainActor
final class Toast {
    static let shared = Toast()

    private init() {}
    
    /// 화면 하단에 ToastView를 띄웁니다.
    /// - Parameter message: 띄울 메세지를 받습니다.
    func showToast(message: String) {
        let scenes = UIApplication.shared.connectedScenes
        if let windowScene = scenes.first as? UIWindowScene {
            if let window = windowScene.windows.first {
                configureUI(window, message: message)
            }
        }
    }

    private func configureUI(_ window: UIWindow, message: String) {
        let toastContainer: UIView = {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.clipsToBounds = true
            v.backgroundColor = UIColor.systemGray
            v.alpha = 0.0
            v.layer.cornerRadius = 15
            return v
        }()

        let toastLabel: UILabel = {
            let l = UILabel()
            l.translatesAutoresizingMaskIntoConstraints = false
            l.textColor = UIColor.white
            l.textAlignment = .center
            l.font = UIFont.systemFont(ofSize: 14)
            l.text = message
            l.clipsToBounds = true
            return l
        }()

        toastContainer.addSubview(toastLabel)
        window.addSubview(toastContainer)

        NSLayoutConstraint.activate([
            toastContainer.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20),
            toastContainer.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20),
            toastContainer.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -40),

            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 15),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -15),
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 10),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -10)
        ])

        UIView.animate(withDuration: 0.3, animations: {
            toastContainer.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0, animations: {
                toastContainer.alpha = 0.0
            }, completion: { _ in
                toastContainer.removeFromSuperview()
            })
        })
    }
}
