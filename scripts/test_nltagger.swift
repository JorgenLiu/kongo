#!/usr/bin/env swift
//
// test_nltagger.swift
// 验证 Apple NaturalLanguage 框架 + NSDataDetector 对快速笔记输入的实际能力边界。
//
// 运行方式：
//   swift scripts/test_nltagger.swift
//
// 关注三个 API（不依赖网络，全离线）：
//   1. NLTagger(.nameType)       — 人名/地名/机构名 NER
//   2. NLTagger(.lexicalClass)   — 词性标注（名词/动词/形容词…）
//   3. NSDataDetector(.date)     — 自然语言日期/时间检测
//

import Foundation
import NaturalLanguage

// MARK: - 测试语料（100 条）

let testTexts: [(label: String, text: String)] = [

    // ── 人名：中文 2 字 ──
    ("CN2_bare",          "约了张伟明天开会"),
    ("CN2_trigger_call",  "打电话给李明"),
    ("CN2_trigger_msg",   "发消息给王芳"),
    ("CN2_met",           "今天遇到了赵磊"),
    ("CN2_told",          "刚刚告诉陈静这件事"),
    ("CN2_collab",        "和刘洋一起做方案"),
    ("CN2_saw",           "碰到了孙悦"),
    ("CN2_in_sentence",   "下周三和吴迪讨论合同细节"),
    ("CN2_multiple",      "张伟和李娜都同意了"),
    ("CN2_title_prefix",  "王总说明天延期"),

    // ── 人名：中文 3 字 ──
    ("CN3_bare",          "帮张小明安排会议室"),
    ("CN3_trigger",       "联系一下李大伟"),
    ("CN3_context",       "陈晓燕发来了合同"),
    ("CN3_collab",        "和王建国确认需求"),
    ("CN3_appt",          "下午见刘晓峰"),
    ("CN3_review",        "给赵丽华发 review 意见"),
    ("CN3_sent_to",       "把方案发给孙建军"),
    ("CN3_meeting",       "和吴小红开碰头会"),
    ("CN3_briefing",      "向邓志强汇报"),
    ("CN3_follow_up",     "跟进一下郑建平那边"),

    // ── 人名：4 字复姓 ──
    ("CN4_ouyang",        "欧阳修发来修改意见"),
    ("CN4_zhuge",         "诸葛亮那边还没回"),
    ("CN4_sima",          "司马昭下周来拜访"),
    ("CN4_shangguan",     "上官婉儿负责这块"),
    ("CN4_murong",        "慕容复来面试了"),
    ("CN4_linghu",        "令狐冲今天请假"),
    ("CN4_ouyang_call",   "打电话给欧阳娜娜"),
    ("CN4_zhuge_appt",    "约了诸葛亮明天下午"),

    // ── 人名：英文 ──
    ("EN_first",          "John called me this morning"),
    ("EN_sentence_start", "Sarah will join the meeting tomorrow"),
    ("EN_full",           "Tom Wilson sent the contract"),
    ("EN_chinese_mix",    "和 Michael 确认一下时间"),
    ("EN_trigger",        "email David about the review"),

    // ── 时间：相对日期 ──
    ("TIME_today",        "今天下午开会"),
    ("TIME_tomorrow",     "明天早上九点有站会"),
    ("TIME_day_after",    "后天交设计稿"),
    ("TIME_3days",        "大后天发版本"),
    ("TIME_yesterday",    "昨天忘了和张伟确认"),

    // ── 时间：时段修饰 ──
    ("TIME_morning",      "明天早上八点开会"),
    ("TIME_am",           "后天上午十点和客户见面"),
    ("TIME_noon",         "今天中午吃饭"),
    ("TIME_pm",           "明天下午三点会议"),
    ("TIME_pm_half",      "明天下午两点半有面试"),
    ("TIME_pm_minute",    "后天下午四点十分签合同"),
    ("TIME_evening",      "今天傍晚去机场"),
    ("TIME_night",        "明天晚上八点半聚餐"),
    ("TIME_night_oclock", "明天晚上九点"),

    // ── 时间：周几 ──
    ("TIME_weekday_bare", "周三下午开会"),
    ("TIME_weekday_next", "下周一和李明讨论"),
    ("TIME_weekday_this", "本周五发版"),
    ("TIME_weekday_xing", "星期二上午十点站会"),

    // ── 时间：绝对日期 ──
    ("TIME_abs_month",    "4月15号见客户"),
    ("TIME_abs_full",     "3月30日提交代码"),
    ("TIME_abs_zero",     "05月01日放假"),
    ("TIME_bare_day",     "30号开会"),
    ("TIME_bare_past",    "15号交报告"),

    // ── 时间 + 人名组合 ──
    ("MIX_person_time",   "明天下午两点半约了张伟开会"),
    ("MIX_time_trigger",  "下周三打电话给欧阳修"),
    ("MIX_en_time",       "明天上午和 Sarah 开会"),
    ("MIX_multi_person",  "后天和李明、王芳一起讨论"),
    ("MIX_3char_time",    "下周五和刘晓峰签合同"),

    // ── 事件标题意图 ──
    ("EVENT_meeting",     "明天下午开会"),
    ("EVENT_interview",   "后天有面试"),
    ("EVENT_dinner",      "今晚聚餐"),
    ("EVENT_contract",    "下周签合同"),
    ("EVENT_review",      "明天做 code review"),
    ("EVENT_demo",        "周五做产品演示"),
    ("EVENT_call",        "下午打电话跟进"),
    ("EVENT_report",      "周三汇报进度"),
    ("EVENT_deadline",    "4月15号截止日期"),
    ("EVENT_travel",      "下周出差北京"),

    // ── 纯知识笔记（无时间无人名）──
    ("KN_plain",          "记得买牛奶"),
    ("KN_idea",           "产品想法：离线优先存储"),
    ("KN_todo",           "整理一下技术债"),
    ("KN_note",           "密码是abc123"),
    ("KN_thought",        "考虑换个架构方案"),

    // ── 停用词误命中测试 ──
    ("STOP_today",        "今天很忙"),
    ("STOP_meeting",      "会议室预订好了"),
    ("STOP_project",      "项目进展顺利"),
    ("STOP_system",       "系统上线了"),
    ("STOP_data",         "数据需要清洗"),

    // ── 边界：短输入 ──
    ("EDGE_onechar",      "忙"),
    ("EDGE_twocn",        "开会"),
    ("EDGE_name_only",    "张伟"),
    ("EDGE_time_only",    "明天"),
    ("EDGE_empty_ish",    "  "),

    // ── 边界：混合中英文 ──
    ("BILINGUAL_1",       "明天 deadline 提交 PR"),
    ("BILINGUAL_2",       "和 PM 对需求"),
    ("BILINGUAL_3",       "update README 然后发邮件"),
    ("BILINGUAL_4",       "review John 的代码"),
    ("BILINGUAL_5",       "fix bug 然后通知张伟"),

    // ── 边界：组织机构名 ──
    ("ORG_1",             "阿里巴巴的合同发来了"),
    ("ORG_2",             "字节跳动面试通知"),
    ("ORG_3",             "苹果公司下周来访"),
    ("ORG_4",             "和腾讯合作项目"),
    ("ORG_5",             "Google 那边说要延期"),

    // ── 边界：地名 ──
    ("LOC_1",             "明天去上海出差"),
    ("LOC_2",             "后天飞北京"),
    ("LOC_3",             "周五在深圳开会"),
    ("LOC_4",             "下周去杭州拜访客户"),
    ("LOC_5",             "和纽约团队开会"),

    // ── 边界：带标点 ──
    ("PUNCT_comma",       "张伟说，明天开会"),
    ("PUNCT_exclaim",     "明天记得开会！"),
    ("PUNCT_question",    "后天有时间吗？找李明确认"),
    ("PUNCT_ellipsis",    "约了张伟……下午两点"),

    // ── 口语化/非正式 ──
    ("COLLQ_1",           "等下打给老王"),
    ("COLLQ_2",           "明儿下午见"),
    ("COLLQ_3",           "找小李确认一下"),
    ("COLLQ_4",           "下午两点来找我"),
    ("COLLQ_5",           "刚跟张总聊完"),

    // ── 数字混合 ──
    ("NUM_1",             "Q2 目标和张伟对齐"),
    ("NUM_2",             "2025年底前完成"),
    ("NUM_3",             "第3季度回顾会议"),
    ("NUM_4",             "预算100万，找李明审批"),
    ("NUM_5",             "v2.0发布，通知王芳"),
]

// MARK: - 工具函数

func separator(_ char: Character = "─", count: Int = 72) -> String {
    String(repeating: char, count: count)
}

func runNameType(_ text: String) -> [(range: Range<String.Index>, tag: String, token: String)] {
    let tagger = NLTagger(tagSchemes: [.nameType])
    tagger.string = text
    var results: [(Range<String.Index>, String, String)] = []
    tagger.enumerateTags(
        in: text.startIndex..<text.endIndex,
        unit: .word,
        scheme: .nameType,
        options: [.omitWhitespace, .omitPunctuation, .joinNames]
    ) { tag, range in
        if let tag = tag {
            let token = String(text[range])
            results.append((range, tag.rawValue, token))
        }
        return true
    }
    return results
}

func runLexicalClass(_ text: String) -> [(token: String, pos: String)] {
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = text
    var results: [(String, String)] = []
    tagger.enumerateTags(
        in: text.startIndex..<text.endIndex,
        unit: .word,
        scheme: .lexicalClass,
        options: [.omitWhitespace, .omitPunctuation]
    ) { tag, range in
        if let tag = tag {
            let token = String(text[range])
            results.append((token, tag.rawValue))
        }
        return true
    }
    return results
}

func runDataDetector(_ text: String) -> [String] {
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
        return ["[NSDataDetector 初始化失败]"]
    }
    let nsText = text as NSString
    let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
    return matches.compactMap { match -> String? in
        guard let date = match.date else { return nil }
        let matchedText = nsText.substring(with: match.range)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return "\"\(matchedText)\" → \(formatter.string(from: date))"
    }
}

// MARK: - 统计累积

var nameTypeStats: [String: Int] = [:]   // tag → hit count
var nameHitCount = 0
var dateHitCount = 0
var totalCount = 0

// MARK: - 主循环

print(separator("═"))
print("  NLTagger + NSDataDetector 能力验证报告")
print("  测试时间：\(Date())")
print("  测试用例：\(testTexts.count) 条")
print(separator("═"))

for (label, text) in testTexts {
    guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
    totalCount += 1

    let names  = runNameType(text)
    let dates  = runDataDetector(text)
    let lexical = runLexicalClass(text)

    // 仅在有发现时打印（减少噪音）
    let hasName = !names.filter { ["PersonalName","PlaceName","OrganizationName"].contains($0.tag) }.isEmpty
    let hasDate = !dates.isEmpty

    if hasName || hasDate {
        print("\n[\(label)] \(text)")
    }

    // nameType 结果
    for hit in names {
        let tag = hit.tag
        nameTypeStats[tag, default: 0] += 1
        if ["PersonalName","PlaceName","OrganizationName"].contains(tag) {
            nameHitCount += 1
            print("  🏷  nameType  \(tag.padding(toLength: 20, withPad: " ", startingAt: 0))  [\(hit.token)]")
        }
    }

    // NSDataDetector 日期
    for d in dates {
        dateHitCount += 1
        print("  📅  dataDetect  \(d)")
    }

    // lexicalClass（仅当有人名或日期命中时打印，帮助理解上下文）
    if hasName || hasDate {
        let posLine = lexical.map { "\($0.token)/\(shortPos($0.pos))" }.joined(separator: " ")
        print("  📝  lexical     \(posLine)")
    }
}

// MARK: - 汇总报告

func shortPos(_ pos: String) -> String {
    switch pos {
    case "Noun": return "N"
    case "Verb": return "V"
    case "Adjective": return "Adj"
    case "Adverb": return "Adv"
    case "Pronoun": return "Pron"
    case "Determiner": return "Det"
    case "Particle": return "Part"
    case "Preposition": return "Prep"
    case "Number": return "Num"
    case "Conjunction": return "Conj"
    case "Interjection": return "Interj"
    case "Classifier": return "Cl"
    case "Idiom": return "Idiom"
    case "OtherWord": return "Other"
    default: return pos
    }
}

print("\n\(separator("═"))")
print("  汇总")
print(separator("─"))
print("  总用例数：\(totalCount)")
print("  含 nameType 命中：\(nameHitCount) 次")
print("  含 dataDetector 命中：\(dateHitCount) 次")
print()
print("  nameType tag 分布：")
for (tag, count) in nameTypeStats.sorted(by: { $0.value > $1.value }) {
    print("    \(tag.padding(toLength: 22, withPad: " ", startingAt: 0))\(count)")
}
print(separator("═"))

// MARK: - 专项测试：时间用例详情（无论是否命中都打印）

print("\n  专项：NSDataDetector 时间用例全览（含未命中）")
print(separator("─"))
let timeTests = testTexts.filter { $0.label.hasPrefix("TIME") || $0.label.hasPrefix("MIX") }
for (label, text) in timeTests {
    let dates = runDataDetector(text)
    let result = dates.isEmpty ? "❌ 未命中" : dates.joined(separator: " | ")
    let padding = label.padding(toLength: 22, withPad: " ", startingAt: 0)
    print("  \(padding)\(text.padding(toLength: 30, withPad: " ", startingAt: 0))\(result)")
}

// MARK: - 专项测试：人名提取全览（无论是否命中都打印）

print("\n  专项：NLTagger 人名提取全览（含未命中）")
print(separator("─"))
let nameTests = testTexts.filter {
    $0.label.hasPrefix("CN") || $0.label.hasPrefix("EN") ||
    $0.label.hasPrefix("MIX") || $0.label.hasPrefix("COLLQ")
}
for (label, text) in nameTests {
    let names = runNameType(text)
    let persons = names.filter { $0.tag == "PersonalName" }.map { "[\($0.token)]" }
    let result = persons.isEmpty ? "❌ 未命中" : persons.joined(separator: ", ")
    let padding = label.padding(toLength: 22, withPad: " ", startingAt: 0)
    print("  \(padding)\(text.padding(toLength: 30, withPad: " ", startingAt: 0))\(result)")
}

print(separator("═"))
print("  完成。")
