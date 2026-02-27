//
//  Color+Theme.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

extension Color {
    /// Ping Identity brand red — used for primary buttons and interactive elements.
    static var themeButtonBackground: Color {
        Color(red: 163.0/255.0, green: 19.0/255.0, blue: 0.0/255.0)
    }

    static var themeTextField: Color {
        Color(red: 220.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, opacity: 1.0)
    }

    static var googleButtonBackground: Color {
        Color(red: 163.0/255.0, green: 19.0/255.0, blue: 0.0/255.0)
    }

    static var appleButtonBackground: Color {
        Color(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0)
    }

    static var facebookButtonBackground: Color {
        Color(red: 0.0/255.0, green: 128.0/255.0, blue: 255.0/255.0)
    }
}
