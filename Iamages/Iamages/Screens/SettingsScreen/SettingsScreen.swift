import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(dataCentralObservable.userInformation.auth.username)
                            .bold()
                    }
                    HStack {
                        Text("Creation date")
                        Spacer()
                        Text(dataCentralObservable.userInformation.createdDate)
                            .bold()
                            .lineLimit(-1)
                    }
                    NavigationLink(destination: UserBiographyScreen(), label: {
                        HStack {
                            Text("Biography")
                            Spacer()
                            Text(dataCentralObservable.userInformation.biography)
                                .bold()
                                .lineLimit(-1)
                        }
                    })
                }
                Section(header: Text("Settings")) {
                    NavigationLink(destination: UserSettingsScreen(), label: {
                        Image(systemName: "person.circle")
                        Text("User settings")
                    })
                    NavigationLink(destination: AppSettingsScreen(), label: {
                        Image(systemName: "gear")
                        Text("App settings")
                    })
                }
                Section(header: Text("About"), footer: Text("Iamages iOS 2.1.0 (2)")) {
                    Link(destination: URL(string: api.IAMAGES_APIROOT + "private/tos")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "signature")
                        }
                    }
                    Link(destination: URL(string: api.IAMAGES_APIROOT + "private/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "hand.raised")
                        }
                    }
                    Link(destination: URL(string: "https://github.com/iamages")!) {
                        HStack {
                            Text("Open-source on GitHub")
                            Spacer()
                            Image(systemName: "chevron.left.slash.chevron.right")
                        }
                    }
                    Link(destination: URL(string: "https://discord.gg/hGwGkZsuXB")!) {
                        HStack {
                            Text("Join our Discord")
                            Spacer()
                            Image(systemName: "ellipsis.bubble")
                        }
                    }
                 }
            }.navigationBarTitle("Settings")
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
