import SwiftUI
import Foundation

let kTitle = "AdsAssitant"
let kMsgWait = "收到，请稍候..."
let kSenderName = "AI"
let kReceiverName = "我"
let kMsgNetworkIssue = "请求失败，请检查网络"
let kSystemPrompt = "考虑你是一个法律专家，请你回答我的法律咨询问题，并给出适用条款。"
let kSendTextLimit = 1000

TODO: add you key here
let gptApiKey = "Bearer sk-l7b4AP2pUT3yvJ"
let gptOrgKey = "org-w3p2JBlT8SD"
let gptModel = "gpt-3.5-turbo"
let gptTemp = 0.7
let gptApiUrl = "https://api.openai.com/v1/chat/completions"

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let sender: String
    let sentDate: Date
    var isMe: Bool
}

struct GPT3Prompt: Codable {
    let model: String
    let messages: [GPT3PromptMessage]
    let temperature: Double
}

struct GPT3PromptMessage: Codable {
    let role: String
    let content: String
}

struct GPT3Response: Codable {
    let id: String?
    let object: String
    let created: Int64
    let model: String
    let usage: GPT3Usage
    let choices: [GPT3Choice]
}


struct GPT3Usage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

struct GPT3Choice: Codable {
    let message: GPT3ChoiceMessage
    let finish_reason: String
    let index: Int
}

struct GPT3ChoiceMessage: Codable {
    let role: String
    let content: String
}

func convertToPrompt(messages: [Message]) -> [GPT3PromptMessage] {
    let hidden_prompt = [GPT3PromptMessage(role: "system", content: kSystemPrompt)]
    let visible_prompt = messages.map {
        GPT3PromptMessage(role: $0.isMe ? "user" : "system", content: $0.content)
    }
    return hidden_prompt + visible_prompt
}

enum RecordingState {
    case idle, recording, busy

    var iconName: String {
        switch self {
        case .idle:
            return "mic.fill"
        case .recording:
            return "mic.slash.fill"
        case .busy:
            return "hourglass"
        }
    }
}

struct AssistantView: View {
    @State private var recordingState: RecordingState = .idle
    
    var body: some View {
        VStack {
            Button(action: {
                toggleRecording()
            }) {
                Image(systemName: recordingState.iconName)
            }
        }
    }
    
    private func toggleRecording() {
        print("on toogle")
        switch recordingState {
        case .idle:
            recordingState = .recording
            // Start recording logic here
        case .recording:
            recordingState = .busy
            // Stop recording logic here
        case .busy:
            // Add additional logic if needed when the state is busy
            var k = 0
            for _ in 1 ... 10000000 {
                k += 1
            }
            recordingState = .idle
            
        }
    }

}

struct ChatView: View {
    @State var messages: [Message] = []
    @State var messageText: String = ""
    @State var isSending: Bool = false

    var body: some View {
        VStack {
            List(messages) { message in
                MessageView(message: message)
            }
            HStack {
                TextField("输入你的问题", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: messageText) { newValue in
                        if newValue.count > kSendTextLimit {
                            messageText = String(newValue.prefix(kSendTextLimit))
                        }
                    }
                Button(action: sendMessage) {
                    Text("发送")
                }
                .disabled(isSending)
            }.padding()
        }
    }

    func sendMessage() {
        // diable send button until GPT ansered
        isSending = true
        
        // Create a new message with the current messageText and add it to the messages array
        let message = Message(content: messageText, sender: kReceiverName, sentDate: Date(), isMe: true)
        messages.append(message)

        // Simulate an AI response after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let aiMessage = Message(content: kMsgWait, sender: kSenderName, sentDate: Date(), isMe: false)
            self.messages.append(aiMessage)
        }
        
        // GPT3 result
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            requestGPT3(messages: self.messages) { (respondText) in
                let aiMessage = Message(content: respondText, sender: kSenderName, sentDate: Date(), isMe: false)
                self.messages.append(aiMessage)
                // enable send button
                isSending = false
            }
        }
        
        // Clear the messageText field
        messageText = ""
    }
}

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isMe {
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(message.content)
                        .padding(.all, 12)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .clipShape(ChatBubble(isMyMessage: true))
                        .padding(.trailing, 16)
                        .padding(.leading, 60)
                    Text(message.sentDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                        .padding(.leading, 60)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.content)
                        .padding(.all, 12)
                        .foregroundColor(.white)
                        .background(Color.gray)
                        .clipShape(ChatBubble(isMyMessage: false))
                        .padding(.leading, 16)
                        .padding(.trailing, 60)
                    Text(message.sentDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 16)
                        .padding(.trailing, 60)
                }
                Spacer()
            }
        }.frame(maxWidth: .infinity, alignment: message.isMe ? .trailing : .leading)
    }
}

struct ChatBubble: Shape {
    let isMyMessage: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight, isMyMessage ? .bottomLeft : .bottomRight], cornerRadii: CGSize(width: 16, height: 16))
        return Path(path.cgPath)
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
//            ChatView()
            AssistantView()
                .navigationBarTitle(Text(kTitle))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

/* Query GPT3 with either a question or use historical messages
    fetch fesult in completionBlock
 */
func requestGPT3(messages: [Message], completionBlock: @escaping (String) -> Void) {
    // 设置 API 请求 URL
    let url = URL(string: gptApiUrl)!

    // 创建请求
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue(gptApiKey, forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // 设置请求正文
    let gpt3Prompt = GPT3Prompt(
        model: gptModel,
        messages: convertToPrompt(messages: messages),
        temperature: gptTemp)
    let jsonData = try! JSONEncoder().encode(gpt3Prompt)
    request.httpBody = jsonData

    // 创建并启动任务
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Request failed with error: \(error)")
            return
        }
        
        // decode resp from data to json
        do {
            let gpt3Response = try  JSONDecoder().decode(GPT3Response.self, from: data!)
            if let choice = gpt3Response.choices.first {
                // decode json succ
                completionBlock(choice.message.content)
            } else {
                // decode json fail
                completionBlock("解析 choice 失败")
            }
        } catch {
            // if failed, decode resp from data to string
            if let outputStr = String(data: data!, encoding: String.Encoding.utf8) as String? {
                completionBlock(outputStr)
            } else {
                completionBlock(kMsgNetworkIssue)
            }
        }
    }
    task.resume()
}

