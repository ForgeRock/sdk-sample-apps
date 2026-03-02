//
//  DeleteType.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

/// Represents which credential types should be deleted when an account has both OATH and Push.
enum DeleteType {
    case oathOnly, pushOnly, both
}
