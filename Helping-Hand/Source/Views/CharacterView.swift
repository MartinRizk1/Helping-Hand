import SwiftUI
import UIKit
import Combine

struct CharacterView: View {
    let character: Character
    let mood: Character.Mood
    
    @State private var currentFrame: UIImage?
    @State private var animationTimer: Timer?
    @State private var frameIndex = 0
    @State private var isAnimating = false
    @State private var animationFrames: [UIImage] = []
    private let animationService = CharacterAnimationService.shared
    
    var body: some View {
        VStack {
            if let image = currentFrame {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .transition(.opacity)
                    .id(image.hashValue) // Force refresh on image change
            } else if let _ = UIImage(named: character.imageName) {
                Image(character.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
            } else {
                // Fallback to SF Symbol if no image is available
                VStack {
                    Image(uiImage: animationService.getSFSymbolForMood(mood))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .foregroundColor(Color("AccentColor"))
                        .padding()
                        .background(
                            Circle()
                                .fill(Color("AccentColor").opacity(0.2))
                                .frame(width: 180, height: 180)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color("AccentColor").opacity(0.5), lineWidth: 2)
                        )
                    
                    Text("Helper Character")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text(character.name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextColor"))
        }
        .onChange(of: mood) { newMood in
            startAnimation(for: newMood)
        }
        .onAppear {
            // Load animations when view appears
            animationFrames = animationService.getAnimationFramesForMood(mood)
            startAnimation(for: mood)
        }
        .onDisappear {
            stopAnimation()
        }
        .onTapGesture {
            // Do a quick happy animation when tapped
            let originalMood = mood
            
            // Show happy flash
            withAnimation(.easeInOut(duration: 0.2)) {
                animationFrames = animationService.getAnimationFramesForMood(.happy)
                currentFrame = animationFrames.first
                
                // Return to original mood after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        animationFrames = animationService.getAnimationFramesForMood(originalMood)
                        currentFrame = animationFrames.first
                        startAnimation(for: originalMood)
                    }
                }
            }
        }
    }
    
    private func startAnimation(for mood: Character.Mood) {
        stopAnimation()
        
        // Get frames from our animation service
        animationFrames = animationService.getAnimationFramesForMood(mood)
        
        guard !animationFrames.isEmpty else {
            // Fall back to static image if no animation
            if let image = UIImage(named: character.imageName) {
                currentFrame = image
            } else {
                // If no image available, we'll use nil and let the view handle it
                currentFrame = animationService.getSFSymbolForMood(mood)
            }
            return
        }
        
        frameIndex = 0
        currentFrame = animationFrames[0]
        isAnimating = true
        
        // Animation speed varies by mood
        let interval: TimeInterval
        switch mood {
        case .thinking: interval = 0.3
        case .helping: interval = 0.2
        default: interval = 0.5
        }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            frameIndex = (frameIndex + 1) % animationFrames.count
            withAnimation(.easeInOut(duration: 0.1)) {
                currentFrame = animationFrames[frameIndex]
            }
        }
    }
    
    private func stopAnimation() {
        isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
    }
}
