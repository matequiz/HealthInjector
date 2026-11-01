import SwiftUI
import HealthKit

struct ContentView: View {
    private let healthStore = HKHealthStore()
    @State private var stepCountText: String = "5000"
    @State private var selectedDate: Date = Date()
    @State private var statusMessage: String = "Sẵn sàng tiêm dữ liệu..."

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tùy chỉnh số liệu")) {
                    TextField("Nhập số bước chân", text: $stepCountText)
                        .keyboardType(.numberPad)
                    
                    DatePicker("Thời gian ghi nhận", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    Button(action: {
                        requestAndInjectSteps()
                    }) {
                        Text("Tiêm vào Apple Health")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }

                Section(header: Text("Trạng thái thực thi")) {
                    Text(statusMessage)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Health Injector")
        }
    }

    func requestAndInjectSteps() {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Thiết bị không hỗ trợ HealthKit!"
            return
        }

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            statusMessage = "Không khởi tạo được loại dữ liệu bước chân!"
            return
        }

        healthStore.requestAuthorization(toShare: [stepType], read: [stepType]) { success, error in
            if success {
                saveStepData(type: stepType)
            } else {
                DispatchQueue.main.async {
                    statusMessage = "Lỗi cấp quyền: \(error?.localizedDescription ?? "Không rõ")"
                }
            }
        }
    }

    func saveStepData(type: HKQuantityType) {
        guard let steps = Double(stepCountText) else {
            DispatchQueue.main.async {
                statusMessage = "Số bước chân không hợp lệ!"
            }
            return
        }

        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: steps)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: selectedDate, end: selectedDate)

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                if success {
                    statusMessage = "Đã bơm thành công \(Int(steps)) bước!"
                } else {
                    statusMessage = "Lỗi lưu dữ liệu: \(error?.localizedDescription ?? "Không rõ")"
                }
            }
        }
    }
}
