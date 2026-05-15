import SwiftUI
import AuthenticationServices

struct ProfileSheet: View {
    var onDismissAll: (() -> Void)? = nil

    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var authManager = AuthenticationManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var birthDate = Date()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var dateText = ""
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @FocusState private var isTextFieldFocused: Bool

    private let fieldBackground = AppConstants.Colors.capsuleButton

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMddyyyy")
        return formatter
    }

    private var formattedDate: String { dateFormatter.string(from: birthDate) }

    private var localizedPlaceholder: String {
        let pattern = dateFormatter.dateFormat ?? "MM/dd/yyyy"
        return pattern
            .replacingOccurrences(of: "MM", with: "MM")
            .replacingOccurrences(of: "dd", with: "DD")
            .replacingOccurrences(of: "yyyy", with: "YYYY")
            .replacingOccurrences(of: "M", with: "M")
            .replacingOccurrences(of: "d", with: "D")
    }

    private func parseDate(_ text: String) -> Date? { dateFormatter.date(from: text) }
    private func isValidBirthdate(_ date: Date) -> Bool { date <= Date() }

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
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { presentationMode.wrappedValue.dismiss() }

            NavigationView {
                ZStack {
                    AppTheme.backgroundColor.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: AppConstants.Spacing.cardPadding) {

                            // MARK: - Guest Mode
                            if dataManager.isGuestMode {
                                VStack(spacing: AppConstants.Spacing.cardPadding) {
                                    Image(systemName: "person.crop.circle.badge.questionmark")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.secondaryText)
                                        .padding(.top, AppConstants.Spacing.section)

                                    Text("Guest Account")
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline))
                                        .foregroundColor(AppTheme.primaryText)

                                    Text("Profile editing is not available for guest users. Sign in with Apple to save your profile and access all features.")
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                                        .foregroundColor(AppTheme.secondaryText)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(4)

                                    Text("Birthday: \(formattedDate)")
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                                        .foregroundColor(AppTheme.primaryText)
                                        .padding(.top, 4)

                                    SignInWithAppleButton(
                                        .signIn,
                                        onRequest: { request in
                                            request.requestedScopes = [.email, .fullName]
                                        },
                                        onCompletion: { result in
                                            authManager.handleAuthorization(result)
                                            if case .success = result {
                                                dataManager.isGuestMode = false
                                                birthDate = dataManager.userProfile.birthDate
                                            }
                                        }
                                    )
                                    .signInWithAppleButtonStyle(.black)
                                    .frame(height: 40)
                                    .frame(width: 220)
                                    .cornerRadius(8)
                                    .overlay(AnimatedGoldBorder(cornerRadius: 8))
                                    .padding(.top, AppConstants.Spacing.tight)
                                }
                                .padding(.bottom, AppConstants.Spacing.section)
                            }

                            // MARK: - Profile Name
                            if !dataManager.isGuestMode {
                                VStack(alignment: .leading, spacing: AppConstants.Spacing.ornament) {
                                    Text("Profile Name")
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                        .foregroundColor(AppTheme.primaryText)

                                    TextField("Enter your name", text: $name)
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                                        .padding(AppConstants.Spacing.tight)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(fieldBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                                        )
                                        .accessibilityLabel("Profile Name")
                                }
                            }

                            // MARK: - Birth Date
                            if !dataManager.isGuestMode {
                                VStack(alignment: .leading, spacing: AppConstants.Spacing.ornament) {
                                    Text("Birth Date")
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                        .foregroundColor(AppTheme.primaryText)

                                    TextField(localizedPlaceholder, text: $dateText)
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                                        .foregroundColor(AppTheme.primaryText)
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.numbersAndPunctuation)
                                        .focused($isTextFieldFocused)
                                        .padding(AppConstants.Spacing.tight)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(fieldBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                                        )
                                        .onChange(of: dateText) { _, newValue in
                                            if let date = parseDate(newValue) { birthDate = date }
                                        }

                                    DatePicker("", selection: $birthDate, displayedComponents: .date)
                                        .datePickerStyle(WheelDatePickerStyle())
                                        .labelsHidden()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(fieldBackground)
                                        )
                                        .accessibilityLabel("Birth Date")
                                        .accessibilityHint("Select your birth date")
                                        .onChange(of: birthDate) { _, _ in
                                            if !isTextFieldFocused { dateText = formattedDate }
                                        }
                                }

                                Button {
                                    saveAndDismiss()
                                } label: {
                                    HStack {
                                        if isSaving {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(AppTheme.accentText)
                                        }
                                        Text(isSaving ? "Saving..." : "Save Changes")
                                            .font(.custom("Iowan Old Style", size: 19))
                                            .tracking(0.5)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                }
                                .buttonStyle(GoldButtonStyle())
                                .disabled(isSaving)
                                .accessibilityLabel("Save Changes")
                            }

                            // MARK: - Sign Out / Delete Account
                            VStack(spacing: AppConstants.Spacing.tight) {
                                Button {
                                    showingSignOutAlert = true
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text(dataManager.isGuestMode ? "Exit Guest Mode" : "Sign Out")
                                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                                    }
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(fieldBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(AppTheme.primaryText.opacity(0.12), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                if !dataManager.isGuestMode {
                                    Button {
                                        showingDeleteAccountAlert = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete Account")
                                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                                        }
                                        .foregroundColor(.red.opacity(0.85))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(fieldBackground)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .stroke(Color.red.opacity(0.20), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, AppConstants.Spacing.tight)

                        }
                        .padding(.horizontal, AppConstants.Spacing.cardPadding)
                        .padding(.top, AppConstants.Spacing.tight)
                        .padding(.bottom, AppConstants.Spacing.section)
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(width: AppConstants.ButtonSizes.closeButton, height: AppConstants.ButtonSizes.closeButton)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close profile")
                    }
                }
                .toolbarBackground(AppTheme.backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
            .background(AppTheme.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal))
            .shadow(color: Color(red: 1.0, green: 0.95, blue: 0.88).opacity(0.12), radius: 120, x: 0, y: 0)
            .padding(.horizontal, AppConstants.Spacing.pageInset)
            .padding(.bottom, AppConstants.Spacing.pageInset)
            .padding(.top, safeAreaTop + AppConstants.Spacing.pageInset)
        }
        .presentationBackground(.clear)
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
        .alert(dataManager.isGuestMode ? "Exit Guest Mode?" : "Sign Out?", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button(dataManager.isGuestMode ? "Exit Guest Mode" : "Sign Out", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
                authManager.signOut()
                DataManager.shared.clearProfile()
                onDismissAll?()
            }
        } message: {
            Text(dataManager.isGuestMode
                 ? "This will return you to the sign-in screen."
                 : "You will be signed out and returned to the sign-in screen.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
                authManager.deleteAccount()
                onDismissAll?()
            }
        } message: {
            Text("This will permanently delete your account and all associated data — including your profile, preferences, and card history. This action cannot be undone.")
        }
    }
}

#Preview("Profile Sheet") {
    ProfileSheet()
}
