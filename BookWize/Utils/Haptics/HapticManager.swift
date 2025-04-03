//
//  HapticManager.swift
//  BookWize
//
//  Created by Lakshya Agarwal on 03/04/25.
//
import UIKit

enum HapticManager {
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // Convenience methods for common scenarios
    static func success() {
        notification(type: .success)
    }
    
    static func error() {
        notification(type: .error)
    }
    
    static func warning() {
        notification(type: .warning)
    }
    
    static func lightImpact() {
        impact(style: .light)
    }
    
    static func mediumImpact() {
        impact(style: .medium)
    }
    
    static func heavyImpact() {
        impact(style: .heavy)
    }
    
    static func softImpact() {
        impact(style: .soft)
    }
    
    static func rigidImpact() {
        impact(style: .rigid)
    }
}
