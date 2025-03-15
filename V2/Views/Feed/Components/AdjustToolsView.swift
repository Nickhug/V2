import SwiftUI

// MARK: - Adjust Tools View
struct AdjustToolsView: View {
    // Example adjustment controls
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 0.0
    @State private var saturation: Double = 0.0
    @State private var selectedControl: AdjustmentControl = .brightness
    
    enum AdjustmentControl: String, CaseIterable {
        case brightness = "Brightness"
        case contrast = "Contrast"
        case saturation = "Saturation"
        
        var icon: String {
            switch self {
            case .brightness: return "sun.max"
            case .contrast: return "circle.lefthalf.filled"
            case .saturation: return "drop"
            }
        }
        
        var range: ClosedRange<Double> {
            switch self {
            case .brightness: return -1.0...1.0
            case .contrast: return -1.0...1.0
            case .saturation: return -1.0...1.0
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Selector for adjustment type
            HStack(spacing: 20) {
                ForEach(AdjustmentControl.allCases, id: \.self) { control in
                    Button(action: {
                        selectedControl = control
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: control.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedControl == control ? .white : .gray)
                            
                            Text(control.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedControl == control ? .white : .gray)
                        }
                        .frame(width: 70)
                    }
                }
            }
            .padding(.bottom, 10)
            
            // Slider for selected control
            VStack(spacing: 5) {
                Text(selectedControl.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                
                // Slider with the appropriate value binding based on selection
                adjustmentSlider
                
                // Value label
                Text(String(format: "%.1f", currentValue))
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.2))
    }
    
    // Helper to get current value based on selected control
    private var currentValue: Double {
        switch selectedControl {
        case .brightness: return brightness
        case .contrast: return contrast
        case .saturation: return saturation
        }
    }
    
    // Dynamic slider that updates appropriate property
    private var adjustmentSlider: some View {
        Slider(
            value: binding,
            in: selectedControl.range,
            step: 0.1
        )
        .accentColor(.white)
    }
    
    // Dynamic binding for the selected control
    private var binding: Binding<Double> {
        switch selectedControl {
        case .brightness:
            return $brightness
        case .contrast:
            return $contrast
        case .saturation:
            return $saturation
        }
    }
} 