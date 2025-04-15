import Foundation
import AVFoundation
import SwiftUI
import Supabase
import Speech

class DnDRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, SFSpeechRecognizerDelegate {
    @Published var isRecording = false
    @Published var currentChunkIndex = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var errorMessage: String?
    @Published var transcriptionText: String = ""
    @Published var sessionId: String?
    @Published var isAuthorized = false
    
    private let supabase: SupabaseClient
    private var audioRecorder: AVAudioRecorder?
    private var currentChunkURL: URL?
    private let chunkDuration: TimeInterval = 30 * 60 // 30 minutes
    private var chunkTimer: Timer?
    private var chunks: [URL] = []
    
    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        super.init()
        setupAudioSession()
        setupSpeechRecognition()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
            }
        }
    }
    
    private func setupSpeechRecognition() {
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                case .denied:
                    self?.errorMessage = "Speech recognition permission denied"
                case .restricted:
                    self?.errorMessage = "Speech recognition not available on this device"
                case .notDetermined:
                    self?.errorMessage = "Speech recognition not yet authorized"
                @unknown default:
                    self?.errorMessage = "Unknown speech recognition authorization status"
                }
            }
        }
    }
    
    func startRecording() async {
        guard !isRecording else { return }
        guard isAuthorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }
        
        do {
            // Check if user is authenticated
            guard try await supabase.auth.session != nil else {
                throw NSError(domain: "DnDRecorder", code: 4, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Generate a unique session ID
            sessionId = UUID().uuidString
            
            // Start speech recognition
            try await startSpeechRecognition()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.transcriptionText = ""
            }
            
            // Upload initial metadata to Supabase
            try await supabase.from("transcription_sessions")
                .insert([
                    "id": sessionId!,
                    "start_time": Date().ISO8601Format(),
                    "status": "recording"
                ])
                .execute()
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isRecording = false
                self.sessionId = nil
            }
        }
    }
    
    private func startSpeechRecognition() async throws {
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Ensure audio session is properly configured
        let audioSession = AVAudioSession.sharedInstance()
        if !audioSession.isInputAvailable {
            throw NSError(domain: "DnDRecorder", code: 2, userInfo: [NSLocalizedDescriptionKey: "No audio input available"])
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "DnDRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Create a recognition task for the speech recognition session
        guard let speechRecognizer = speechRecognizer else {
            throw NSError(domain: "DnDRecorder", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcriptionText = result.bestTranscription.formattedString
                    
                    // Upload the transcription to Supabase
                    Task {
                        try? await self.uploadTranscription(result.bestTranscription.formattedString)
                    }
                }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                }
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure the microphone input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func uploadTranscription(_ text: String) async throws {
        guard let sessionId = sessionId else {
            throw NSError(domain: "DnDRecorder", code: 5, userInfo: [NSLocalizedDescriptionKey: "No active session"])
        }
        
        guard try await supabase.auth.session != nil else {
            throw NSError(domain: "DnDRecorder", code: 4, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.from("transcription_chunks")
            .insert([
                "session_id": sessionId,
                "text": text,
                "timestamp": Date().ISO8601Format()
            ])
            .execute()
    }
    
    func stopRecording() async {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        do {
            // Upload final metadata to Supabase
            try await supabase.from("transcription_sessions")
                .update([
                    "end_time": Date().ISO8601Format(),
                    "status": "completed",
                    "final_text": transcriptionText
                ])
                .eq("id", value: sessionId!)
                .execute()
            
            DispatchQueue.main.async {
                self.isRecording = false
                self.currentChunkIndex = 0
                self.sessionId = nil
            }
            
        } catch {
            errorMessage = "Failed to stop recording: \(error.localizedDescription)"
        }
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            errorMessage = "Speech recognition is not available"
        }
    }
} 