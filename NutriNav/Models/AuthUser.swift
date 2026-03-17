//
//  AuthUser.swift
//  NutriNav
//
//  Model representing an authenticated user via Apple Sign In
//

import Foundation

struct AuthUser: Codable, Identifiable {
    let id: String              // Apple userIdentifier (stable)
    let email: String?          // Only available on first sign in
    let fullName: String?       // Only available on first sign in
}
