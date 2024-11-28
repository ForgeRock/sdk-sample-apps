import SwiftUI
import FRAuth

struct ContentView: View {
    
    @State private var startDavinici = false
    
    @State private var path: [String] = []
    
    @State private var configurationViewModel: ConfigurationViewModel = ConfigurationManager.shared.loadConfigurationViewModel()
    
    @ObservedObject var oidcViewModel: OIDCViewModel = OIDCViewModel()
    
    @ObservedObject var logoutViewModel: LogoutViewModel = LogoutViewModel()
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section(header: Text("Configuration")) {
                    NavigationLink(value: "Configuration") {
                        Text("Edit configuration")
                    }
                }
                Section(header: Text("Storage Items")) {
                    NavigationLink(value: "Token") {
                        Text("Access Token")
                    }
                    NavigationLink(value: "User") {
                        Text("User Info")
                    }
                }
                Section(header: Text("Actions")) {
                    Button(action: {
                        Task {
                            do {
                                let _ = try await oidcViewModel.startOIDC()
                                path.append("Token")
                            } catch {
                                print(String(describing: error))
                            }
                        }
                    }) {
                        Text("Launch OIDC")
                    }
                    Button(action: {
                        Task {
                            await logoutViewModel.logout()
                            self.oidcViewModel.updateStatus()
                        }
                    }) {
                        Text("Logout")
                    }
                }
            }
            .navigationDestination(for: String.self) { item in
                switch item {
                case "Configuration":
                    ConfigurationView(configurationViewModel: $configurationViewModel)
                case "Token":
                    AccessTokenView(path: $path, accessTokenViewModel: AccessTokenViewModel())
                case "User":
                    UserInfoView(path: $path, userInfoViewModel:  UserInfoViewModel())
                default:
                    EmptyView()
                }
            }
            .navigationBarTitle("Ping OIDC")
            Text($oidcViewModel.status.wrappedValue)
            Image(uiImage: UIImage(named: "Logo")!)
                .resizable()
                .frame(width: 180.0, height: 180.0).clipped()
            
            
        }
        .onAppear{
            Task {
                do {
                    let _ = try await ConfigurationManager.shared.startSDK()
                    self.oidcViewModel.updateStatus()
                } catch {
                    self.oidcViewModel.status = String(describing: error)
                    print(String(describing: error))
                }
            }
        }
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { (url) in
                    let _ = Browser.validateBrowserLogin(url: url)
                }
        }
    }
}
