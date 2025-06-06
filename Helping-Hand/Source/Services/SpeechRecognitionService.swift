import Foundation
import Speech
import Combine

class SpeechRecognitionService: NSObject, ObservableObject {
    // Singleton instance for convenience
    static let shared = SpeechRecognitionService()
    
    // Published state properties
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // Private properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var textSubject = PassthroughSubject<String, Never>()
    
    // Make text available via Combine publisher
    var recognizedTextPublisher: AnyPublisher<String, Never> {
        textSubject.eraseToAnyPublisher()
    }
    
    // Check and request permissions
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                if status != .authorized {
                    self.errorMessage = "Speech recognition not authorized."
                }
            }
        }
    }
    
    // Start recording and recognition
    func startRecording() {
        // Reset states
        recognizedText = ""
        errorMessage = nil
        
        // Check if we're already recording
        if isRecording {
            stopRecording()
            return
        }
        
        // Check authorization
        if authorizationStatus != .authorized {
            requestAuthorization()
            return
        }
        
        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
            return
        }
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create speech recognition request"
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep audio data for reference
        recognitionRequest.taskHint = .search
        
        // Create a recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update with latest result
                self.recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recording when done or on error
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
                
                // Publish the final result
                if !self.recognizedText.isEmpty {
                    self.textSubject.send(self.recognizedText)
                }
            }
        }
        
        // Configure audio
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
        }
    }
    
    // Stop recording and finalize recognition
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        
        // In test mode, generate mock results
        if AppDelegate.isTestMode && recognizedText.isEmpty {
            let mockPhrases = [
                "I need a window repair service",
                "Where can I find Chinese food?",
                "I'm looking for hotels nearby"
            ]
            let mockText = mockPhrases.randomElement() ?? "Help me find something nearby"
            
            // Simulate typing with slight delays
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.recognizedText = mockText
                self.textSubject.send(mockText)
            }
        }
    }
    
    // Get appropriate icon for current state
    func getRecordingIcon() -> String {
        if isRecording {
            return "waveform.circle.fill"
        } else {
            return "mic.fill"
        }
    }
}
