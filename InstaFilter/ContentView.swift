//
//  ContentView.swift
//  InstaFilter
//
//  Created by Bruno Oliveira on 17/09/24.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    @State private var showingFilters = false
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    //insted of @State private ar currentFilter = CIFilter.sepiaTone() *1
    let context = CIContext()
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to to import a photo"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                Spacer()
                
                HStack {
                    Text("Intensity")
                    Slider(value: $filterIntensity)
                        .onChange(of: filterIntensity, applyProcessing)
                }
                .padding(.vertical)
                
                HStack {
                    Button("Change Filter", action: changeFilter)
                    Spacer()
                    
                    //Share the picture
                    ///that needs to be replaced with a check to see if there is an image to share, and, if there is, a ShareLink button using it.
                    
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter Image", image: processedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("InstaFilter")
            .confirmationDialog("Select a Filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize())}
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur())}
                Button("Edges") { setFilter(CIFilter.edges())}
                Button("Pixellate") { setFilter(CIFilter.pixellate())}
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone())}
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask())}
                Button("Vignette") { setFilter(CIFilter.vignette())}
                Button("Cancel", role: .cancel) { }
                                            
            }
        }
        .padding()
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
            
        }
    }
    
    func applyProcessing() {
        // *1 - CIFilter.sepiaTone() returns a CIFilter object that conforms to the CISepiaTone protocol. Adding that explicit type annotation means we’re throwing away some data: we’re saying that the filter must be a CIFilter but doesn’t have to conform to CISepiaTone any more.As a result of this change we lose access to the intensity property, which means this code won’t work any more:
        
        //currentFilter.intensity = Float(filterIntensity)
        
        //currentFilter.setValue(filterIntensity,forKey: kCIInputIntensityKey) *2
        
        //*2 - Go ahead and run the app, select a picture, then try changing Sepia Tone to Vignette – this applies a darkening effect around the edges of your photo. (If you’re using the simulator, remember to give it a little time because it’s slow!)Now try changing it to Gaussian Blur, which ought to blur the image, but will instead cause our app to crash. By jettisoning the CISepiaTone restriction for our filter, we’re now forced to send values in using setValue(_:forKey:), which provides no safety at all. In this case, the Gaussian Blur filter doesn’t have an intensity value, so the app just crashes.To fix this – and also to make our single slider do much more work – we’re going to add some more code that reads all the valid keys we can use with setValue(_:forKey:), and only sets the intensity key if it’s supported by the current filter. Using this approach we can actually query as many keys as we want, and set all the ones that are supported. So, for sepia tone this will set intensity, but for Gaussian blur it will set the radius (size of the blur), and so on.This conditional approach will work with any filters you choose to apply, which means you can experiment with others safely. The only thing you need be careful with is to make sure you scale up filterIntensity by a number that makes sense – a 1-pixel blur is pretty much invisible, for example, so I’m going to multiply that by 200 to make it more pronounced.
        
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage,from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage : cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    //*3 - Now Swift will ensure that code always runs on the main actor, and the compile error will go away.
    @MainActor func setFilter(_ Filter: CIFilter) {
        currentFilter = Filter
        loadImage()
        
        //Tip: This means image loading is triggered every time a filter changes. If you wanted to make this run a little faster, you could store beginImage in another @State property to avoid reloading the image each time a filter changes.
        
        filterCount += 1
        
        if filterCount >= 20 {
            requestReview()
            //*3 That will trigger an error in Xcode: requesting a review must be done on Swift's main actor, which is the part of our app that's able to work with the user interface. Although we're currently writing code inside a SwiftUI view, Swift can't guarantee this code will run on the main actor unless we specifically force that to be the case.
        }
        
    }
    
}

#Preview {
    ContentView()
}
