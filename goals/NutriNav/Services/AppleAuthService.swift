//
//  AppleAuthService.swift
//  NutriNav
//
//  Handles Sign in with Apple logic, Keychain persistence, and session validation
//

import Foundation
import AuthenticationServices
import Security
import Combine

class AppleAuthService: NSObject, AuthService, ObservableObject {
    @Published var currentUser: AuthUser?
    
    // Keychain keys
    private let userIdentifierKey = "appleUserIdentifier"
    private let emailKey = "appleUserEmail"
    private let fullNameKey = "appleUserFullName"
    
    // Authorization Controller Reference
    private var activeController: ASAuthorizationController?
    
    override init() {
        super.init()
    }
    
    // MARK: - AuthService Implementation
    
    func checkCredentialState() async {
        guard let userIdentifier = getFromKeychain(key: userIdentifierKey) else {
            return
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        do {
            let credentialState = try await appleIDProvider.credentialState(forUserID: userIdentifier)
            switch credentialState {
            case .authorized:
                // User is authorized, restore session
                let email = getFromKeychain(key: emailKey)
                let fullName = getFromKeychain(key: fullNameKey)
                
                await MainActor.run {
                    self.currentUser = AuthUser(id: userIdentifier, email: email, fullName: fullName)
                }
            case .revoked, .notFound, .transferred:
                // Credential no longer valid
                signOut()
            @unknown default:
                signOut()
            }
        } catch {
            print("Error checking credential state: \(error)")
            // On error specifically related to network/system, maybe don't sign out immediately?
            // But safely, if we can't verify, we shouldn't assume authorized for critical actions.
            // For now, let's keep the existing session if it was just a network blip?
            // "If you cannot access the credential state ... treat the user as logged out" is safest.
            signOut()
        }
    }
    
    func signInWithApple() async throws -> AuthUser {
        print("DEBUG: signInWithApple called")
        return try await withCheckedThrowingContinuation { continuation in
            print("DEBUG: Creating request")
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            
            // Retain controller to prevent deallocation
            self.activeController = controller
            
            // Create a delegate helper to handle the callback
            let delegate = AppleSignInDelegate(continuation: continuation, service: self)
            // Retain the delegate strongly so it doesn't vanish
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            controller.delegate = delegate
            controller.presentationContextProvider = delegate // Assuming we implement this too
            print("DEBUG: Performing requests")
            controller.performRequests()
        }
    }
    
    func signOut() {
        // Clear Keychain
        removeFromKeychain(key: userIdentifierKey)
        removeFromKeychain(key: emailKey)
        removeFromKeychain(key: fullNameKey)
        
        // Update State
        Task { @MainActor in
            self.currentUser = nil
        }
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func removeFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    fileprivate func handleAuthorizationSuccess(authorization: ASAuthorization, continuation: CheckedContinuation<AuthUser, Error>) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            
            // Email and Name are only available on first login
            let email = appleIDCredential.email
            var fullName: String?
            if let nameComponents = appleIDCredential.fullName {
                fullName = PersonNameComponentsFormatter().string(from: nameComponents)
            }
            
            // Persist data
            saveToKeychain(key: userIdentifierKey, value: userIdentifier)
            if let email = email {
                saveToKeychain(key: emailKey, value: email)
            }
            if let fullName = fullName {
                saveToKeychain(key: fullNameKey, value: fullName)
            }
            // If email/name missing (returning user), try to fetch from Keychain if we had it?
            // But we might be re-installing. We only really need userIdentifier.
            
            let user = AuthUser(id: userIdentifier, email: email, fullName: fullName)
            
            Task { @MainActor in
                self.currentUser = user
            }
            
            // TODO: Create or fetch User record in CloudKit using appleUserID
            
            continuation.resume(returning: user)
        } else {
            continuation.resume(throwing: NSError(domain: "AppleAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
        }
    }
    
    fileprivate func handleAuthorizationFailure(error: Error, continuation: CheckedContinuation<AuthUser, Error>) {
        continuation.resume(throwing: error)
    }
}

// MARK: - Delegate Helper

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<AuthUser, Error>
    private weak var service: AppleAuthService?
    
    init(continuation: CheckedContinuation<AuthUser, Error>, service: AppleAuthService) {
        self.continuation = continuation
        self.service = service
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("DEBUG: Delegate didCompleteWithAuthorization")
        service?.handleAuthorizationSuccess(authorization: authorization, continuation: continuation)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("DEBUG: Delegate didCompleteWithError: \(error)")
        service?.handleAuthorizationFailure(error: error, continuation: continuation)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("DEBUG: presentationAnchor requested")
        // Return key window using SceneDelegate logic appropriately or a window finder
        // For SwiftUI, getting the window can be tricky.
        // A common workaround is searching UIApplication scenes.
        
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.compactMap { $0 as? UIWindowScene }.first
        let window = windowScene?.windows.first { $0.isKeyWindow }
        
        if let window = window {
             print("DEBUG: Found valid window: \(window)")
             return window
        } else {
             print("DEBUG: No valid window found, creating temporary empty window (FAIL)")
             return UIWindow()
        }
    }
}
