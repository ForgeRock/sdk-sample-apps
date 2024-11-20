import SwiftUI

struct ContentView: View {
    
    @State private var startDavinici = false
    
    @State private var path: [String] = []
    
    @State private var configurationViewModel: ConfigurationViewModel = ConfigurationManager.shared.loadConfigurationViewModel()
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: "Configuration") {
                    Text("Edit configuration")
                }
                NavigationLink(value: "OIDC") {
                    Text("Launch OIDC")
                }
                NavigationLink(value: "Token") {
                    Text("Access Token")
                }
                NavigationLink(value: "User") {
                    Text("User Info")
                }
                NavigationLink(value: "Logout") {
                    Text("Logout")
                }
            }.navigationDestination(for: String.self) { item in
                switch item {
                case "Configuration":
                    ConfigurationView(viewmodel: $configurationViewModel)
                case "OIDC":
                    LoginView(oidcViewModel: OIDCViewModel(), path: $path)
                case "Token":
                    AccessTokenView(path: $path)
                case "User":
                    UserInfoView(path: $path)
                case "Logout":
                    LogoutView(path: $path)
                default:
                    EmptyView()
                }
            }.navigationBarTitle("Ping OIDC")
            Image(uiImage: UIImage(named: "Logo")!)
                .resizable()
                .frame(width: 180.0, height: 180.0).clipped()
        }.onAppear{
            ConfigurationManager.shared.startSDK()
        }
    }
}

struct NextButton: View {
    let title: String
    let action: () -> (Void)
    var body: some View {
        Button(action:  {
            action()
        } ) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: 50)
                .background(Color.green)
                .cornerRadius(15.0)
                .shadow(radius: 10.0, x: 20, y: 10)
        }
        
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
