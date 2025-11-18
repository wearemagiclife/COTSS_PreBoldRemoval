import SwiftUI
import AuthenticationServices

struct ProfileSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var birthDate = Date()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showDatePicker: Bool = true
    @State private var isSaving = false
    
    private let fieldBackgroundColor = Color(red: 0.95, green: 0.90, blue: 0.78)
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthDate)
    }
    
    private func isValidBirthdate(_ date: Date) -> Bool {
        return date <= Date()
    }
    
    private func saveAndDismiss() {
        if isValidBirthdate(birthDate) {
            if dataManager.updateProfile(name: name, birthDate: birthDate) {
                dataManager.explorationDate = nil
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            errorMessage = "Invalid birth date. Please check that the date is not in the future."
            showingError = true
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let isSmallScreen = geometry.size.height < 700

                ZStack {
                    AppTheme.backgroundColor
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: isSmallScreen ? 15 : 30) {
                        // Guest mode message
                        if dataManager.isGuestMode {
                            VStack(spacing: 20) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .padding(.top, 40)

                                Text("Guest Account")
                                    .font(.custom("Iowan Old Style", size: 22))
                                    .foregroundColor(AppTheme.primaryText)

                                Text("Profile editing is not available for guest users. Sign in with Apple to save your profile and access all features.")
                                    .font(.custom("Iowan Old Style", size: 16))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)

                                Text("Birthday: \(formattedDate)")
                                    .font(.custom("Iowan Old Style", size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding(.top, 10)

                                SignInWithAppleButton(
                                    .signIn,
                                    onRequest: { request in
                                        request.requestedScopes = [.email, .fullName]
                                    },
                                    onCompletion: { result in
                                        authManager.handleAuthorization(result)
                                        if case .success = result {
                                            dataManager.isGuestMode = false
                                            // Keep the birthday from guest mode
                                            let guestBirthday = dataManager.userProfile.birthDate
                                            birthDate = guestBirthday
                                        }
                                    }
                                )
                                .signInWithAppleButtonStyle(.black)
                                .frame(height: 44)
                                .frame(width: 240)
                                .cornerRadius(8)
                                .padding(.top, 20)
                            }
                            .padding(.bottom, 40)
                        }

                        // Apple ID Info Section (if signed in)
                        if !dataManager.isGuestMode && authManager.isSignedIn && (authManager.email != nil || authManager.displayName != "User") {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Apple ID")
                                    .font(.custom("Iowan Old Style", size: 22))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    if authManager.displayName != "User" {
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(AppTheme.secondaryText)
                                                .accessibilityHidden(true)
                                            Text(authManager.displayName)
                                                .font(.custom("Iowan Old Style", size: 16))
                                                .foregroundColor(AppTheme.primaryText)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("Name: \(authManager.displayName)")
                                    }
                                    if let email = authManager.email, !email.isEmpty {
                                        HStack {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(AppTheme.secondaryText)
                                                .accessibilityHidden(true)
                                            Text(email)
                                                .font(.custom("Iowan Old Style", size: 16))
                                                .foregroundColor(AppTheme.primaryText)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("Email: \(email)")
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(fieldBackgroundColor)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                        
                        if !dataManager.isGuestMode {
                            VStack(alignment: .center, spacing: 10) {
                                Text("Profile Name")
                                    .font(.custom("Iowan Old Style", size: 22))
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding(.top, authManager.isSignedIn ? 0 : 20)

                                TextField("Enter your name", text: $name)
                                    .font(.custom("Iowan Old Style", size: 20))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(fieldBackgroundColor)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                                    .accessibilityLabel("Profile Name")
                            }
                            .padding(.horizontal)
                        }

                        if !dataManager.isGuestMode {
                            VStack(spacing: 15) {
                                Text("Birth Date")
                                    .font(.custom("Iowan Old Style", size: 22))
                                    .foregroundColor(AppTheme.primaryText)

                                Text(formattedDate)
                                    .font(.custom("Iowan Old Style", size: 20))
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(fieldBackgroundColor)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                                    .padding(.horizontal, 50)

                                DatePicker("", selection: $birthDate, displayedComponents: .date)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(fieldBackgroundColor)
                                    )
                                    .padding(.horizontal)
                                    .accessibilityLabel("Birth Date")
                                    .accessibilityHint("Select your birth date")
                            }

                            Button {
                                saveAndDismiss()
                            } label: {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    }
                                    Text(isSaving ? "Saving..." : "Save Changes")
                                        .font(.custom("Iowan Old Style", size: 19))
                                        .tracking(0.5)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 50)
                                .padding(.vertical, 18)
                                .background(AppTheme.darkAccent.opacity(0.7))
                                .cornerRadius(30)
                                .multilineTextAlignment(.center)
                            }
                            .disabled(isSaving)
                            .accessibilityLabel("Save Changes")
                            .accessibilityHint("Saves profile information and closes the sheet")
                            .padding(.horizontal)
                        }

                    }
                    .padding()
                }
            }
            }
            .onAppear {
                name = dataManager.userProfile.name
                birthDate = dataManager.userProfile.birthDate
            }
            .alert("Invalid Birth Date", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview("Profile Sheet") {
    ProfileSheet()
}
