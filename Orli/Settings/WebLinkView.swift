//
//  WebLinkView.swift
//  Orli
//
//  Created by mohammad ali panhwar on 22/06/2025.
//

import SwiftUI
import WebKit


struct CleanWebView: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool

       func makeUIView(context: Context) -> WKWebView {
           let webView = WKWebView()
           webView.navigationDelegate = context.coordinator
           isLoading = true
           return webView
       }

       func updateUIView(_ webView: WKWebView, context: Context) {
           guard let url = URL(string: urlString) else { return }
           webView.load(URLRequest(url: url))
       }

       func makeCoordinator() -> Coordinator {
           Coordinator(isLoading: $isLoading)
       }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        
        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            let js = """
            // Remove top bar (sticky nav)
            const topBar = document.querySelector('body > div > div > div.sticky');
            if (topBar) topBar.remove();

            // Remove footer
            const footer = document.querySelector('footer');
            if (footer) footer.remove();

            // Optional: also remove second section at bottom (like logo area)
            const allDivs = document.querySelectorAll('body > div > div');
            if (allDivs.length > 2) {
                const lastSection = allDivs[allDivs.length - 1];
                lastSection.remove();
            }

            // Remove padding left after header/footer removed
            document.body.style.paddingTop = '0px';
            document.body.style.paddingBottom = '0px';
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

}




struct WebContainerView: View {
    let link: String
    @State private var isLoading = true


    var body: some View {
        ZStack {
               VStack {
                   CleanWebView(urlString: link, isLoading: $isLoading)
               }

               if isLoading {
                   Color.black.opacity(0.4).ignoresSafeArea()

                   LottieView(animationName: "loader")
                       .frame(width: 150, height: 150)
               }
           }
        .background(Color("Primary"))
        .padding(.top, -120)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
