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
    @State private var dateText = ""
    @FocusState private var isTextFieldFocused: Bool

    private let fieldBackgroundColor = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1.0)  // dark tan (matches AppTheme.cardBackground)
            : UIColor(red: 0.97, green: 0.95, blue: 0.92, alpha: 1.0)  // soft off-white
    })

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMddyyyy")
        return formatter
    }

    private var formattedDate: String {
        return dateFormatter.string(from: birthDate)
    }

    private var localizedPlaceholder: String {
        let pattern = dateFormatter.dateFormat ?? "MM/dd/yyyy"
        return pattern
            .replacingOccurrences(of: "MM", with: "MM")
            .replacingOccurrences(of: "dd", with: "DD")
            .replacingOccurrences(of: "yyyy", with: "YYYY")
            .replacingOccurrences(of: "M", with: "M")
            .replacingOccurrences(of: "d", with: "D")
    }

    private func parseDate(_ text: String) -> Date? {
        return dateFormatter.date(from: text)
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
                            VStack(spacing: AppConstants.Spacing.cardPadding) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .padding(.top, AppConstants.Spacing.page)

                                Text("Guest Account")
                                    .font(.custom("Iowan Old Style", size: 22))
                                    .foregroundColor(AppTheme.primaryText)

                                Text("Profile editing is not available for guest users. Sign in with Apple to save your profile and access all features.")
                                    .font(.custom("Iowan Old Style", size: 16))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, AppConstants.Spacing.section)

                                Text("Birthday: \(formattedDate)")
                                    .font(.custom("Iowan Old Style", size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding(.top, AppConstants.Spacing.tight)

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
                                .overlay(
                                    AnimatedGoldBorder(cornerRadius: 8)
                                )
                                .padding(.top, AppConstants.Spacing.cardPadding)
                            }
                            .padding(.bottom, AppConstants.Spacing.page)
                        }

                        // Apple ID Info Section (if signed in)
                        if !dataManager.isGuestMode && authManager.isSignedIn && (authManager.email != nil || authManager.displayName != "User") {
                            VStack(alignment: .leading, spacing: AppConstants.Spacing.ornament) {
                                Text("Apple ID")
                                    .font(.custom("Iowan Old Style", size: 22))
                                    .foregroundColor(AppTheme.primaryText)

                                VStack(alignment: .leading, spacing: AppConstants.Spacing.tight) {
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
                            .padding(.top, AppConstants.Spacing.cardPadding)
                        }

                        if !dataManager.isGuestMode {
                            VStack(alignment: .center, spacing: AppConstants.Spacing.tight) {
                                Text("Profile Name")
                                    .font(.custom("Iowan Old Style", size: 22))
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding(.top, authManager.isSignedIn ? AppConstants.Spacing.section : AppConstants.Spacing.page)

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
                            VStack(spacing: AppConstants.Spacing.ornament) {
                                Text("Birth Date")
                                    .font(.custom("Iowan Old Style", size: 22))
                                    .foregroundColor(AppTheme.primaryText)

                                TextField(localizedPlaceholder, text: $dateText)
                                    .font(.custom("Iowan Old Style", size: 20))
                                    .foregroundColor(AppTheme.primaryText)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numbersAndPunctuation)
                                    .focused($isTextFieldFocused)
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
                                    .padding(.horizontal, AppConstants.Spacing.page)
                                    .onChange(of: dateText) { _, newValue in
                                        if let date = parseDate(newValue) {
                                            birthDate = date
                                        }
                                    }

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
                                    .onChange(of: birthDate) { _, _ in
                                        if !isTextFieldFocused {
                                            dateText = formattedDate
                                        }
                                    }
                            }

                            Button {
                                saveAndDismiss()
                            } label: {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(Color(UIColor { traitCollection in
                                                traitCollection.userInterfaceStyle == .dark
                                                    ? UIColor.black
                                                    : UIColor.white
                                            }))
                                    }
                                    Text(isSaving ? "Saving..." : "Save Changes")
                                        .font(.custom("Iowan Old Style", size: 19))
                                        .tracking(0.5)
                                        .foregroundColor(Color(UIColor { traitCollection in
                                            traitCollection.userInterfaceStyle == .dark
                                                ? UIColor.black
                                                : UIColor.white
                                        }))
                                }
                                .padding(.horizontal, 50)
                                .padding(.vertical, 18)
                                .background(AppTheme.darkAccent)
                                .cornerRadius(30)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
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
                dateText = formattedDate
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
