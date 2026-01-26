import SwiftUI
import UIKit

struct JOIcon: View {
    let name: String
    let size: CGFloat
    let weight: Font.Weight
    let color: Color
    let renderingMode: Image.TemplateRenderingMode

    init(
        name: String,
        size: CGFloat,
        weight: Font.Weight = .semibold,
        color: Color,
        renderingMode: Image.TemplateRenderingMode = .template
    ) {
        self.name = name
        self.size = size
        self.weight = weight
        self.color = color
        self.renderingMode = renderingMode
    }

    var body: some View {
        if UIImage(systemName: name) != nil {
            Image(systemName: name)
                .font(.system(size: size, weight: weight))
                .foregroundStyle(color)
        } else if UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .renderingMode(renderingMode)
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
        } else {
            Image(systemName: "questionmark")
                .font(.system(size: size, weight: weight))
                .foregroundStyle(color)
        }
    }
}
