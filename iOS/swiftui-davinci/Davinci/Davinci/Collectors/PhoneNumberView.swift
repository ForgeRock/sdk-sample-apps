// 
//  PhoneNumberView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A Struct representing a Country
/// - `countryCode`: The country code for the country.
/// - `name`: The name of the country.
/// - `countryCodeNumber`: The country code number for the country.
/// This struct conforms to the `Identifiable` protocol, allowing it to be used in SwiftUI views that require unique identifiers for each item.
/// It also provides static methods to retrieve the country code and country code number based on the provided values.
struct Country: Identifiable {
    var id: String { countryCode }
    var countryCode: String
    var name: String
    var countryCodeNumber: String
    
    static func countryCodeForCountryCodeNumber(_ countryCodeNumber: String, listOfCountries: [Country]) -> String? {
        for country in listOfCountries {
            if country.countryCodeNumber == countryCodeNumber {
                return country.countryCode
            }
        }
        return nil
    }
    
    static func countryCodeNumberForCountryCode(_ countryCode: String, listOfCountries: [Country]) -> String? {
        for country in listOfCountries {
            if country.countryCode == countryCode {
                return country.countryCodeNumber
            }
        }
        return nil
    }
}

struct PhoneNumberView: View {
    var field: PhoneNumberCollector
    var onNodeUpdated: () -> Void
    var listOfCountries: [Country] = [
        Country(countryCode: "US", name: "United States", countryCodeNumber: "1"),
        Country(countryCode: "CA", name: "Canada", countryCodeNumber: "1"),
        Country(countryCode: "GB", name: "United Kingdom", countryCodeNumber: "44"),
        Country(countryCode: "AU", name: "Australia", countryCodeNumber: "61"),
        Country(countryCode: "DE", name: "Germany", countryCodeNumber: "49"),
        Country(countryCode: "FR", name: "France", countryCodeNumber: "33"),
        Country(countryCode: "JP", name: "Japan", countryCodeNumber: "81"),
        Country(countryCode: "CN", name: "China", countryCodeNumber: "86"),
        Country(countryCode: "IN", name: "India", countryCodeNumber: "91"),
        Country(countryCode: "BR", name: "Brazil", countryCodeNumber: "55"),
        Country(countryCode: "RU", name: "Russia", countryCodeNumber: "7"),
        Country(countryCode: "IT", name: "Italy", countryCodeNumber: "39"),
        Country(countryCode: "KR", name: "South Korea", countryCodeNumber: "82"),
        Country(countryCode: "MX", name: "Mexico", countryCodeNumber: "52"),
        Country(countryCode: "ES", name: "Spain", countryCodeNumber: "34"),
        Country(countryCode: "ZA", name: "South Africa", countryCodeNumber: "27"),
        Country(countryCode: "HK", name: "Hong Kong", countryCodeNumber: "852")
        // Add more countries as needed
    ]
    
    @EnvironmentObject var validationViewModel: ValidationViewModel
    @State var text: String = ""
    @State private var isValid: Bool = true
    @State private var expanded: Bool = false
    @State private var selectedCountry: Country?
    
    var body: some View {
        HStack {
            Menu {
                ForEach(listOfCountries) { country in
                    Button(action: {
                        selectedCountry = country
                        field.countryCode = selectedCountry?.countryCode ?? ""
                        expanded = false
                        isValid = field.validate().isEmpty
                        onNodeUpdated()
                    }) {
                        Text("+" + country.countryCodeNumber)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
            } label: {
                HStack {
                    Text({
                        var selectedCountryCode: String?
                        if let selectedCountry = selectedCountry {
                            selectedCountryCode = Country.countryCodeForCountryCodeNumber(selectedCountry.countryCodeNumber, listOfCountries: listOfCountries)
                        }
                        
                        let code: String
                        if !field.countryCode.isEmpty {
                            code = field.countryCode
                        } else {
                            code = selectedCountryCode ?? field.defaultCountryCode
                        }
                        
                        let codeNumber = Country.countryCodeNumberForCountryCode(code, listOfCountries: listOfCountries)
                        if !code.isEmpty {
                            field.countryCode = code
                        }
                        return (codeNumber == nil) ? "Select an option" : "+" + codeNumber!
                    }())
                        .foregroundColor((selectedCountry?.countryCodeNumber ?? "").isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(Angle(degrees: expanded ? 180 : 0))
                        .foregroundStyle(Color.themeButtonBackground)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValid ? Color.gray : Color.red, lineWidth: 1)
                )
            }
            TextField(
                field.required ? "\(field.label)*" : field.label,
                text: $text
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.gray : Color.red, lineWidth: 1)
            )
            .onAppear(perform: {
                text = field.phoneNumber
            })
            .onChange(of: text) { newValue in
                field.phoneNumber = newValue
                isValid = field.validate().isEmpty
                onNodeUpdated()
            }
            if !isValid {
                ErrorMessageView(errors: field.validate().map { $0.errorMessage }.sorted())
            }
        }
        .onChange(of: validationViewModel.shouldValidate) { newValue in
            if newValue {
                isValid = field.validate().isEmpty
            }
        }
        .padding()
    }
}

