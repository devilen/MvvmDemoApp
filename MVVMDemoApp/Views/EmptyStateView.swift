import SwiftUI

struct EmptyStateView: View {
    let title: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
