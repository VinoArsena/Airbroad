//
//  BottomPanelSheetView.swift
//  Airbroad
//
//  Created by Caroline Ang on 11/08/26.
//


import SwiftUI

struct BottomPanelSheetView: View {
    @Bindable var viewModel: SearchViewModel
    @Binding var currentPresentationDetents: PresentationDetent
    
    var activeSearchText: Binding<String> = .constant("Where you wanna go?")
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .padding(.trailing, 5)
                TextField("", text: activeSearchText)
                    .foregroundStyle(Color(.systemGray))
            }
            .padding(10)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Text("How long will you stay?")
            
        }
        .padding(20)
    }
}

#Preview {
    BottomPanelSheetView(viewModel: SearchViewModel(), currentPresentationDetents:.constant(.fraction(0.1)))
}
