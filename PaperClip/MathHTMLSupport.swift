import Foundation

func formatted(_ value: String) -> String {
    let html = escaped(value)
        .replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
    return replaceNewlinesOutsideMath(in: html)
}

/// 将换行符（真实 0x0A 或 fixUnescapedBackslashes 后的字面量 \n）替换为 <br>，
/// 但在 $...$ 数学范围内保留，供 KaTeX 识别 \neq 等命令。
func replaceNewlinesOutsideMath(in text: String) -> String {
    var result = ""
    result.reserveCapacity(text.count + 64)
    var inMath = false
    var i = text.startIndex

    while i < text.endIndex {
        let ch = text[i]
        let next = text.index(after: i)

        if ch == "$" {
            inMath.toggle()
            result.append(ch)
        } else if inMath {
            result.append(ch)
        } else if ch == "\n" {
            result.append(contentsOf: "<br>")
        } else if ch == "\\" && next < text.endIndex && text[next] == "n" {
            // 字面量 \n（来自双重转义后的 JSON 换行符），数学范围外视为换行
            result.append(contentsOf: "<br>")
            i = next
        } else {
            result.append(ch)
        }

        i = text.index(after: i)
    }

    return result
}

func escaped(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}
