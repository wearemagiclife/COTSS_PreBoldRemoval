import Foundation
import AuthenticationServices

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isSignedIn: Bool = false
    @Published var userIdentifier: String = ""
    @Published var fullName: PersonNameComponents?
    @Published var email: String?
    
    // Keys for UserDefaults
    private let userIdentifierKey = "com.yourapp.userIdentifier"
    private let userFullNameKey = "com.yourapp.userFullName"
    private let userEmailKey = "com.yourapp.userEmail"
    private let isSignedInKey = "com.yourapp.isSignedIn"
    
    private init() {
        // Check for existing authentication on initialization
        restoreAuthenticationState()
    }
    
    /// Restore authentication state from UserDefaults
    private func restoreAuthenticationState() {
        // Check if user was previously signed in
        let wasSignedIn = UserDefaults.standard.bool(forKey: isSignedInKey)
        
        // Restore user identifier if it exists
        if let storedUserIdentifier = UserDefaults.standard.string(forKey: userIdentifierKey),
           !storedUserIdentifier.isEmpty,
           wasSignedIn {
            
            self.userIdentifier = storedUserIdentifier
            self.email = UserDefaults.standard.string(forKey: userEmailKey)
            
            // Restore full name if it was stored
            if let fullNameData = UserDefaults.standard.data(forKey: userFullNameKey),
               let decodedFullName = try? JSONDecoder().decode(PersonNameComponents.self, from: fullNameData) {
                self.fullName = decodedFullName
            }
            
            // Set signed in state
            DispatchQueue.main.async {
                self.isSignedIn = true
            }
        }
    }
    
    /// Handle Sign in with Apple authorization result
    func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Extract and store user information
                let userIdentifier = appleIDCredential.user
                
                // Store in memory
                self.userIdentifier = userIdentifier
                
                // Store full name if available (only provided on first sign-in)
                if let fullName = appleIDCredential.fullName,
                   (fullName.givenName != nil || fullName.familyName != nil) {
                    self.fullName = fullName
                    
                    // Persist full name
                    if let encoded = try? JSONEncoder().encode(fullName) {
                        UserDefaults.standard.set(encoded, forKey: userFullNameKey)
                    }
                }
                
                // Store email if available
                if let email = appleIDCredential.email {
                    self.email = email
                    UserDefaults.standard.set(email, forKey: userEmailKey)
                }
                
                // Persist authentication state
                UserDefaults.standard.set(userIdentifier, forKey: userIdentifierKey)
                UserDefaults.standard.set(true, forKey: isSignedInKey)
                UserDefaults.standard.synchronize()
                
                // Update signed-in state
                DispatchQueue.main.async {
                    self.isSignedIn = true
                }
            }
            
        case .failure:
            DispatchQueue.main.async {
                self.isSignedIn = false
            }
        }
    }
    
    /// Check the user's authentication state with Apple
    /// This can be called to verify if the user's Apple ID credentials are still valid
    func checkAuthenticationState() {
        guard !userIdentifier.isEmpty else {
            DispatchQueue.main.async {
                self.isSignedIn = false
            }
            return
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: userIdentifier) { [weak self] (credentialState, error) in
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid
                DispatchQueue.main.async {
                    self?.isSignedIn = true
                }
                
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or was not found
                DispatchQueue.main.async {
                    self?.signOut()
                }
                
            case .transferred:
                // The app was transferred to another team
                DispatchQueue.main.async {
                    self?.signOut()
                }
                
            default:
                break
            }
        }
    }
    
    /// Sign out the user and clear all stored authentication data
    func signOut() {
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: userIdentifierKey)
        UserDefaults.standard.removeObject(forKey: userFullNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.set(false, forKey: isSignedInKey)
        UserDefaults.standard.synchronize()
        
        // Clear in-memory data
        userIdentifier = ""
        fullName = nil
        email = nil
        
        // Update signed-in state
        DispatchQueue.main.async {
            self.isSignedIn = false
        }
    }
    
    /// Get the user's display name
    var displayName: String {
        if let fullName = fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            return formatter.string(from: fullName)
        }
        return email ?? "User"
    }
}
