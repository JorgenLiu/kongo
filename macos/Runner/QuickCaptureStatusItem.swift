import Cocoa
import FlutterMacOS
import NaturalLanguage

/// macOS 菜单栏快速记录入口。
/// 点击菜单栏图标或按 ⌃⌘K 弹出 Popover，用户输入后按 Return 提交。
/// 解析和保存通过 FlutterMethodChannel 双向通信完成，确认 UI 在 Popover 内完成。
class QuickCaptureStatusItem: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private weak var viewController: QuickCaptureViewController?
    // In-memory queue of pending parse items. Each item is a dict: ["text": String, "parseResult": [String: Any]]
    private var pendingQueue: [[String: Any]] = []
    private var isProcessingQueue: Bool = false
    /// The entry currently shown in the confirm UI (removed from queue but not yet confirmed/cancelled).
    private var currentProcessingItem: [String: Any]?
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
        popover?.contentSize = NSSize(width: 340, height: 80)
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApplication.shared.activate(ignoringOtherApps: true)
        // If we were mid-confirm when popover was dismissed, restore that state.
        if let item = currentProcessingItem {
            let text = item["text"] as? String ?? ""
            let parseResult = item["parseResult"] as? [String: Any] ?? [:]
            viewController?.showConfirm(text: text, parseResult: parseResult)
            let height = viewController?.preferredContentHeight ?? 200
            popover?.contentSize = NSSize(width: 340, height: height)
        } else {
            viewController?.resetToInput()
        }
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
    func quickCaptureDidRequestResize() {
        guard let vc = viewController else { return }
        let height = vc.preferredContentHeight
        popover?.contentSize = NSSize(width: 340, height: height)
    }

    func quickCaptureDidSubmit(_ text: String) {
        viewController?.showLoading()

        // 使用 NLTagger 提取候选人名（离线、同步）
        let nerHints = extractPersonNames(from: text)
        // 使用 NSDataDetector 提取日期/时间 hint（离线、同步）
        let dateHints = extractDateHints(from: text)

        let args: [String: Any] = [
            "text": text,
            "nerHints": nerHints,
            "dateHints": dateHints,
        ]

        channel?.invokeMethod("parse", arguments: args) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let dict = result as? [String: Any] else {
                    // 解析失败 → 直接保存为 knowledge note
                    self.saveDirectly(text)
                    return
                }

                // 如果 AI 路径返回 multiResult，则将 items 入队；否则将单条结果入队
                if let multi = dict["multiResult"] as? Bool, multi, let items = dict["items"] as? [[String: Any]], items.count > 0 {
                    for item in items {
                        let entry: [String: Any] = ["text": text, "parseResult": item]
                        self.pendingQueue.append(entry)
                    }
                } else {
                    let entry: [String: Any] = ["text": text, "parseResult": dict]
                    // If no entities detected, handle as direct save
                    let hasContact = dict["hasContact"] as? Bool ?? false
                    let hasEvent = dict["hasEvent"] as? Bool ?? false
                    if !hasContact && !hasEvent {
                        self.saveDirectly(text)
                        return
                    }
                    self.pendingQueue.append(entry)
                }

                self.updateQueueBadge()
                if !self.isProcessingQueue {
                    self.processNextInQueue()
                }
            }
        }
    }

    func quickCaptureDidConfirm(_ saveArgs: [String: Any]) {
        currentProcessingItem = nil
        viewController?.showLoading()
        let successMsg = buildSuccessMessage(from: saveArgs)
        channel?.invokeMethod("save", arguments: saveArgs) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Show per-item success then continue with next queued item
                self.popover?.contentSize = NSSize(width: 340, height: 80)
                self.viewController?.showSuccess(message: successMsg)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.processNextInQueue()
                }
            }
        }
    }

    func quickCaptureDidCancel() {
        currentProcessingItem = nil
        // Skip current and show next queued item if any
        processNextInQueue()
    }

    private func saveDirectly(_ text: String) {
        let args: [String: Any] = [
            "text": text,
            "contactAction": "skip",
            "eventAction": "skip",
        ]
        channel?.invokeMethod("save", arguments: args) { [weak self] _ in
            DispatchQueue.main.async {
                self?.popover?.contentSize = NSSize(width: 340, height: 64)
                self?.viewController?.showSuccess(message: "✓ 已保存")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.closePopover()
                    self?.popover?.contentSize = NSSize(width: 340, height: 64)
                }
            }
        }
    }

    /// 根据保存参数构建语义化的成功提示语。
    private func buildSuccessMessage(from args: [String: Any]) -> String {
        let contactAction = args["contactAction"] as? String ?? "skip"
        let eventAction   = args["eventAction"]   as? String ?? "skip"
        let contactName   = args["newContactName"] as? String
                          ?? (contactAction == "link" ? args["contactId"] as? String : nil)
        let eventTitle    = args["newEventTitle"]  as? String

        var parts: [String] = []

        switch contactAction {
        case "create":
            if let name = contactName, !name.isEmpty {
                parts.append("👤 联系人「\(name)」已创建")
            } else {
                parts.append("👤 联系人已创建")
            }
        case "link":
            if let name = contactName, !name.isEmpty {
                parts.append("👤 已关联「\(name)」")
            }
        default:
            break
        }

        switch eventAction {
        case "create":
            if let title = eventTitle, !title.isEmpty {
                parts.append("📅 事件「\(title)」已创建")
            } else {
                parts.append("📅 事件已创建")
            }
        case "link":
            parts.append("📅 已关联事件")
        default:
            break
        }

        return parts.isEmpty ? "✓ 已保存" : "✓ " + parts.joined(separator: "  ")
    }

    // MARK: - Queue processing

    private func processNextInQueue() {
        // If nothing pending, close soon
        if pendingQueue.isEmpty {
            isProcessingQueue = false
            updateQueueBadge()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.popover?.contentSize = NSSize(width: 340, height: 64)
                self.closePopover()
            }
            return
        }

        isProcessingQueue = true
        let entry = pendingQueue.removeFirst()
        currentProcessingItem = entry  // saved so re-open can restore this state
        updateQueueBadge(includingCurrent: true)

        let text = entry["text"] as? String ?? ""
        let parseResult = entry["parseResult"] as? [String: Any] ?? [:]

        // Present confirm UI for this entry
        viewController?.showConfirm(text: text, parseResult: parseResult)
        let height = viewController?.preferredContentHeight ?? 200
        self.popover?.contentSize = NSSize(width: 340, height: height)
    }

    private func updateQueueBadge(includingCurrent: Bool = false) {
        let count = pendingQueue.count + (includingCurrent ? 1 : 0)
        viewController?.setQueueCount(count)
    }

    // MARK: - NSDataDetector 日期提取

    /// 使用 NSDataDetector 提取文本中的日期/时间，返回 ISO 8601 字符串数组（UTC）。
    /// 结果作为 dateHints 传给 Dart，优先于 Dart 正则解析。
    private func extractDateHints(from text: String) -> [String] {
        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.date.rawValue
        ) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return matches.compactMap { match in
            guard match.resultType == .date, let date = match.date else { return nil }
            return formatter.string(from: date)
        }
    }

    // MARK: - NLTagger 人名提取

    /// 使用 Apple NaturalLanguage 框架提取人名实体（离线、同步、支持中英文）。
    private func extractPersonNames(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var names: [String] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation, .joinNames]
        ) { tag, range in
            if tag == .personalName {
                let name = String(text[range]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    names.append(name)
                }
            }
            return true
        }
        return names
    }
}

// MARK: - Delegate protocol

protocol QuickCaptureViewControllerDelegate: AnyObject {
    func quickCaptureDidSubmit(_ text: String)
    func quickCaptureDidConfirm(_ saveArgs: [String: Any])
    func quickCaptureDidCancel()
    /// Task 7: 标签删除后通知上层依据 preferredContentHeight 重整 popover 大小
    func quickCaptureDidRequestResize()
}

// MARK: - Multi-state ViewController

class QuickCaptureTextView: NSTextView {
    weak var owner: QuickCaptureViewController?
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
           let chars = event.charactersIgnoringModifiers, chars == "\r" {
            owner?.submitInput()
        } else {
            super.keyDown(with: event)
        }
    }
}


class QuickCaptureViewController: NSViewController {
    weak var delegate: QuickCaptureViewControllerDelegate?

    private var containerView: NSView!
    private var scrollView: NSScrollView!
    private var textView: NSTextView!
    private var placeholderLabel: NSTextField?
    private var queueBadge: NSTextField?
    private var submitButton: NSButton?

    // 确认态 UI
    private var confirmStack: NSStackView?
    private var contactSection: NSView?
    private var eventSection: NSView?
    private var infoTagsSection: NSView?
    private var buttonBar: NSView?

    // 加载/成功态
    private var statusLabel: NSTextField?

    // 确认态选择控件
    private var contactSegmentControl: NSSegmentedControl?
    private var eventActionSegmentControl: NSSegmentedControl?
    private var eventLinkButtons: [NSButton] = []

    // 当前状态数据
    private var currentText: String = ""
    private var currentParseResult: [String: Any] = [:]

    // 信息标签（确认态用户可删除，保留每个联系人相应的分组结构）
    private var pendingStructuredInfoTags: [[String: Any]] = []

    // 联系人选择态
    private var contactAction: String = "skip"
    private var selectedContactId: String?
    private var newContactName: String?

    // 事件选择态
    private var eventAction: String = "skip"
    private var selectedEventId: String?
    private var eventTitleFields: [NSTextField] = []
    private var eventTimePicker: NSDatePicker?

    var preferredContentHeight: CGFloat {
        let hasContact = currentParseResult["hasContact"] as? Bool ?? false
        let hasEvent = currentParseResult["hasEvent"] as? Bool ?? false
        let existingEvents = currentParseResult["existingEvents"] as? [[String: Any]]
        let aiFallback = currentParseResult["aiFallback"] as? Bool ?? false
        var height: CGFloat = 90  // baseline: echo label + button bar + padding
        if aiFallback { height += 52 }  // AI fallback hint + retry button
        if hasContact { height += 70 }
        if !pendingStructuredInfoTags.isEmpty {
            // 按实际标签数动态计算高度，避免截断
            let totalTags = pendingStructuredInfoTags.flatMap { $0["tags"] as? [String] ?? [] }.count
            let entryCount = pendingStructuredInfoTags.count
            let tagRows = max(1, Int(ceil(Double(totalTags) / 4.0)))
            height += 20 + CGFloat(entryCount) * 18 + CGFloat(tagRows) * 28
        }
        if hasEvent {
            let titleCount = max(1, (currentParseResult["eventTitles"] as? [Any])?.count ?? 1)
            height += 108 + CGFloat(titleCount - 1) * 28 + CGFloat((existingEvents?.count ?? 0)) * 28
        }
        return max(height, 120)
    }

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 80))
        container.translatesAutoresizingMaskIntoConstraints = false
        containerView = container

        // Scrollable text view — uses AutoLayout so it fills the container properly
        let tvFrameInit = NSRect(x: 0, y: 0, width: 240, height: 44)
        let sv = NSScrollView(frame: tvFrameInit)
        sv.borderType = .noBorder
        sv.hasVerticalScroller = true
        sv.hasHorizontalScroller = false  // 禁止横向滚动，强制换行
        sv.drawsBackground = false
        sv.translatesAutoresizingMaskIntoConstraints = false

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(containerSize: NSSize(width: tvFrameInit.width, height: .greatestFiniteMagnitude))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let tv = QuickCaptureTextView(frame: NSRect(origin: .zero, size: tvFrameInit.size), textContainer: textContainer)
        tv.minSize = NSSize(width: 0, height: 0)
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]   // 跟随 clip view 宽度自动伸缩，防止文字横向溢出
        tv.textContainer?.widthTracksTextView = true
        tv.isRichText = false
        tv.font = NSFont.systemFont(ofSize: 13)
        tv.delegate = self
        tv.owner = self

        sv.documentView = tv
        container.addSubview(sv)
        scrollView = sv
        textView = tv

        // Submit button — AutoLayout, right edge, vertically centred
        let submitBtn = NSButton(title: "提交", target: self, action: #selector(submitButtonTapped))
        submitBtn.bezelStyle = .rounded
        submitBtn.font = NSFont.systemFont(ofSize: 12)
        submitBtn.keyEquivalent = "\r"
        submitBtn.keyEquivalentModifierMask = .command
        submitBtn.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(submitBtn)
        submitButton = submitBtn

        // ScrollView fills container leaving room for submit button
        NSLayoutConstraint.activate([
            sv.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            sv.trailingAnchor.constraint(equalTo: submitBtn.leadingAnchor, constant: -8),
            sv.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            sv.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            submitBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            submitBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            submitBtn.widthAnchor.constraint(equalToConstant: 64),
        ])

        // Placeholder label — overlaid on the scroll view, left-aligned, vertically centred
        let ph = NSTextField(labelWithString: "记录…（按 Cmd+Return 提交）")
        ph.textColor = NSColor.placeholderTextColor
        ph.font = NSFont.systemFont(ofSize: 13)
        ph.isSelectable = false
        ph.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(ph)
        placeholderLabel = ph
        NSLayoutConstraint.activate([
            ph.leadingAnchor.constraint(equalTo: sv.leadingAnchor, constant: 4),
            ph.centerYAnchor.constraint(equalTo: sv.centerYAnchor),
            ph.trailingAnchor.constraint(lessThanOrEqualTo: sv.trailingAnchor),
        ])

        // Queue badge — top-right corner, overlaps submit button
        let badge = NSTextField(labelWithString: "")
        badge.alignment = .center
        badge.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        badge.textColor = NSColor.white
        badge.drawsBackground = true
        badge.backgroundColor = NSColor.systemBlue
        badge.isBezeled = false
        badge.wantsLayer = true
        badge.layer?.cornerRadius = 10
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.isHidden = true
        container.addSubview(badge)
        queueBadge = badge
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: submitBtn.topAnchor, constant: -6),
            badge.trailingAnchor.constraint(equalTo: submitBtn.trailingAnchor, constant: 6),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badge.heightAnchor.constraint(equalToConstant: 20),
        ])

        // observe text changes to update placeholder visibility
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: NSText.didChangeNotification, object: textView)

        view = container
    }

    func setQueueCount(_ count: Int) {
        DispatchQueue.main.async {
            if count <= 0 {
                self.queueBadge?.isHidden = true
            } else {
                self.queueBadge?.stringValue = "\(count)"
                self.queueBadge?.isHidden = false
            }
        }
    }

    @objc private func submitButtonTapped() {
        submitInput()
    }

    func submitInput() {
        let text = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        delegate?.quickCaptureDidSubmit(text)
    }

    func resetToInput() {
        clearConfirmUI()
        scrollView.isHidden = false
        submitButton?.isHidden = false
        textView.string = ""
        textView.isEditable = true
        statusLabel?.removeFromSuperview()
        statusLabel = nil
        // 每次打开随机切换提示文案，暗示智能识别能力
        let placeholders = [
            "明天下午见张三…",
            "周五和 Lisa 讨论项目…",
            "今天联系了王明关于合同…",
            "后天上午 10 点团队周会…",
            "记录…（按 Cmd+Return 提交）",
        ]
        placeholderLabel?.stringValue = placeholders[Int.random(in: 0..<placeholders.count)]
        placeholderLabel?.isHidden = false
        view.window?.makeFirstResponder(textView)
    }

    // MARK: - States

    func showLoading() {
        scrollView.isHidden = true
        submitButton?.isHidden = true
        clearConfirmUI()
        showStatusText("正在处理…")
    }

    func showSuccess(message: String = "✓ 已保存") {
        clearConfirmUI()
        scrollView.isHidden = true
        showStatusText(message)
        guard let label = statusLabel else { return }
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = NSColor.systemGreen
        label.maximumNumberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        // 轻微音效反馈
        NSSound(named: NSSound.Name("Tink"))?.play()
        // Fade-in 微动画
        label.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            label.animator().alphaValue = 1.0
        }
    }

    func showConfirm(text: String, parseResult: [String: Any]) {
        currentText = text
        currentParseResult = parseResult
        scrollView.isHidden = true
        submitButton?.isHidden = true
        statusLabel?.removeFromSuperview()
        statusLabel = nil
        clearConfirmUI()

        // 重置选择状态
        contactAction = "skip"
        selectedContactId = nil
        newContactName = nil
        eventAction = "skip"
        selectedEventId = nil

        // 提取 AI 返回的信息标签，保留原始每联系人分组结构
        pendingStructuredInfoTags = parseResult["contactInfoTags"] as? [[String: Any]] ?? []

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

        // 原始输入回显（P4：帮助用户确认识别是否正确）
        let inputLabel = NSTextField(labelWithString: "「\(text)」")
        inputLabel.font = NSFont.systemFont(ofSize: 11)
        inputLabel.textColor = NSColor.secondaryLabelColor
        inputLabel.lineBreakMode = .byTruncatingTail
        inputLabel.maximumNumberOfLines = 1
        inputLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(inputLabel)

        // If AI fell back to regex, show hint and retry button
        if let aiFallback = parseResult["aiFallback"] as? Bool, aiFallback {
            let hintLabel = NSTextField(labelWithString: "AI 解析失败，已切换至快速模式")
            hintLabel.font = NSFont.systemFont(ofSize: 11)
            hintLabel.textColor = NSColor.systemRed
            hintLabel.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(hintLabel)

            let retryBtn = NSButton(title: "重新 AI 解析", target: self, action: #selector(retryAiTapped))
            retryBtn.bezelStyle = .rounded
            retryBtn.font = NSFont.systemFont(ofSize: 11)
            retryBtn.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(retryBtn)
        }

        if hasContact {
            let section = buildContactSection(parseResult)
            stack.addArrangedSubview(section)
            contactSection = section
        }

        if !pendingStructuredInfoTags.isEmpty {
            let section = buildInfoTagsSection()
            stack.addArrangedSubview(section)
            infoTagsSection = section
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
        // originalName: the name actually extracted from user input (may differ from fuzzy-matched contactName)
        let originalName = result["originalName"] as? String

        // Label shows original input name when available, so user confirms what they typed
        let labelText: String
        if let orig = originalName, orig != contactName {
            labelText = "👤 识别到「\(orig)」，可能是：\(contactName)"
        } else {
            labelText = "👤 识别到联系人：\(contactName)"
        }
        let label = NSTextField(labelWithString: labelText)
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)

        // 互斥操作选择：NSSegmentedControl 视觉更清晰
        let segments: [String]
        let defaultSegment: Int
        if contactType == "matched", let cid = contactId {
            segments = ["关联", "新建联系人", "跳过"]
            contactAction = "link"
            selectedContactId = cid
            defaultSegment = 0
        } else {
            segments = ["新建联系人", "跳过"]
            contactAction = "create"
            // Use original extracted name (what user typed) rather than matched contact name
            newContactName = originalName ?? contactName
            selectedContactId = nil
            defaultSegment = 0
        }

        let seg = NSSegmentedControl(labels: segments, trackingMode: .selectOne,
                                     target: self, action: #selector(contactSegmentChanged(_:)))
        seg.selectedSegment = defaultSegment
        seg.font = NSFont.systemFont(ofSize: 11)
        seg.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(seg)
        contactSegmentControl = seg

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: box.topAnchor),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            seg.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            seg.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            seg.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            box.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
        ])

        return box
    }

    @objc private func contactSegmentChanged(_ sender: NSSegmentedControl) {
        let isMatched = (currentParseResult["contactType"] as? String) == "matched"
        let idx = sender.selectedSegment
        if isMatched {
            switch idx {
            case 0:
                contactAction = "link"
                selectedContactId = currentParseResult["contactId"] as? String
                newContactName = nil
            case 1:
                contactAction = "create"
                // Prefer the original extracted name (what user typed) over the fuzzy-matched contact name
                newContactName = (currentParseResult["originalName"] as? String)
                    ?? (currentParseResult["contactName"] as? String)
                selectedContactId = nil
            default:
                contactAction = "skip"
                selectedContactId = nil
                newContactName = nil
            }
        } else {
            if idx == 0 {
                contactAction = "create"
                newContactName = currentParseResult["contactName"] as? String
                selectedContactId = nil
            } else {
                contactAction = "skip"
                selectedContactId = nil
                newContactName = nil
            }
        }
    }

    @objc private func retryAiTapped() {
        // Re-run parse for the current text via delegate
        delegate?.quickCaptureDidSubmit(currentText)
    }

    // MARK: - Event section

    private func buildEventSection(_ result: [String: Any]) -> NSView {
        let box = NSView()
        box.translatesAutoresizingMaskIntoConstraints = false

        // Prefer eventTitles array; fall back to single eventTitle string.
        // Flutter method channels encode List<String> as NSArray ([Any]), not [String],
        // so we must cast via [Any] and then compactMap to get [String].
        let rawTitles = (result["eventTitles"] as? [Any])?.compactMap { $0 as? String }
        let eventTitles: [String]
        if let arr = rawTitles, !arr.isEmpty {
            eventTitles = arr
        } else {
            let single = result["eventTitle"] as? String ?? ""
            eventTitles = single.isEmpty ? [] : [single]
        }
        let eventDate = result["eventDate"] as? String ?? ""
        let existingEvents = result["existingEvents"] as? [[String: Any]] ?? []

        let isTimeExact = result["isTimeExact"] as? Bool ?? false

        let dateLabel = formatDateLabel(eventDate)
        let labelText = isTimeExact
            ? "📅 识别到时间：\(dateLabel)"
            : "📅 识别到时间：\(dateLabel)（请确认）"
        let label = NSTextField(labelWithString: labelText)
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)

        // 时间选择器
        let picker = NSDatePicker()
        picker.datePickerStyle = .textField
        picker.datePickerElements = .hourMinute
        picker.isBezeled = true
        picker.drawsBackground = true
        let parsedBase = ISO8601DateFormatter().date(from: eventDate) ?? dateFromFlexibleISO(eventDate)
        if let base = parsedBase {
            let cal = Calendar.current
            let hour = cal.component(.hour, from: base)
            let minute = cal.component(.minute, from: base)
            if isTimeExact || hour != 0 || minute != 0 {
                // Exact time ("下午三点") or vague period with inferred hour ("下午"→14:00, "晚上"→20:00) — use as-is
                picker.dateValue = base
            } else {
                // Pure date, no time hint at all (T00:00:00) — default to 08:00
                var comps = cal.dateComponents([.year, .month, .day], from: base)
                comps.hour = 8
                comps.minute = 0
                picker.dateValue = cal.date(from: comps) ?? base
            }
        } else {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = 8
            comps.minute = 0
            picker.dateValue = Calendar.current.date(from: comps) ?? Date()
        }
        picker.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(picker)
        eventTimePicker = picker

        // 事件标题输入（一个输入框对应一个标题）
        eventTitleFields = []
        let titlesToShow = eventTitles.isEmpty ? [""] : eventTitles
        for titleStr in titlesToShow {
            let titleField = NSTextField(frame: .zero)
            titleField.stringValue = titleStr
            titleField.placeholderString = "事件标题"
            titleField.font = NSFont.systemFont(ofSize: 12)
            titleField.isBezeled = true
            titleField.bezelStyle = .roundedBezel
            titleField.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(titleField)
            eventTitleFields.append(titleField)
        }

        var lastView: NSView = eventTitleFields.last ?? picker

        // 已有事件按钮
        eventLinkButtons = []
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
            eventLinkButtons.append(btn)
        }

        // 互斥操作选择（创建 / 关联已有 / 跳过）
        let actionSeg = NSSegmentedControl(labels: ["创建事件", "关联已有", "跳过"], trackingMode: .selectOne,
                                           target: self, action: #selector(eventActionSegmentChanged(_:)))
        actionSeg.selectedSegment = 0
        actionSeg.font = NSFont.systemFont(ofSize: 11)
        actionSeg.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(actionSeg)
        eventActionSegmentControl = actionSeg
        eventAction = "create"

        // 布局
        var constraints: [NSLayoutConstraint] = [
            label.topAnchor.constraint(equalTo: box.topAnchor),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            picker.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            picker.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            picker.heightAnchor.constraint(equalToConstant: 22),
            box.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
        ]

        // 每个标题输入框垂直堆叠
        var prevAnchor = picker.bottomAnchor
        for titleField in eventTitleFields {
            constraints.append(titleField.topAnchor.constraint(equalTo: prevAnchor, constant: 6))
            constraints.append(titleField.leadingAnchor.constraint(equalTo: box.leadingAnchor))
            constraints.append(titleField.trailingAnchor.constraint(equalTo: box.trailingAnchor))
            constraints.append(titleField.heightAnchor.constraint(equalToConstant: 22))
            prevAnchor = titleField.bottomAnchor
        }
        lastView = eventTitleFields.last ?? picker
        for btn in eventBtnViews {
            constraints.append(btn.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 4))
            constraints.append(btn.leadingAnchor.constraint(equalTo: box.leadingAnchor))
            lastView = btn
        }

        constraints.append(actionSeg.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 4))
        constraints.append(actionSeg.leadingAnchor.constraint(equalTo: box.leadingAnchor))
        constraints.append(actionSeg.bottomAnchor.constraint(equalTo: box.bottomAnchor))

        NSLayoutConstraint.activate(constraints)
        return box
    }

    @objc private func eventLinkTapped(_ sender: NSButton) {
        eventAction = "link"
        selectedEventId = sender.toolTip
        // 高亮已选按钮，取消其他已有事件按钮的选中态
        for btn in eventLinkButtons {
            btn.state = (btn === sender) ? .on : .off
        }
        // 切到「关联已有」（index 1），语义明确
        eventActionSegmentControl?.selectedSegment = 1
    }

    @objc private func eventActionSegmentChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            eventAction = "create"
            selectedEventId = nil
        case 1:
            // 「关联已有」：保留 selectedEventId，等用户点选事件按钮
            eventAction = "link"
        default:
            eventAction = "skip"
            selectedEventId = nil
        }
        // 用户主动切到创建或跳过时，取消所有已有事件按钮的选中态
        if sender.selectedSegment != 1 {
            for btn in eventLinkButtons { btn.state = .off }
        }
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

    @objc func textDidChange(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView, tv === textView else { return }
        // Placeholder visibility only — input view uses a fixed window height
        let empty = textView.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel?.isHidden = !empty
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        // 批量队列场景：透传 isFirstInBatch，Dart 端据此判断是否写入 note
        if let firstInBatch = currentParseResult["isFirstInBatch"] {
            args["isFirstInBatch"] = firstInBatch
        }

        if contactAction == "link", let cid = selectedContactId {
            args["contactId"] = cid
        } else if contactAction == "create" {
            args["newContactName"] = newContactName ?? (currentParseResult["contactName"] as? String ?? "")
        }

        if eventAction == "link", let eid = selectedEventId {
            args["eventId"] = eid
        } else if eventAction == "create" {
            let titles = eventTitleFields.map { $0.stringValue.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            if titles.count == 1 {
                args["newEventTitle"] = titles[0]
            } else if titles.count > 1 {
                args["newEventTitles"] = titles
            } else {
                args["newEventTitle"] = ""
            }
            // 合并基础日期（年月日）和时间选择器的时分，生成最终事件时间
            let isoStr = currentParseResult["eventDate"] as? String ?? ""
            let baseDate = ISO8601DateFormatter().date(from: isoStr) ?? dateFromFlexibleISO(isoStr)
            if let base = baseDate, let picker = eventTimePicker {
                let cal = Calendar.current
                var comps = cal.dateComponents([.year, .month, .day], from: base)
                let timeComps = cal.dateComponents([.hour, .minute], from: picker.dateValue)
                comps.hour = timeComps.hour
                comps.minute = timeComps.minute
                if let merged = cal.date(from: comps) {
                    let fmt = ISO8601DateFormatter()
                    fmt.formatOptions = [.withInternetDateTime]
                    args["eventDate"] = fmt.string(from: merged)
                } else {
                    args["eventDate"] = isoStr
                }
            } else if let picker = eventTimePicker {
                // No parseable base date (dateless event) — use picker's value (defaults to today)
                let fmt = ISO8601DateFormatter()
                fmt.formatOptions = [.withInternetDateTime]
                args["eventDate"] = fmt.string(from: picker.dateValue)
            } else {
                args["eventDate"] = isoStr
            }
        }

        if !pendingStructuredInfoTags.isEmpty {
            args["infoTags"] = pendingStructuredInfoTags
        }

        delegate?.quickCaptureDidConfirm(args)
    }

    // MARK: - Info tags section

    private func buildInfoTagsSection() -> NSView {
        let box = NSStackView()
        box.orientation = .vertical
        box.alignment = .leading
        box.spacing = 4
        box.translatesAutoresizingMaskIntoConstraints = false

        let headerLabel = NSTextField(labelWithString: "🏷 信息标签")
        headerLabel.font = NSFont.systemFont(ofSize: 11)
        headerLabel.textColor = NSColor.secondaryLabelColor
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        box.addArrangedSubview(headerLabel)

        for (entryIndex, entry) in pendingStructuredInfoTags.enumerated() {
            guard let contactName = entry["contact"] as? String,
                  let tags = entry["tags"] as? [String], !tags.isEmpty else { continue }

            // 联系人小标题
            let nameLabel = NSTextField(labelWithString: contactName)
            nameLabel.font = NSFont.boldSystemFont(ofSize: 10)
            nameLabel.textColor = NSColor.tertiaryLabelColor
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            box.addArrangedSubview(nameLabel)

            // 该联系人的 tag chip 行
            let tagRow = NSStackView()
            tagRow.orientation = .horizontal
            tagRow.spacing = 4
            tagRow.translatesAutoresizingMaskIntoConstraints = false

            for (tagIndex, tagName) in tags.enumerated() {
                let btn = NSButton(title: "\(tagName) ×", target: self, action: #selector(infoTagDeleteTapped(_:)))
                btn.bezelStyle = .rounded
                btn.font = NSFont.systemFont(ofSize: 11)
                // entryIndex * 100 + tagIndex 编码便于 delete 时定位
                btn.tag = entryIndex * 100 + tagIndex
                btn.translatesAutoresizingMaskIntoConstraints = false
                tagRow.addArrangedSubview(btn)
            }
            box.addArrangedSubview(tagRow)
        }

        box.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        return box
    }

    @objc private func infoTagDeleteTapped(_ sender: NSButton) {
        let encoded = sender.tag
        let entryIndex = encoded / 100
        let tagIndex   = encoded % 100
        guard entryIndex < pendingStructuredInfoTags.count else { return }
        var entry = pendingStructuredInfoTags[entryIndex]
        guard var tags = entry["tags"] as? [String], tagIndex < tags.count else { return }
        tags.remove(at: tagIndex)
        if tags.isEmpty {
            pendingStructuredInfoTags.remove(at: entryIndex)
        } else {
            entry["tags"] = tags
            pendingStructuredInfoTags[entryIndex] = entry
        }
        rebuildInfoTagsSection()
    }

    private func rebuildInfoTagsSection() {
        infoTagsSection?.removeFromSuperview()
        infoTagsSection = nil

        if !pendingStructuredInfoTags.isEmpty, let stack = confirmStack {
            let section = buildInfoTagsSection()
            if let barIndex = stack.arrangedSubviews.firstIndex(where: { $0 === buttonBar }) {
                stack.insertArrangedSubview(section, at: barIndex)
            } else {
                stack.addArrangedSubview(section)
            }
            infoTagsSection = section
        }
        // Task 7: 标签变化后重整 popover 高度
        delegate?.quickCaptureDidRequestResize()
    }

    private func showStatusText(_ text: String) {
        statusLabel?.removeFromSuperview()
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13)
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
        ])
        statusLabel = label
    }

    private func clearConfirmUI() {
        confirmStack?.removeFromSuperview()
        confirmStack = nil
        contactSection = nil
        eventSection = nil
        infoTagsSection = nil
        buttonBar = nil
        eventTitleFields = []
        eventTimePicker = nil
        contactSegmentControl = nil
        eventActionSegmentControl = nil
        eventLinkButtons = []
        pendingStructuredInfoTags = []
    }

    private func makeSmallButton(_ title: String) -> NSButton {
        let btn = NSButton(title: title, target: nil, action: nil)
        btn.bezelStyle = .rounded
        btn.font = NSFont.systemFont(ofSize: 11)
        btn.setButtonType(.pushOnPushOff)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
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

// MARK: - NSTextViewDelegate (input state)

extension QuickCaptureViewController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // insertNewline（plain Return）— 插入换行，支持多行输入；提交由 Cmd+Return 负责
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            return false  // 交给默认处理，插入换行符
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            delegate?.quickCaptureDidCancel()
            return true
        }
        return false
    }
}
