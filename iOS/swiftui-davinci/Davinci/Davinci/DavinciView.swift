//
//  DavinciView.swift
//  Davinci
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import SwiftUI
import PingOrchestrate
import PingDavinci

/// The main view for orchestrating the Davinci flow.
struct DavinciView: View {
  /// The view model that manages the Davinci flow logic.
  @StateObject private var davinciViewModel =  DavinciViewModel()
  /// A binding to the navigation stack path.
  @Binding var path: [String]
  
  var body: some View {
    ZStack {
      ScrollView {
        VStack {
          Spacer()
          // Handle different types of nodes in the flow.
          switch davinciViewModel.data.currentNode {
          case let nextNode as ContinueNode:
            // Display the connector view for the next node.
            ConnectorView(davinciViewModel: davinciViewModel, nextNode: nextNode)
          case is SuccessNode:
            // Navigate to the token view on success.
            VStack{}.onAppear {
              path.removeLast()
              path.append("Token")
            }
          case let failureNode as FailureNode:
            // Handle failure node scenarios.
            if let nextNode = davinciViewModel.data.previousNode as? ContinueNode {
              ConnectorView(davinciViewModel: davinciViewModel, nextNode: nextNode)
            }
            
            let apiError = failureNode.cause as? ApiError
            switch apiError {
            case .error(_, _, let message):
              // Show error message from the API.
              ErrorView(name: message)
            default:
              // Show a default error message.
              ErrorView(name: "unknown error")
            }
            
          case let errorNode as ErrorNode:
            if let nextNode = davinciViewModel.data.previousNode as? ContinueNode {
              ConnectorView(davinciViewModel: davinciViewModel, nextNode: nextNode)
            }
            ErrorView(name: errorNode.message)
          default:
            // Show an empty view for unhandled cases.
            EmptyView()
          }
        }
      }
      
      Spacer()
      
      // Show an activity indicator when loading.
      if davinciViewModel.isLoading {
        Color.black.opacity(0.4)
          .edgesIgnoringSafeArea(.all)
        
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(4)
          .foregroundColor(.white)
      }
    }
  }
}

/// A view for displaying the current step in the Davinci flow.
struct ConnectorView: View {
  /// The Davinci view model managing the flow.
  @ObservedObject var davinciViewModel: DavinciViewModel
  /// The next node to process in the flow.
  public var nextNode: ContinueNode
  
  var body: some View {
    VStack {
      Image("Logo").resizable().scaledToFill().frame(width: 100, height: 100)
        .padding(.vertical, 32)
      HeaderView(name: nextNode.name) // Displays the header of the current node.
      DescriptionView(name: nextNode.description)// Displays the description of the current node.
      NewLoginView(
        davinciViewModel: davinciViewModel,
        nextNode: nextNode, collectorsList: nextNode.collectors)
    }// Displays input fields or buttons based on the collectors.
  }
}

/// A view for displaying error messages.
struct ErrorView: View {
  var name: String = ""
  
  var body: some View {
    VStack {
      Text(name)
        .foregroundColor(.red).padding(.top, 20)
    }
  }
}

/// A view for displaying the header of a node.
struct HeaderView: View {
  var name: String = ""
  
  var body: some View {
    VStack {
      Text(name)
        .font(.title)
    }
  }
}

/// A view for displaying the description of a node.
struct DescriptionView: View {
  var name: String = ""
  
  var body: some View {
    VStack {
      Text(name)
        .font(.subheadline)
    }
  }
}

/// A view for displaying input fields and actions based on the flow's collectors.
struct NewLoginView: View {
  /// The Davinci view model managing the flow.
  @ObservedObject var davinciViewModel: DavinciViewModel
  /// The next node to process.
  public var nextNode: ContinueNode
  /// The list of collectors to display as input fields or buttons.
  public var collectorsList: Collectors
  
  var body: some View {
    VStack {
      ForEach(collectorsList, id: \.id) { field in
        VStack {
          if let text = field as? TextCollector {
            // Displays a text input field.
            InputView(text: text.value, placeholderString: text.label, field: text)
          }
          
          if let password = field as? PasswordCollector {
            // Displays a secure password input field.
            InputView(placeholderString: password.label, secureField: true, field: password)
          }
          
          if let submitButton = field as? SubmitCollector {
            // Displays a submit button.
            InputButton(title: submitButton.label, field: submitButton) {
              Task {
                await davinciViewModel.next(node: nextNode)
              }
            }
          }
        }.padding(.horizontal, 5).padding(.top, 20)
        
        if let flowButton = field as? FlowCollector {
          // Displays a button to trigger a flow action.
          Button(action: {
            flowButton.value = "action"
            Task {
              await davinciViewModel.next(node: nextNode)
            }
          }) {
            Text(flowButton.label)
              .foregroundColor(.black)
          }
        }
      }
    }
  }
}
