import Foundation
import UIKit

enum MistakePDFExporter {
    private static let a4Size   = CGSize(width: 595.28, height: 841.89)
    private static let margin: CGFloat = 36
    private static let headerH: CGFloat = 46   // 页眉区高度
    private static let footerH: CGFloat = 24   // 页脚区高度

    // MARK: - Public API

    static func export(
        title: String,
        cards: [MistakeCard],
        layout: ExportLayout,
        kind: ExportKind,
        groupBySubject: Bool = false,
        includeCoverPage: Bool = true
    ) throws -> URL {
        let fileName = "\(UUID().uuidString).pdf"
        let destination = AppStorageDirectory.exports.appendingPathComponent(fileName)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: title,
            kCGPDFContextCreator as String: "PaperClip"
        ]

        // 如果按学科分组，按 Subject 枚举顺序排序（相同学科聚集在一起）
        let orderedCards: [MistakeCard]
        if groupBySubject {
            let subjectOrder: (String) -> Int = { subject in
                Subject.allCases.firstIndex { $0.rawValue == subject } ?? 99
            }
            orderedCards = cards.sorted {
                let a = subjectOrder($0.subject)
                let b = subjectOrder($1.subject)
                return a != b ? a < b : $0.createdAt < $1.createdAt
            }
        } else {
            orderedCards = cards
        }

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: a4Size),
            format: format
        )
        try renderer.writePDF(to: destination) { context in
            var pageNumber = 1

            // 封面页
            if includeCoverPage {
                context.beginPage()
                drawCoverPage(title: title, cards: orderedCards)
                pageNumber += 1
            }

            if groupBySubject {
                // 按学科分组渲染
                var currentSubject = ""
                var pageCards: [MistakeCard] = []
                let perPage = layout.rawValue

                func flushPage() {
                    guard !pageCards.isEmpty else { return }
                    context.beginPage()
                    drawHeader(title, pageNumber: pageNumber)
                    drawFooter(pageNumber: pageNumber)
                    drawCards(pageCards, layout: layout, kind: kind)
                    pageNumber += 1
                    pageCards = []
                }

                for card in orderedCards {
                    // 切换学科时先刷当前页，再插学科分隔页
                    if card.subject != currentSubject {
                        flushPage()
                        context.beginPage()
                        drawSubjectDivider(card.subject, cards: orderedCards.filter { $0.subject == card.subject }.count)
                        drawHeader(title, pageNumber: pageNumber)
                        drawFooter(pageNumber: pageNumber)
                        pageNumber += 1
                        currentSubject = card.subject
                    }
                    pageCards.append(card)
                    if pageCards.count == perPage { flushPage() }
                }
                flushPage()

            } else {
                // 普通分页渲染
                let perPage = layout.rawValue
                for pageStart in stride(from: 0, to: orderedCards.count, by: perPage) {
                    context.beginPage()
                    drawHeader(title, pageNumber: pageNumber)
                    drawFooter(pageNumber: pageNumber)
                    let slice = Array(orderedCards[pageStart..<min(pageStart + perPage, orderedCards.count)])
                    drawCards(slice, layout: layout, kind: kind)
                    pageNumber += 1
                }
            }
        }
        return destination
    }

    // MARK: - Cover Page

    private static func drawCoverPage(title: String, cards: [MistakeCard]) {
        let w = a4Size.width
        let h = a4Size.height

        // 顶部色块
        let accentRect = CGRect(x: 0, y: 0, width: w, height: h * 0.38)
        UIColor.systemBlue.setFill()
        UIRectFill(accentRect)

        // 标题
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let titleStr = title as NSString
        let titleSize = titleStr.size(withAttributes: titleAttrs)
        titleStr.draw(
            at: CGPoint(x: (w - titleSize.width) / 2, y: h * 0.13),
            withAttributes: titleAttrs
        )

        // 副标题 — 日期
        let dateStr = Date.now.formatted(.dateTime.year().month().day()) as NSString
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let dateSize = dateStr.size(withAttributes: dateAttrs)
        dateStr.draw(
            at: CGPoint(x: (w - dateSize.width) / 2, y: h * 0.13 + titleSize.height + 10),
            withAttributes: dateAttrs
        )

        // 总题数徽章
        let badgeRect = CGRect(x: w / 2 - 48, y: h * 0.32 - 36, width: 96, height: 36)
        UIColor.white.withAlphaComponent(0.2).setFill()
        UIBezierPath(roundedRect: badgeRect, cornerRadius: 18).fill()
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let countStr = "共 \(cards.count) 道题" as NSString
        let countSize = countStr.size(withAttributes: countAttrs)
        countStr.draw(
            at: CGPoint(x: badgeRect.midX - countSize.width / 2, y: badgeRect.midY - countSize.height / 2),
            withAttributes: countAttrs
        )

        // 学科统计区（白色卡片区）
        let statsY = h * 0.44
        let subjectGroups = Dictionary(grouping: cards, by: \.subject)
            .sorted { $0.value.count > $1.value.count }

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.label
        ]
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.secondaryLabel
        ]

        // 节标题
        ("学科分布" as NSString).draw(
            at: CGPoint(x: margin, y: statsY),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )

        var rowY = statsY + 28
        let barMaxW = w - margin * 2 - 80
        let maxCount = subjectGroups.first?.value.count ?? 1

        for group in subjectGroups.prefix(10) {
            let count = group.value.count
            let barW = barMaxW * CGFloat(count) / CGFloat(maxCount)
            let barRect = CGRect(x: margin + 80, y: rowY + 2, width: barW, height: 14)
            UIColor.systemBlue.withAlphaComponent(0.25).setFill()
            UIBezierPath(roundedRect: barRect, cornerRadius: 4).fill()

            (group.key as NSString).draw(at: CGPoint(x: margin, y: rowY), withAttributes: bodyAttrs)
            ("\(count) 题" as NSString).draw(
                at: CGPoint(x: margin + 80 + barW + 6, y: rowY),
                withAttributes: labelAttrs
            )
            rowY += 22
        }

        // 掌握状态汇总
        let masteredCount = cards.filter { $0.status == MasteryStatus.mastered.rawValue }.count
        let reviewCount   = cards.filter { $0.status == MasteryStatus.review.rawValue }.count
        let unmasteredCount = cards.filter { $0.status == MasteryStatus.unmastered.rawValue }.count

        let summaryY = max(rowY + 20, h * 0.75)
        ("掌握状态" as NSString).draw(
            at: CGPoint(x: margin, y: summaryY),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
        let summaryText = "已掌握 \(masteredCount)  待复习 \(reviewCount)  未掌握 \(unmasteredCount)"
        (summaryText as NSString).draw(
            at: CGPoint(x: margin, y: summaryY + 26),
            withAttributes: bodyAttrs
        )

        // 页脚
        let footerText = "由 PaperClip 生成" as NSString
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let footerSize = footerText.size(withAttributes: footerAttrs)
        footerText.draw(
            at: CGPoint(x: (w - footerSize.width) / 2, y: h - 28),
            withAttributes: footerAttrs
        )
    }

    // MARK: - Subject Divider Page

    private static func drawSubjectDivider(_ subject: String, cards count: Int) {
        let w = a4Size.width
        let h = a4Size.height

        // 学科色带
        let rect = CGRect(x: 0, y: h / 2 - 60, width: w, height: 100)
        UIColor.systemIndigo.withAlphaComponent(0.08).setFill()
        UIRectFill(rect)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let str = subject as NSString
        let sz = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: (w - sz.width) / 2, y: h / 2 - 20), withAttributes: attrs)

        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let sub = "共 \(count) 道题" as NSString
        let subSz = sub.size(withAttributes: subAttrs)
        sub.draw(at: CGPoint(x: (w - subSz.width) / 2, y: h / 2 + 16), withAttributes: subAttrs)
    }

    // MARK: - Header & Footer

    private static func drawHeader(_ title: String, pageNumber: Int) {
        let w = a4Size.width
        // 细分隔线
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setStrokeColor(UIColor.separator.cgColor)
        ctx?.setLineWidth(0.5)
        ctx?.move(to: CGPoint(x: margin, y: headerH - 4))
        ctx?.addLine(to: CGPoint(x: w - margin, y: headerH - 4))
        ctx?.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.secondaryLabel
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: 14), withAttributes: attrs)
    }

    private static func drawFooter(pageNumber: Int) {
        let w = a4Size.width
        let h = a4Size.height
        let y = h - footerH + 4

        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setStrokeColor(UIColor.separator.cgColor)
        ctx?.setLineWidth(0.5)
        ctx?.move(to: CGPoint(x: margin, y: y - 4))
        ctx?.addLine(to: CGPoint(x: w - margin, y: y - 4))
        ctx?.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let pageStr = "— \(pageNumber) —" as NSString
        let sz = pageStr.size(withAttributes: attrs)
        pageStr.draw(at: CGPoint(x: (w - sz.width) / 2, y: y), withAttributes: attrs)
    }

    // MARK: - Cards Layout

    private static func drawCards(_ cards: [MistakeCard], layout: ExportLayout, kind: ExportKind) {
        let contentRect = CGRect(
            x: margin,
            y: headerH,
            width: a4Size.width - margin * 2,
            height: a4Size.height - headerH - footerH - margin * 0.5
        )
        let gap: CGFloat = 16
        let cellRects: [CGRect]

        switch layout {
        case .one:
            cellRects = [contentRect]
        case .two:
            let height = (contentRect.height - gap) / 2
            cellRects = [
                CGRect(x: contentRect.minX, y: contentRect.minY, width: contentRect.width, height: height),
                CGRect(x: contentRect.minX, y: contentRect.minY + height + gap, width: contentRect.width, height: height)
            ]
        case .four:
            let cw = (contentRect.width - gap) / 2
            let ch = (contentRect.height - gap) / 2
            cellRects = [
                CGRect(x: contentRect.minX,      y: contentRect.minY,      width: cw, height: ch),
                CGRect(x: contentRect.minX + cw + gap, y: contentRect.minY, width: cw, height: ch),
                CGRect(x: contentRect.minX,      y: contentRect.minY + ch + gap, width: cw, height: ch),
                CGRect(x: contentRect.minX + cw + gap, y: contentRect.minY + ch + gap, width: cw, height: ch)
            ]
        }

        for (card, rect) in zip(cards, cellRects) {
            drawCard(card, in: rect, kind: kind)
        }
    }

    private static func drawCard(_ card: MistakeCard, in rect: CGRect, kind: ExportKind) {
        let ctx = UIGraphicsGetCurrentContext()
        // 圆角边框
        ctx?.setStrokeColor(UIColor.separator.cgColor)
        ctx?.setLineWidth(0.75)
        UIBezierPath(roundedRect: rect, cornerRadius: 6).stroke()

        let inset = rect.insetBy(dx: 10, dy: 10)
        let fontSize = layoutFontSize(for: rect)

        // 元数据区（复习版显示，练习版也显示学科标签以便识别）
        let metaH: CGFloat = fontSize + 6
        let metaRect = CGRect(x: inset.minX, y: inset.minY, width: inset.width, height: metaH)
        let subjectAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let subjectStr = [card.subject, card.grade, card.semester]
            .filter { !$0.isEmpty }.joined(separator: " · ")
        (subjectStr as NSString).draw(in: metaRect, withAttributes: subjectAttrs)

        // 图片区
        let answerBlankH: CGFloat = kind == .practice ? max(inset.height * 0.30, 60) : 0
        let reviewMetaH: CGFloat = kind == .review ? min(80, inset.height * 0.26) : 0
        let imageH = inset.height - metaH - 4 - answerBlankH - reviewMetaH - (reviewMetaH > 0 ? 8 : 0)
        let imageRect = CGRect(x: inset.minX, y: inset.minY + metaH + 4, width: inset.width, height: imageH)

        if let img = UIImage(contentsOfFile: card.imageURL.path) {
            let fitted = aspectFit(img.size, inside: imageRect)
            img.draw(in: fitted)
        }

        // 练习版：答题空白区（横线）
        if kind == .practice && answerBlankH > 0 {
            let blankRect = CGRect(
                x: inset.minX,
                y: imageRect.maxY + 4,
                width: inset.width,
                height: answerBlankH
            )
            ctx?.setStrokeColor(UIColor.systemGray4.cgColor)
            ctx?.setLineWidth(0.5)
            let lineSpacing: CGFloat = 18
            var lineY = blankRect.minY + lineSpacing
            while lineY < blankRect.maxY - 4 {
                ctx?.move(to: CGPoint(x: blankRect.minX, y: lineY))
                ctx?.addLine(to: CGPoint(x: blankRect.maxX, y: lineY))
                lineY += lineSpacing
            }
            ctx?.strokePath()
        }

        // 复习版：元数据详情
        if kind == .review && reviewMetaH > 0 {
            let detailRect = CGRect(
                x: inset.minX, y: imageRect.maxY + 8,
                width: inset.width, height: reviewMetaH
            )
            let details = [
                "知识点：\(card.tagsText.isEmpty ? "—" : card.tagsText)",
                "原因：\(card.errorReason)   状态：\(card.status)",
                card.note.isEmpty ? nil : "备注：\(card.note)"
            ].compactMap { $0 }.joined(separator: "\n")

            let para = NSMutableParagraphStyle()
            para.lineSpacing = 2
            (details as NSString).draw(
                in: detailRect,
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: fontSize),
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: para
                ]
            )
        }
    }

    // MARK: - Helpers

    private static func aspectFit(_ size: CGSize, inside rect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return rect }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: rect.midX - fitted.width / 2,
            y: rect.midY - fitted.height / 2,
            width: fitted.width,
            height: fitted.height
        )
    }

    private static func layoutFontSize(for rect: CGRect) -> CGFloat {
        rect.width < 280 ? 8 : 10
    }
}
