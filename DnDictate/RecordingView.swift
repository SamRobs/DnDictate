import SwiftUI
import Supabase

struct RecordingView: View {
    @StateObject private var recorder: DnDRecorder
    @State private var showError = false
    @State private var showEntityReview = false
    @State private var showTranscriptionEdit = false
    @State private var editedTranscription: String = ""
    
    init(supabase: SupabaseClient) {
        _recorder = StateObject(wrappedValue: DnDRecorder(supabase: supabase))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("D&D Session Recorder")
                .font(.largeTitle)
                .padding()
            
            if recorder.isRecording {
                VStack {
                    Text("Recording in progress...")
                        .font(.title2)
                    
                    ScrollView {
                        Text(recorder.transcriptionText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                    
                    Button(action: {
                        Task {
                            await recorder.stopRecording()
                            editedTranscription = recorder.transcriptionText
                            showTranscriptionEdit = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Recording")
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            } else {
                Button(action: {
                    Task {
                        await recorder.startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: "record.circle")
                        Text("Start Recording")
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            if let error = recorder.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = recorder.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showTranscriptionEdit) {
            NavigationView {
                VStack {
                    TextEditor(text: $editedTranscription)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding()
                    
                    Button("Proceed to Entity Review") {
                        showTranscriptionEdit = false
                        showEntityReview = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .navigationTitle("Edit Transcription")
                .navigationBarItems(trailing: Button("Done") {
                    showTranscriptionEdit = false
                    showEntityReview = true
                })
            }
        }
        .sheet(isPresented: $showEntityReview) {
            NavigationView {
                EntityReviewView(
                    transcriptionText: editedTranscription,
                    sessionId: recorder.sessionId ?? ""
                )
                .navigationTitle("Review Entities")
                .navigationBarItems(trailing: Button("Done") {
                    showEntityReview = false
                })
            }
        }
    }
}

#Preview {
    RecordingView(supabase: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: ""))
} 