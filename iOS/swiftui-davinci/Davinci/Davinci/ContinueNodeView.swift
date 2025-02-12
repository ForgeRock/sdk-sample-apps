// 
//  ContinueNodeView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOrchestrate
import PingDavinci

struct ContinueNodeView: View {
    var continueNode: ContinueNode
    let onNodeUpdated: () -> Void
    let onStart: () -> Void
    let onNext: (Bool) -> Void
    
    @EnvironmentObject var validationViewModel: ValidationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(continueNode.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(Color.gray)
            Text(continueNode.description)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(Color.gray)
            
            Divider()
            
            ForEach(continueNode.collectors , id: \.id) { collector in
                switch collector {
                case is FlowCollector:
                    if let flowCollector = collector as? FlowCollector {
                        FlowButtonView(field: flowCollector, onNext: onNext)
                    }
                case is PasswordCollector:
                    if let passwordCollector = collector as? PasswordCollector {
                        PasswordView(field: passwordCollector, onNodeUpdated: onNodeUpdated)
                    }
                case is SubmitCollector:
                    if let submitCollector = collector as? SubmitCollector {
                        SubmitButtonView(field: submitCollector, onNext: onNext)
                    }
                case is TextCollector:
                    if let textCollector = collector as? TextCollector {
                        TextView(field: textCollector, onNodeUpdated: onNodeUpdated)
                    }
                case is LabelCollector:
                    if let labelCollector = collector as? LabelCollector {
                        LabelView(field: labelCollector)
                    }
                case is MultiSelectCollector:
                    if let multiSelectCollector = collector as? MultiSelectCollector {
                        if multiSelectCollector.type == "COMBOBOX" {
                            ComboBoxView(field: multiSelectCollector, onNodeUpdated: onNodeUpdated)
                        } else {
                            CheckBoxView(field: multiSelectCollector, onNodeUpdated: onNodeUpdated)
                        }
                    }
                case is SingleSelectCollector:
                    if let singleSelectCollector = collector as? SingleSelectCollector {
                        if singleSelectCollector.type == "DROPDOWN" {
                            DropdownView(field: singleSelectCollector, onNodeUpdated: onNodeUpdated)
                        } else {
                            RadioButtonView(field: singleSelectCollector, onNodeUpdated: onNodeUpdated)
                        }
                    }
                default:
                    EmptyView()
                }
            }
            
            // Fallback Next Button
            if !continueNode.collectors.contains(where: { $0 is FlowCollector || $0 is SubmitCollector }) {
                Button(action: { onNext(false) }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeButtonBackground)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
            }
        }
        .padding()
    }
}
