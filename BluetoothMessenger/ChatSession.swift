
import Foundation
import MultipeerConnectivity
import SwiftUI
import SwiftData

struct Message: Identifiable, Codable {
    var id = UUID()
    let senderName: String
    let content: String
    let isFromLocalUser: Bool
    let timestamp: Date
    var status: MessageStatus = .sending
    
    enum MessageStatus: Codable {
        case sending, delivered, failed
    }
}

class ChatSession: NSObject, ObservableObject {
    
    private var myPeerId: MCPeerID
    @Published var currentUserName: String
   // @Published var currentUserName = "User \(UIDevice.current.identifierForVendor!.uuidString)"
    
    private let serviceType = "bluetooth-chat"
    private let modelContext: ModelContext
    private var serviceAdvertiser: MCNearbyServiceAdvertiser
    private var serviceBrowser: MCNearbyServiceBrowser
    private var session: MCSession
    
    @Published var messages: [Message] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var connectionStatus = "Searching for devices..."
    
    private var colorCache: [String: Color] = [:]
    
    func colorForSender(_ name: String) -> Color {
        
        if let cached = colorCache[name] {
            return cached
        }
        
        // Генерируем цвет на основе хеша имени
        let hash = name.unicodeScalars.map { $0.value }.reduce(0, +)
        let hue = Double(hash % 360) / 360.0
        let color = Color(hue: hue, saturation: 0.7, brightness: 0.8)
        
        colorCache[name] = color
        return color
    }
    
    init(modelContext: ModelContext) {
        // Получаем сохраненные настройки или создаем новые
        let descriptor = FetchDescriptor<UserSettings>()
        let settings = (try? modelContext.fetch(descriptor).first) ?? UserSettings(userName: "User \(UIDevice.current.identifierForVendor!.uuidString)")
        
        self.modelContext = modelContext
        self.currentUserName = settings.userName
        self.myPeerId = MCPeerID(displayName: settings.userName)
    
    
        // 1. Инициализация всех stored properties
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        // 2. Вызов super.init
        super.init()
        
        // 3. Настройка делегатов (теперь можно использовать self)
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        // 4. Запуск сервисов
        startServices()
    }
    
    private func startServices() {
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    func updateUserName(_ newName: String) {
       //>> guard newName != currentUserName else { return }
        
        // Обновляем в памяти
        currentUserName = newName
        myPeerId = MCPeerID(displayName: newName)
        
        // Сохраняем в SwiftData
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            settings.userName = newName
        } else {
            modelContext.insert(UserSettings(userName: newName))
        }
        
        // Останавливаем текущие сервисы
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        session.disconnect()
        
        // Пересоздаем сервисы с новыми параметрами
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        // Настраиваем делегаты
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        // Запускаем сервисы заново
        startServices()
    }
    
    func send(message: String) {
        guard !message.isEmpty else { return }
        
        let newMessage = Message(
            senderName: currentUserName,
            content: message,
            isFromLocalUser: true,
            timestamp: Date()
        )
        
        messages.append(newMessage)
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try JSONEncoder().encode(newMessage)
                try self.session.send(data, toPeers: self.session.connectedPeers, with: .reliable)
                
                DispatchQueue.main.async {
                    if let index = self.messages.firstIndex(where: { $0.id == newMessage.id }) {
                        self.messages[index].status = .delivered
                    }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    if let index = self.messages.firstIndex(where: { $0.id == newMessage.id }) {
                        self.messages[index].status = .failed
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    func retrySend(message: Message) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        
        messages[index].status = .sending
        send(message: message.content)
    }
    
    func disconnect() {
        session.disconnect()
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        updateConnectionStatus()
    }
    
    func reconnect() {
        startServices()
    }
    
    private func updateConnectionStatus() {
        if connectedPeers.isEmpty {
            connectionStatus = "Searching for devices..."
            isConnected = false
        } else {
            //let peerNames = connectedPeers.map { $0.displayName }.joined(separator: ", ")
            connectionStatus = "Connected with: \(connectedPeers.count) device(s)"
            isConnected = true
        }
    }
}

// MARK: - MCSessionDelegate
extension ChatSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.connectedPeers = session.connectedPeers
            self.updateConnectionStatus()
            
            switch state {
            case .connected:
                print("Connected to \(peerID.displayName)")
            case .connecting:
                print("Connecting to \(peerID.displayName)")
            case .notConnected:
                print("Disconnected from \(peerID.displayName)")
                // Попытка переподключения
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.reconnect()
                }
            @unknown default:
                print("Unknown state: \(state)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = try? JSONDecoder().decode(Message.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                let receivedMessage = Message(
                    senderName: peerID.displayName,
                    content: message.content,
                    isFromLocalUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                self?.messages.append(receivedMessage)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Service Delegates
extension ChatSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension ChatSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectionStatus()
        }
    }
}
