import Foundation

enum TextNormalizer {
    static func normalize(_ text: String) -> String {
        var result = text

        result = removeEmojiTags(from: result)

        result = removeUnicodeEmojis(from: result)

        result = removeMarkdown(from: result)

        result = processTTSSpecialContent(from: result)

        return result
    }

    static func removeEmojiTags(from text: String) -> String {
        do {
            let emojiTagPattern = try NSRegularExpression(pattern: ":[a-zA-Z0-9_+-]+:", options: [])
            return emojiTagPattern.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count), withTemplate: "")
        } catch {
            return text // 如果正则表达式创建失败，返回原文本
        }
    }

    static func removeUnicodeEmojis(from text: String) -> String {
        var result = ""

        for character in text {
            if !character.isEmoji {
                result.append(character)
            }
        }

        return result
    }

    private static func replaceText(_ text: String, pattern: String, options: NSRegularExpression.Options = [], template: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            return regex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count), withTemplate: template)
        } catch {
            return text
        }
    }

    static func removeMarkdown(from text: String) -> String {
        var result = text

        // [text](url)
        result = replaceText(result, pattern: "\\[([^\\]]+)\\]\\([^\\)]+\\)", template: "$1")

        // **text**  __text__
        result = replaceText(result, pattern: "\\*\\*([^\\*]+)\\*\\*", template: "$1")
        result = replaceText(result, pattern: "__([^_]+)__", template: "$1")

        // *text*  _text_
        result = replaceText(result, pattern: "\\*([^\\*]+)\\*", template: "$1")
        result = replaceText(result, pattern: "_([^_]+)_", template: "$1")

        // ```code```  `code`
        result = replaceText(result, pattern: "```(?:.*?\\n)?([^`]+)```", template: "$1")
        result = replaceText(result, pattern: "`([^`]+)`", template: "$1")

        // # Title
        result = replaceText(result, pattern: "^#+\\s+(.*?)$", options: .anchorsMatchLines, template: "$1")

        // - item  * item  1. item
        result = replaceText(result, pattern: "^[\\-\\*\\d\\.]\\s+(.*?)$", options: .anchorsMatchLines, template: "$1")

        return result
    }

    static func processTTSSpecialContent(from text: String) -> String {
        var result = text

        result = replaceText(result, pattern: "<[^>]+>", template: "")

        let specialCharsMap: [String: String] = [
            "&nbsp;": " ",
            "&lt;": "less than",
            "&gt;": "greater than",
            "&amp;": "and",
            "\\n": "\n",
        ]

        for (char, replacement) in specialCharsMap {
            result = result.replacingOccurrences(of: char, with: replacement)
        }

        return result
    }
}

extension Character {
    var isEmoji: Bool {
        if let scalar = unicodeScalars.first, scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
            return true
        }

        let scalars = unicodeScalars
        return scalars.count > 1 &&
            (scalars.first?.properties.isEmoji ?? false) &&
            (scalars.contains { $0.properties.isEmojiPresentation })
    }
}
