import Cocoa
import FlutterMacOS

/// macOS 菜单栏快速记录入口。
/// 点击菜单栏图标或按 ⌃⌘K 弹出 Popover，用户输入后按 Return 提交。
/// 解析和保存通过 FlutterMethodChannel 双向通信完成，确认 UI 在 Popover 内完成。
class QuickCaptureStatusItem: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private weak var viewController: QuickCaptureViewController?

    /// 用于与 Flutter 通信的 MethodChannel。
    var channel: FlutterMethodChannel?

    /// 初始化状态栏图标、Popover 和全局热键。
    func setup() {
        // 状态栏图标
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "pencil.circle", accessibilityDescription: "快速记录")
            } else {
                button.title = "⌘"
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        statusItem = item

        // Popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 64)
        popover.behavior = .transient
        let vc = QuickCaptureViewController()
        vc.delegate = self
        viewController = vc
        popover.contentViewController = vc
        self.popover = popover

        // 全局热键 ⌃⌘K
        registerHotkey()
    }

    // MARK: - Toggle

    @objc private func togglePopover(_ sender: Any?) {
        if popover?.isShown == true {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem?.button else { return }
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApplication.shared.activate(ignoringOtherApps: true)
        viewController?.resetToInput()
    }

    func closePopover() {
        popover?.performClose(nil)
    }

    // MARK: - 全局热键

    private func registerHotkey() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.control, .command], event.charactersIgnoringModifiers == "k" {
                DispatchQueue.main.async {
                    self?.showPopover()
                }
            }
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// MARK: - QuickCaptureViewController Delegate

extension QuickCaptureStatusItem: QuickCaptureViewControllerDelegate {
    func quickCaptureDidSubmit(_ text: String) {
        viewController?.showLoading()
        channel?.invokeMethod("parse", arguments: text) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let dict = result as? [String: Any] else {
                    // 解析失败 → 直接保存为 knowledge note
                    self.saveDirectly(text)
                    return
                }

                let hasContact = dict["hasContact"] as? Bool ?? false
                let hasEvent = dict["hasEvent"] as? Bool ?? false

                if !hasContact && !hasEvent {
                    // 没有识别到任何实体 → 直接保存并显示成功
                    self.saveDirectly(text)
                } else {
                    // 有识别结果 → 显示确认 UI
                    self.viewController?.showConfirm(text: text, parseResult: dict)
                    // 调整 popover 大小
                    let height = self.viewController?.preferredContentHeight ?? 200
                    self.popover?.contentSize = NSSize(width: 340, height: height)
                }
            }
        }
    }

    func quickCaptureDidConfirm(_ saveArgs: [String: Any]) {
        viewController?.showLoading()
        channel?.invokeMethod("save", arguments: saveArgs) { [weak self] _ in
            DispatchQueue.main.async {
                self?.viewController?.showSuccess()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self?.closePopover()
                    self?.popover?.contentSize = NSSize(width: 340, height: 64)
                }
            }
        }
    }

    func quickCaptureDidCancel() {
        closePopover()
        popover?.contentSize = NSSize(width: 340, height: 64)
    }

    private func saveDirectly(_ text: String) {
        let args: [String: Any] = [
            "text": text,
            "contactAction": "skip",
            "eventAction": "skip",
        ]
        channel?.invokeMethod("save", arguments: args) { [weak self] _ in
            DispatchQueue.main.async {
                self?.viewController?.showSuccess()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self?.closePopover()
                    self?.popover?.contentSize = NSSize(width: 340, height: 64)
                }
            }
        }
    }
}

// MARK: - Delegate protocol

protocol QuickCaptureViewControllerDelegate: AnyObject {
    func quickCaptureDidSubmit(_ text: String)
    func quickCaptureDidConfirm(_ saveArgs: [String: Any])
    func quickCaptureDidCancel()
}

// MARK: - Multi-state ViewController

class QuickCaptureViewController: NSViewController {
    weak var delegate: QuickCaptureViewControllerDelegate?

    private var containerView: NSView!
    private var textField: NSTextField!

    // 确认态 UI
    private var confirmStack: NSStackView?
    private var contactSection: NSView?
    private var eventSection: NSView?
    private var buttonBar: NSView?

    // 加载/成功态
    private var statusLabel: NSTextField?

    // 当前状态数据
    private var currentText: String = ""
    private var currentParseResult: [String: Any] = [:]

    // 联系人选择态
    private var contactAction: String = "skip"
    private var selectedContactId: String?
    private var newContactName: String?

    // 事件选择态
    private var eventAction: String = "skip"
    private var selectedEventId: String?
    private var eventTitleField: NSTextField?

    var preferredContentHeight: CGFloat {
        let hasContact = currentParseResult["hasContact"] as? Bool ?? false
        let hasEvent = currentParseResult["hasEvent"] as? Bool ?? false
        let existingEvents = currentParseResult["existingEvents"] as? [[String: Any]]
        var height: CGFloat = 60 // top padding + button bar
        if hasContact { height += 70 }
        if hasEvent { height += 80 + CGFloat((existingEvents?.count ?? 0)) * 28 }
        return max(height, 120)
    }

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 64))
        containerView = container

        let field = NSTextField(frame: NSRect(x: 12, y: 20, width: 316, height: 24))
        field.placeholderString = "记录…（按 Return 保存）"
        field.delegate = self
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.focusRingType = .exterior
        container.addSubview(field)
        textField = field

        view = container
    }

    func resetToInput() {
        clearConfirmUI()
        textField.isHidden = false
        textField.stringValue = ""
        textField.isEditable = true
        statusLabel?.removeFromSuperview()
        statusLabel = nil
        view.window?.makeFirstResponder(textField)
    }

    // MARK: - States

    func showLoading() {
        textField.isHidden = true
        clearConfirmUI()
        showStatusText("正在处理…")
    }

    func showSuccess() {
        clearConfirmUI()
        textField.isHidden = true
        showStatusText("✓ 已保存")
        statusLabel?.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel?.textColor = NSColor.systemGreen
    }

    func showConfirm(text: String, parseResult: [String: Any]) {
        currentText = text
        currentParseResult = parseResult
        textField.isHidden = true
        statusLabel?.removeFromSuperview()
        statusLabel = nil
        clearConfirmUI()

        // 重置选择状态
        contactAction = "skip"
        selectedContactId = nil
        newContactName = nil
        eventAction = "skip"
        selectedEventId = nil

        let hasContact = parseResult["hasContact"] as? Bool ?? false
        let hasEvent = parseResult["hasEvent"] as? Bool ?? false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
        ])
        confirmStack = stack

        if hasContact {
            let section = buildContactSection(parseResult)
            stack.addArrangedSubview(section)
            contactSection = section
        }

        if hasEvent {
            let section = buildEventSection(parseResult)
            stack.addArrangedSubview(section)
            eventSection = section
        }

        // 按钮栏
        let bar = buildButtonBar()
        stack.addArrangedSubview(bar)
        buttonBar = bar
    }

    // MARK: - Contact section

    private func buildContactSection(_ result: [String: Any]) -> NSView {
        let box = NSView()
        box.translatesAutoresizingMaskIntoConstraints = false

        let contactType = result["contactType"] as? String ?? ""
        let contactName = result["contactName"] as? String ?? ""
        let contactId = result["contactId"] as? String

        let label = NSTextField(labelWithString: "👤 识别到联系人：\(contactName)")
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)

        let btnStack = NSStackView()
        btnStack.orientation = .horizontal
        btnStack.spacing = 6
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(btnStack)

        if contactType == "matched", let cid = contactId {
            let linkBtn = makeSmallButton("关联")
            linkBtn.target = self
            linkBtn.tag = 1
            linkBtn.action = #selector(contactLinkTapped(_:))
            btnStack.addArrangedSubview(linkBtn)

            // 保存 contactId 供操作使用
            selectedContactId = cid
            contactAction = "link"  // 默认选中关联
            linkBtn.state = .on
        }

        let createBtn = makeSmallButton("新建联系人")
        createBtn.target = self
        createBtn.tag = 2
        createBtn.action = #selector(contactCreateTapped(_:))
        btnStack.addArrangedSubview(createBtn)

        let skipBtn = makeSmallButton("跳过")
        skipBtn.target = self
        skipBtn.tag = 3
        skipBtn.action = #selector(contactSkipTapped(_:))
        btnStack.addArrangedSubview(skipBtn)

        if contactType == "candidate" {
            contactAction = "create"
            newContactName = contactName
            createBtn.state = .on
        }

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: box.topAnchor),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            btnStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            btnStack.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            btnStack.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            box.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
        ])

        return box
    }

    @objc private func contactLinkTapped(_ sender: NSButton) {
        contactAction = "link"
        newContactName = nil
        highlightButtonInSiblings(sender)
    }

    @objc private func contactCreateTapped(_ sender: NSButton) {
        contactAction = "create"
        let contactName = currentParseResult["contactName"] as? String ?? ""
        newContactName = contactName
        selectedContactId = nil
        highlightButtonInSiblings(sender)
    }

    @objc private func contactSkipTapped(_ sender: NSButton) {
        contactAction = "skip"
        selectedContactId = nil
        newContactName = nil
        highlightButtonInSiblings(sender)
    }

    // MARK: - Event section

    private func buildEventSection(_ result: [String: Any]) -> NSView {
        let box = NSView()
        box.translatesAutoresizingMaskIntoConstraints = false

        let eventTitle = result["eventTitle"] as? String ?? ""
        let eventDate = result["eventDate"] as? String ?? ""
        let existingEvents = result["existingEvents"] as? [[String: Any]] ?? []

        let dateLabel = formatDateLabel(eventDate)
        let label = NSTextField(labelWithString: "📅 识别到时间：\(dateLabel)")
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)

        // 事件标题输入
        let titleField = NSTextField(frame: .zero)
        titleField.stringValue = eventTitle
        titleField.placeholderString = "事件标题"
        titleField.font = NSFont.systemFont(ofSize: 12)
        titleField.isBezeled = true
        titleField.bezelStyle = .roundedBezel
        titleField.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(titleField)
        eventTitleField = titleField

        var lastView: NSView = titleField

        // 已有事件按钮
        var eventBtnViews: [NSView] = []
        for (index, event) in existingEvents.enumerated() {
            let eTitle = event["title"] as? String ?? "未命名事件"
            let eId = event["id"] as? String ?? ""
            let btn = makeSmallButton("🔗 \(eTitle)")
            btn.target = self
            btn.tag = 100 + index
            btn.action = #selector(eventLinkTapped(_:))
            btn.toolTip = eId
            btn.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(btn)
            eventBtnViews.append(btn)
        }

        // 按钮栏
        let btnStack = NSStackView()
        btnStack.orientation = .horizontal
        btnStack.spacing = 6
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(btnStack)

        let createBtn = makeSmallButton("创建事件")
        createBtn.target = self
        createBtn.tag = 10
        createBtn.action = #selector(eventCreateTapped(_:))
        btnStack.addArrangedSubview(createBtn)

        let skipBtn = makeSmallButton("跳过")
        skipBtn.target = self
        skipBtn.tag = 11
        skipBtn.action = #selector(eventSkipTapped(_:))
        btnStack.addArrangedSubview(skipBtn)

        // 默认选中创建
        eventAction = "create"
        createBtn.state = .on

        // 布局
        var constraints = [
            label.topAnchor.constraint(equalTo: box.topAnchor),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            titleField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            titleField.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            titleField.heightAnchor.constraint(equalToConstant: 22),
            box.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
        ]

        lastView = titleField
        for btn in eventBtnViews {
            constraints.append(btn.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 4))
            constraints.append(btn.leadingAnchor.constraint(equalTo: box.leadingAnchor))
            lastView = btn
        }

        constraints.append(btnStack.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 4))
        constraints.append(btnStack.leadingAnchor.constraint(equalTo: box.leadingAnchor))
        constraints.append(btnStack.bottomAnchor.constraint(equalTo: box.bottomAnchor))

        NSLayoutConstraint.activate(constraints)
        return box
    }

    @objc private func eventLinkTapped(_ sender: NSButton) {
        eventAction = "link"
        selectedEventId = sender.toolTip
        // 不需要 highlightButtonInSiblings 因为这些单独布局
    }

    @objc private func eventCreateTapped(_ sender: NSButton) {
        eventAction = "create"
        selectedEventId = nil
    }

    @objc private func eventSkipTapped(_ sender: NSButton) {
        eventAction = "skip"
        selectedEventId = nil
    }

    // MARK: - Button bar

    private func buildButtonBar() -> NSView {
        let bar = NSStackView()
        bar.orientation = .horizontal
        bar.spacing = 8
        bar.translatesAutoresizingMaskIntoConstraints = false

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        bar.addArrangedSubview(spacer)

        let cancelBtn = NSButton(title: "取消", target: self, action: #selector(cancelTapped))
        cancelBtn.bezelStyle = .rounded
        cancelBtn.font = NSFont.systemFont(ofSize: 12)
        bar.addArrangedSubview(cancelBtn)

        let confirmBtn = NSButton(title: "确认", target: self, action: #selector(confirmTapped))
        confirmBtn.bezelStyle = .rounded
        confirmBtn.font = NSFont.systemFont(ofSize: 12)
        confirmBtn.keyEquivalent = "\r"
        if #available(macOS 10.14, *) {
            confirmBtn.contentTintColor = .white
        }
        bar.addArrangedSubview(confirmBtn)

        return bar
    }

    @objc private func cancelTapped() {
        delegate?.quickCaptureDidCancel()
    }

    @objc private func confirmTapped() {
        var args: [String: Any] = [
            "text": currentText,
            "contactAction": contactAction,
            "eventAction": eventAction,
        ]

        if contactAction == "link", let cid = selectedContactId {
            args["contactId"] = cid
        } else if contactAction == "create" {
            args["newContactName"] = newContactName ?? (currentParseResult["contactName"] as? String ?? "")
        }

        if eventAction == "link", let eid = selectedEventId {
            args["eventId"] = eid
        } else if eventAction == "create" {
            args["newEventTitle"] = eventTitleField?.stringValue ?? ""
            args["eventDate"] = currentParseResult["eventDate"] ?? ""
        }

        delegate?.quickCaptureDidConfirm(args)
    }

    // MARK: - Helpers

    private func showStatusText(_ text: String) {
        statusLabel?.removeFromSuperview()
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
        statusLabel = label
    }

    private func clearConfirmUI() {
        confirmStack?.removeFromSuperview()
        confirmStack = nil
        contactSection = nil
        eventSection = nil
        buttonBar = nil
        eventTitleField = nil
    }

    private func makeSmallButton(_ title: String) -> NSButton {
        let btn = NSButton(title: title, target: nil, action: nil)
        btn.bezelStyle = .rounded
        btn.font = NSFont.systemFont(ofSize: 11)
        btn.setButtonType(.pushOnPushOff)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private func highlightButtonInSiblings(_ sender: NSButton) {
        guard let parent = sender.superview as? NSStackView else { return }
        for case let btn as NSButton in parent.arrangedSubviews {
            btn.state = (btn === sender) ? .on : .off
        }
    }

    private func formatDateLabel(_ isoDate: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: isoDate)
                ?? dateFromFlexibleISO(isoDate) else {
            return isoDate
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        let dayLabel: String
        switch diff {
        case 0: dayLabel = "今天"
        case 1: dayLabel = "明天"
        case 2: dayLabel = "后天"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            dayLabel = formatter.string(from: date)
        }

        let hour = calendar.component(.hour, from: date)
        if hour > 0 {
            let timeOfDay: String
            switch hour {
            case 5..<12: timeOfDay = "上午"
            case 12..<14: timeOfDay = "中午"
            case 14..<18: timeOfDay = "下午"
            default: timeOfDay = "晚上"
            }
            return "\(dayLabel)\(timeOfDay)"
        }
        return dayLabel
    }

    private func dateFromFlexibleISO(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter.date(from: str)
    }
}

// MARK: - NSTextFieldDelegate (input state)

extension QuickCaptureViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            let text = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                delegate?.quickCaptureDidSubmit(text)
            }
            return true
        }
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            delegate?.quickCaptureDidCancel()
            return true
        }
        return false
    }
}
