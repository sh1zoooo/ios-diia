//___FILEHEADER___

import SwiftUI
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes

struct ___FILEBASENAMEASIDENTIFIER___: View, NavigableSwiftUIView {
    @ObservedObject var viewModel: ___VARIABLE_productName:identifier___ViewModel
    var navigation: NavigationHolder { return viewModel.navigation }

    init(viewModel: ___VARIABLE_productName:identifier___ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color(.blackSqueeze)
                .edgesIgnoringSafeArea(.all)
            VStack {
                TopNavigationViewSUI(
                    viewModel: .init(
                        contextMenu: viewModel.contextMenu,
                        navigation: navigation))
                ScrollView {
                    Text("Put your content here")
                }
            }
        }
    }
}
