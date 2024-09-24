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
    
    @State private var inputKeyLog: [String] = []
    @State private var showLogAlert = false
    @State private var logMessage = "No input Keys Logged"
    
    @State private var showingFilters = false
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var radiusIntensity = 100.0
    @State private var scaleIntensity = 5.0
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    //insted of @State private ar currentFilter = CIFilter.sepiaTone() *1
    let context = CIContext()
    let radiusFilters: [CIFilter] = [
        CIFilter.gaussianBlur(),
        CIFilter.boxBlur(),
    ]
    @State private var center: CIVector
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    // Inicializador padrão
        init(center: CIVector = CIVector(x: 150, y: 150)) {
            self.center = center
        }
    
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
                
                List(inputKeyLog, id: \.self) {
                    Text($0)
                }
                
                Spacer()
                
                if let processedImage {
                    VStack {
                        VStack {
                            if currentFilter.inputKeys.contains(kCIInputIntensityKey) {
                                Text("Intensity")
                                Slider(value: $filterIntensity, in: 0...1)
                                    .onChange(of: filterIntensity)  { oldValue, newValue in
                                        applyProcessing(center)
                                    }
                            }
                            
                            if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
                                //Challange n1: we can do instead of if let:
                                ///.disabled(processedImage == nil
                                Text("Radius")
                                
                                Slider(value: $radiusIntensity, in: 0...200)
                                    .onChange(of: radiusIntensity) { oldValue, newValue in
                                        applyProcessing(center)
                                    }
                            }
                            
                            if currentFilter.inputKeys.contains(kCIInputScaleKey) {
                                //Challange n1: we can do instead of if let:
                                ///.disabled(processedImage == nil
                                Text("Scale")
                                
                                Slider(value: $scaleIntensity, in: 0...10)
                                    .onChange(of: scaleIntensity) { oldValue, newValue in
                                        applyProcessing(center)
                                    }
                            }
                        }
                        .padding(.vertical)
                        
                        HStack {
                            Button("Change Filter", action: changeFilter)
                            //Challange n1: we can do instead of if let:
                            ///.disabled(processedImage == nil
                            Spacer()
                            
                            //Share the picture
                            ///that needs to be replaced with a check to see if there is an image to share, and, if there is, a ShareLink button using it, we need to put if let processed image here or in all code like line 44 (Challange Day 67)
                            
                            ShareLink(item: processedImage, preview: SharePreview("Instafilter Image", image: processedImage))
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("InstaFilter")
            .confirmationDialog("Select a Filter", isPresented: $showingFilters) {
                Button("Bloom") { setFilter(CIFilter.bloom())
                    logInputKeysCurrentFilter()}
                Button("Crystallize") { setFilter(CIFilter.crystallize())
                    logInputKeysCurrentFilter()}
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur())
                    logInputKeysCurrentFilter()}
                Button("Noir") { setFilter(CIFilter.photoEffectNoir())
                    logInputKeysCurrentFilter()}
                Button("Edges") { setFilter(CIFilter.edges())
                    logInputKeysCurrentFilter()}
                Button("Pixellate") { setFilter(CIFilter.pixellate())
                    logInputKeysCurrentFilter()}
                Button("Pointllize") { setFilter(CIFilter.pointillize())
                    logInputKeysCurrentFilter()}
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone())
                    logInputKeysCurrentFilter()}
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask())
                    logInputKeysCurrentFilter()}
                Button("Vignette") { setFilter(CIFilter.vignette())
                    logInputKeysCurrentFilter()}
                Button("Bump Distortion") { setFilter(CIFilter.bumpDistortion())
                    logInputKeysCurrentFilter()}
                Button("Color Invert") { setFilter(CIFilter.colorInvert())
                    logInputKeysCurrentFilter()}
                Button("Cancel", role: .cancel) { }
                                            
            }
            .alert("Selected Filter Inpu Keys", isPresented: $showLogAlert) {
                Button ("Log") {
                    
                }
                Button ("ok"){
                    
                }
            } message: {
                Text(logMessage)
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
            center = CIVector(x: inputImage.size.width / 2, y: inputImage.size.height / 2)
            applyProcessing(center)
            
        }
    }
    
    func applyProcessing(_ center: CIVector) {
        // *1 - CIFilter.sepiaTone() returns a CIFilter object that conforms to the CISepiaTone protocol. Adding that explicit type annotation means we’re throwing away some data: we’re saying that the filter must be a CIFilter but doesn’t have to conform to CISepiaTone any more.As a result of this change we lose access to the intensity property, which means this code won’t work any more:
        
        //currentFilter.intensity = Float(filterIntensity)
        
        //currentFilter.setValue(filterIntensity,forKey: kCIInputIntensityKey) *2
        
        //*2 - Go ahead and run the app, select a picture, then try changing Sepia Tone to Vignette – this applies a darkening effect around the edges of your photo. (If you’re using the simulator, remember to give it a little time because it’s slow!)Now try changing it to Gaussian Blur, which ought to blur the image, but will instead cause our app to crash. By jettisoning the CISepiaTone restriction for our filter, we’re now forced to send values in using setValue(_:forKey:), which provides no safety at all. In this case, the Gaussian Blur filter doesn’t have an intensity value, so the app just crashes.To fix this – and also to make our single slider do much more work – we’re going to add some more code that reads all the valid keys we can use with setValue(_:forKey:), and only sets the intensity key if it’s supported by the current filter. Using this approach we can actually query as many keys as we want, and set all the ones that are supported. So, for sepia tone this will set intensity, but for Gaussian blur it will set the radius (size of the blur), and so on.This conditional approach will work with any filters you choose to apply, which means you can experiment with others safely. The only thing you need be careful with is to make sure you scale up filterIntensity by a number that makes sense – a 1-pixel blur is pretty much invisible, for example, so I’m going to multiply that by 200 to make it more pronounced.
        
        let inputKeys = currentFilter.inputKeys
        
        /*  ###### TO DO LATER: IMPLEMENT ALL FILTERS KEYS TO A SLIDER SO USER CAN CONTROL IT (LIKE SCALE FOR EXAMPLE)  ######### */
        
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(radiusIntensity, forKey: kCIInputRadiusKey)
        
            if inputKeys.contains(kCIInputCenterKey) {
                currentFilter.setValue(center, forKey: kCIInputCenterKey)
            }
            
        }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputScaleKey) }
        
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
    
    ///lines below to log purpose
    func logInputKeysCurrentFilter () {
        let inputKeys = currentFilter.inputKeys
        inputKeyLog.removeAll()
        for inputKey in inputKeys {
            inputKeyLog.append(inputKey)
        }
        
        /*  ###### TO DO LATER: SAVE ALL INPUT KEYS ON A JSON FILE ######### */
        //do a for loop to print in an alert all the inputkeylog array
        /*for inputKey in inputKeyLog {
            showLogAlert = false
            if inputKeyLog.contains(inputKey) {
                logMessage = "InputKeys that this filter apply: \(inputKey)"
            }
            showLogAlert = true
        }*/
    }
    /// end to log purpose
    
}

#Preview {
    ContentView()
}
