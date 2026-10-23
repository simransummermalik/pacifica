import SwiftUI

struct AuthView: View {
    @State private var viewModel: AuthViewModel
    @State private var isPasswordVisible = false
    @State private var hasAppeared = false
    @FocusState private var focusedField: Field?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Field {
        case email
        case password
    }

    init(viewModel: AuthViewModel = AuthViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    wordmark
                        .frame(maxWidth: .infinity)
                        .frame(height: max(proxy.size.height / 3, 160))
                        .entrance(hasAppeared, reduceMotion: reduceMotion, delay: 0)

                    VStack(spacing: 12) {
                        fields
                        signInButton
                            .padding(.top, 12)
                        demoButton
                    }
                    .entrance(hasAppeared, reduceMotion: reduceMotion, delay: 0.1)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .frame(minHeight: proxy.size.height)
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(Theme.text)
        .tint(Theme.text)
        .background(AppBackground())
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .sensoryFeedback(.warning, trigger: viewModel.failedAttempts)
        .onAppear { hasAppeared = true }
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        VStack(spacing: 8) {
            Text("Pacifica")
                .font(.title2.weight(.bold))
            Text("Dive in. Compete. Get hooked.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Fields

    private var fields: some View {
        VStack(alignment: .leading, spacing: 12) {
            AuthField(systemImage: "envelope") {
                TextField("Email", text: $viewModel.email, prompt: prompt("Email"))
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
                    .accessibilityLabel("Email")
            }

            AuthField(systemImage: "lock") {
                Group {
                    if isPasswordVisible {
                        TextField("Password", text: $viewModel.password, prompt: prompt("Password"))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Password", text: $viewModel.password, prompt: prompt("Password"))
                    }
                }
                .textContentType(.password)
                .submitLabel(.go)
                .focused($focusedField, equals: .password)
                .onSubmit(submit)
                .accessibilityLabel("Password")
            } trailing: {
                Button {
                    isPasswordVisible.toggle()
                    focusedField = .password
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            }
        }
        .disabled(viewModel.isSigningIn)
        .shake(trigger: viewModel.failedAttempts)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
    }

    private func prompt(_ text: String) -> Text {
        Text(text).foregroundStyle(.secondary)
    }

    // MARK: - Buttons

    private var signInButton: some View {
        Button(action: submit) {
            ZStack {
                Text("Sign in")
                    .opacity(viewModel.isSigningIn ? 0 : 1)
                if viewModel.isSigningIn {
                    ProgressView()
                        .tint(Theme.surface)
                }
            }
        }
        .buttonStyle(PillButtonStyle(fill: Theme.text, foreground: Theme.surface, font: .title3.weight(.semibold)))
        // Dimmed until both fields have text; stays full strength (but inert) while signing in.
        .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
        .allowsHitTesting(!viewModel.isSigningIn)
    }

    private var demoButton: some View {
        Button("Use demo account") {
            viewModel.useDemoAccount()
            focusedField = .password
        }
        .font(.subheadline.weight(.semibold))
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .disabled(viewModel.isSigningIn)
    }

    private func submit() {
        focusedField = nil
        Task { await viewModel.signIn() }
    }
}

// MARK: - Field container

/// Rounded field in the Home screen's glass card style.
private struct AuthField<Content: View, Trailing: View>: View {
    let systemImage: String
    let content: Content
    let trailing: Trailing

    init(
        systemImage: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.content = content()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 24)
            content
                .font(.body)
            trailing
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .frame(minHeight: 56)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

// MARK: - Entrance animation

private extension View {
    /// Fades in with a slight upward move; with Reduce Motion it only fades.
    func entrance(_ isVisible: Bool, reduceMotion: Bool, delay: Double) -> some View {
        opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 16)
            .animation(.easeOut(duration: 0.5).delay(delay), value: isVisible)
    }
}

#if DEBUG
#Preview("Empty") {
    AuthView(viewModel: .preview(email: ""))
}

#Preview("Filled") {
    AuthView(viewModel: .preview(password: "example-password"))
}

#Preview("Loading") {
    AuthView(viewModel: .preview(password: "example-password", isSigningIn: true))
}

#Preview("Error") {
    AuthView(viewModel: .preview(password: "example-password", errorMessage: "Invalid login credentials"))
}
#endif
