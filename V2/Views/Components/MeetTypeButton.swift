import SwiftUI

struct MeetTypeButton: View {
    enum Style {
        case standard
        case modern
    }
    
    let type: V2MeetType
    let isSelected: Bool
    let action: () -> Void
    var style: Style = .modern
    
    var body: some View {
        Button(action: action) {
            switch style {
            case .standard:
                standardDesign
            case .modern:
                modernDesign
            }
        }
    }
    
    private var standardDesign: some View {
        VStack {
            Image(systemName: type.iconName)
                .font(.system(size: 24))
            Text(type.displayName)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isSelected ? type.color.opacity(0.2) : Color.clear)
        .foregroundColor(isSelected ? type.color : .primary)
        .cornerRadius(10)
    }
    
    private var modernDesign: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? type.color.opacity(0.3) : Color(uiColor: UIColor.systemBackground).opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: type.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? type.color : .white.opacity(0.6))
            }
            
            Text(type.displayName)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
        }
    }
}

struct MeetTypeButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            MeetTypeButton(
                type: .car,
                isSelected: true,
                action: {},
                style: .modern
            )
            
            MeetTypeButton(
                type: .bike,
                isSelected: false,
                action: {},
                style: .standard
            )
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 