import SwiftUI

struct UserBiographyScreen: View {
    @EnvironmentObject var dataCentralObservable: IamagesDataCentral
    var body: some View {
        Form {
            Text(verbatim: dataCentralObservable.userInformation.biography)
                .multilineTextAlignment(.leading)
        }.navigationBarTitle("Biography")
    }
}

struct UserBiographyScreen_Previews: PreviewProvider {
    static var previews: some View {
        UserBiographyScreen()
    }
}
