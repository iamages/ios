//
//  LoginView.swift
//  Iamages
//
//  Created by Nam Thành Nguyễn on 07/11/2021.
//

import SwiftUI

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField(text: self.$password, prompt: Text("Username")) {}
                SecureField(text: self.$password, prompt: Text("Password")) {}
                Button(action: {
                    
                }) {
                    Label("Log in", systemImage: "")
                }
                Button(action: {
                    
                }) {
                    Label("Sign up", systemImage: "")
                }
            }
            .navigationTitle("Log in to Iamages")
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
