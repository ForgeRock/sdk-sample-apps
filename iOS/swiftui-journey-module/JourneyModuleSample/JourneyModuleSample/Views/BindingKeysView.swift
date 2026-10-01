//
//  BindingKeysView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingBinding

struct BindingKeysView: View {
    @StateObject private var viewModel = BindingKeysViewModel()
    
    var body: some View {
        VStack {
            if viewModel.userKeys.isEmpty {
                EmptyStateView(
                    icon: "key.slash",
                    title: "No Binding Keys Found"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.userKeys) { key in
                        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                            Text("User ID: \(key.userId)")
                                .pingSectionHeader()
                            Text("Key Tag: \(key.keyTag)")
                                .pingSupportingText()
                            Text("Auth Type: \(key.authType.rawValue)")
                                .font(PingTheme.Typography.caption)
                                .padding(PingTheme.Spacing.xSmall)
                                .background(PingTheme.Color.actionPrimary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: PingTheme.Shape.fieldRadius))
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: delete)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .pingScreenBackground()
        .navigationTitle("Binding Keys")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Delete All", role: .destructive) {
                    Task {
                        await viewModel.deleteAllKeys()
                    }
                }
                .disabled(viewModel.userKeys.isEmpty)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchKeys()
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let key = viewModel.userKeys[index]
                await viewModel.deleteKey(key: key)
            }
        }
    }
}

struct BindingKeysView_Previews: PreviewProvider {
    static var previews: some View {
        BindingKeysView()
    }
}
