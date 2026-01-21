import UIKit
import Social
import UniformTypeIdentifiers

/// Share Extension for capturing text from other apps (Notes, Safari, etc.) into Cove
class ShareViewController: UIViewController {

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Send to Cove"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send to Cove", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.10, green: 0.21, blue: 0.36, alpha: 1.0) // DeepOcean
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedContent()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(textView)
        containerView.addSubview(cancelButton)
        containerView.addSubview(sendButton)
        containerView.addSubview(activityIndicator)

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            containerView.heightAnchor.constraint(equalToConstant: 320),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 150),

            cancelButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),

            sendButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            sendButton.widthAnchor.constraint(equalToConstant: 140),
            sendButton.heightAnchor.constraint(equalToConstant: 44),

            activityIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
        ])
    }

    // MARK: - Content Extraction

    private func extractSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            return
        }

        for provider in itemProviders {
            // Try plain text first
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, error in
                    if let text = item as? String {
                        DispatchQueue.main.async {
                            self?.textView.text = text
                        }
                    }
                }
                return
            }

            // Try URL (for web pages)
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, error in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            self?.textView.text = url.absoluteString
                        }
                    }
                }
                return
            }
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    @objc private func sendTapped() {
        guard let text = textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Please enter some text to send.")
            return
        }

        sendButton.isEnabled = false
        sendButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()

        // Save to App Group shared container for main app to pick up
        saveToSharedContainer(text: text)

        // Show success and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.showSuccess()
        }
    }

    private func saveToSharedContainer(text: String) {
        // Use App Group to share data between extension and main app
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.cove.app") else {
            return
        }

        // Get existing pending items or create new array
        var pendingItems = sharedDefaults.array(forKey: "pendingCapturedInputs") as? [[String: Any]] ?? []

        // Add new item
        let newItem: [String: Any] = [
            "id": UUID().uuidString,
            "text": text,
            "timestamp": Date().timeIntervalSince1970,
            "source": "share_extension"
        ]
        pendingItems.append(newItem)

        // Save back
        sharedDefaults.set(pendingItems, forKey: "pendingCapturedInputs")
        sharedDefaults.synchronize()
    }

    private func showSuccess() {
        let successLabel = UILabel()
        successLabel.text = "✓ Sent to Cove"
        successLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        successLabel.textColor = UIColor(red: 0.28, green: 0.73, blue: 0.47, alpha: 1.0) // ZenGreen
        successLabel.textAlignment = .center
        successLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(successLabel)
        NSLayoutConstraint.activate([
            successLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            successLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])

        textView.isHidden = true
        titleLabel.isHidden = true
        cancelButton.isHidden = true
        sendButton.isHidden = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
