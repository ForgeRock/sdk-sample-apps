// 
//  AsyncSVGImage.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import SVGKit

struct AsyncSVGImage: View {
    let url: URL
    @State private var svgImage: SVGKImage?

    var body: some View {
        Group {
            if let svgImage = svgImage {
                // Convert the SVGKImage to a UIImage and display it.
                Image(uiImage: svgImage.uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // While loading, show a progress indicator.
                ProgressView()
                    .onAppear(perform: loadSVG)
            }
        }
    }
    
    private func loadSVG() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let loadedSVG = SVGKImage(data: data) else {
                return
            }
            DispatchQueue.main.async {
                self.svgImage = loadedSVG
            }
        }.resume()
    }
}
