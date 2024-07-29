//
//  ContentView.swift
//  BirdWatcher
//
//  Created by mini project on 24/04/24.


import SwiftUI
import PhotosUI

struct ContentView: View {
 
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                  
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
            }else{
                Image(systemName: "person")
                    .resizable()
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/,height: 100)
                    .clipShape(Circle())
            }
            
            HStack {
                PhotosPicker("Select an image", selection: $selectedItem, matching: .images)
                    .onChange(of: selectedItem) { newValue in
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                selectedImage = UIImage(data: data)
                            }
                        }
                    }
                .foregroundColor(.blue)
               
                
            
            }
            
            Button("Open Camera") {
                showCamera = true
            }
             .foregroundColor(.blue)
            
        }
        .sheet(isPresented: $showCamera) {
            accessCameraView(selectedImage: $selectedImage)
        }
        .onAppear(perform: {
            do {
                print("Mounted")
                var abc =  try VisionMLWorker()
                abc.setupClassificationRequest()
                abc.classify()
            }
            catch{
                print(error) 
            }
        }) 
    }
}

struct accessCameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var isPresented
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
}

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: accessCameraView
    
    init(picker: accessCameraView) {
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.picker.selectedImage = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


