//
//  PingDesignSystemImport.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import PingDesignSystem

/// Re-exports the shared design system for every JourneyModuleSample source
/// file, so call sites keep compiling without a per-file
/// `import PingDesignSystem`.
@_exported import PingDesignSystem
