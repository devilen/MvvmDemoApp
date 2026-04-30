import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.red)
            Button("重试", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
