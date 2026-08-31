// Views/Components/AccountCardView.swift
import SwiftUI
import PingOneMFA

struct AccountCardView: View {
    let account: PingOneMfaAccount

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [.themeButtonBackground, Color(red: 0.6, green: 0.1, blue: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text("\(account.name) \(account.family)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Region: \(account.region)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text("ID: \(account.id)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
