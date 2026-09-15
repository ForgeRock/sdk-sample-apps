//
//  RichTextBuilder.swift
//  Davinci
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingDavinci

enum RichTextBuilder {
    static func build(from richContent: RichContent) -> AttributedString {
        let template = richContent.content
        var result = AttributedString()

        var remaining = template[template.startIndex...]

        while let openRange = remaining.range(of: "{{") {
            let prefix = String(remaining[remaining.startIndex..<openRange.lowerBound])
            result.append(AttributedString(prefix))

            let afterOpen = openRange.upperBound
            guard let closeRange = remaining[afterOpen...].range(of: "}}") else {
                result.append(AttributedString(String(remaining[openRange.lowerBound...])))
                remaining = remaining[remaining.endIndex...]
                break
            }

            let placeholderKey = String(remaining[afterOpen..<closeRange.lowerBound])

            if let replacement = richContent.replacements[placeholderKey] {
                if replacement.type == "link", let href = replacement.href {
                    if let url = URL(string: href) {
                        var linkText = AttributedString(replacement.value)
                        linkText.link = url
                        linkText.foregroundColor = PingTheme.Color.actionPrimary
                        result.append(linkText)
                    } else {
                        // Server returned a malformed URL; render as plain text so content is not lost.
                        assertionFailure("RichTextBuilder: invalid URL from server: \(href)")
                        result.append(AttributedString(replacement.value))
                    }
                } else {
                    result.append(AttributedString(replacement.value))
                }
            } else {
                result.append(AttributedString("{{\(placeholderKey)}}"))
            }

            remaining = remaining[closeRange.upperBound...]
        }

        if !remaining.isEmpty {
            result.append(AttributedString(String(remaining)))
        }

        return result
    }
}
