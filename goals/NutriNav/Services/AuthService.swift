//
//  AuthService.swift
//  NutriNav
//
//  Protocol defining authentication requirements
//

import Foundation

protocol AuthService {
    /// Validates existing credentials and restores session if valid
    func checkCredentialState() async
    
    /// Initiates Sign in with Apple flow
    func signInWithApple() async throws -> AuthUser
    
    /// Signs out the user and clears persistence
    func signOut()
    
    /// Current authenticated user
    var currentUser: AuthUser? { get }
}
