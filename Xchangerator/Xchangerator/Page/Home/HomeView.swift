//
//  HomeView.swift
//  Xchangerator
//
//  Created by Yizhang Cao on 2020-01-28.
//  Copyright © 2020 YYES. All rights reserved.
//

import Foundation
import PartialSheet
import SwiftUI

struct HomeView: View {
    @State private var baseCurrencyAmt: String = "100"
    @State private var baseCurrencyUnit: String = "CAD"
    @EnvironmentObject var countries: Countries
    @State private var modalPresented: Bool = false
    @State private var longer: Bool = false
    
    func convert(_ targetCurrencyUnit: String) -> String {
        let amount = Double(baseCurrencyAmt) ?? 0
        let converter = Converter(countries)
        let convertedAmount = converter.convert(self.baseCurrencyUnit, targetCurrencyUnit, amount)
        return String(format:"%.2f",convertedAmount)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("🇨🇦")
                        .padding(.leading, 50)
                        .font(.largeTitle)
                    TextField("Amount", text: $baseCurrencyAmt)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                        .frame(width: 170)
                    Text(baseCurrencyUnit)
                    
                    Button(action: {
                        self.modalPresented = true
                    }) {
                    Image("ellipsis").padding(.trailing, 10).padding(.leading, 20)
                    }
                }
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.black, lineWidth: 0.5)
                    ).padding()
                ScrollView{
                    ForEach(countries.getModel(), id:\.self) { country in
                        HStack {
                            Text(country.flag)
                                .padding(.leading, 50)
                                .font(.largeTitle)
                            Text(self.convert(country.unit))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .fixedSize()
                                .frame(width: 170)
                            Text(country.unit).padding(.trailing, 50)
                        }
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.black, lineWidth: 0.5)
                            ).padding()
                    }
                }
                
                
            }
            
        }.partialSheet(presented: $modalPresented) {
            VStack {
                Group {
                    Text("Settings Panel")
                        .font(.subheadline)
                    Toggle(isOn: self.$longer) {
                        Text("Advanced")
                    }
                    .padding()
                }
                .frame(height: 50)
                if self.longer {
                    VStack {
                        Text("More settings here...")
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}
