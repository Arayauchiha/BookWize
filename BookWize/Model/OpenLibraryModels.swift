//
//  OpenLibraryModels.swift
//  Search&Browse
//
//  Created by Devashish Upadhyay on 19/03/25.
//

import Foundation

struct OpenLibraryResponse: Codable {
    let works: [OpenLibraryBook]?
    let docs: [OpenLibraryBook]?
    let numFound: Int?
    
    enum CodingKeys: String, CodingKey {
        case works
        case docs
        case numFound = "num_found"
    }
    
    var allBooks: [OpenLibraryBook] {
        if let works = works {
            return works
        } else if let docs = docs {
            return docs
        }
        return []
    }
}

struct OpenLibraryBook: Codable {
    let key: String
    let title: String
    let authorName: [String]?
    let authors: [OpenLibraryAuthor]?
    let firstPublishYear: Int?
    let isbn: [String]?
    let subject: [String]?
    let coverI: Int?
    
    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName = "author_name"
        case authors
        case firstPublishYear = "first_publish_year"
        case isbn
        case subject
        case coverI = "cover_i"
    }
    
    var book: Book {
        let coverId = if let coverI = coverI {
            String(coverI)
        } else {
            key.components(separatedBy: "/").last ?? ""
        }
        let imageURL = "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        
        let authorName = if let firstAuthor = authorName?.first {
            firstAuthor
        } else if let firstAuthor = authors?.first?.name {
            firstAuthor
        } else {
            "Unknown Author"
        }
        
        let genre: String
        if let subjects = subject {
            let normalizedSubjects = subjects.map { $0.lowercased() }
            
            // Define genre keywords for better matching
            let fictionKeywords = ["fiction", "novel", "story", "literature", "drama", "romance", "thriller", "mystery"]
            let scienceKeywords = ["science", "physics", "chemistry", "biology", "mathematics", "astronomy", "medicine", "research"]
            let historyKeywords = ["history", "historical", "ancient", "medieval", "century", "civilization", "war", "revolution"]
            let technologyKeywords = ["technology", "computer", "programming", "engineering", "software", "digital", "internet", "electronics"]
            let businessKeywords = ["business", "economics", "management", "finance", "marketing", "entrepreneurship", "leadership", "investment"]
            
            // Check for genre matches
            if normalizedSubjects.contains(where: { subject in
                fictionKeywords.contains(where: subject.contains)
            }) {
                genre = "Fiction"
            } else if normalizedSubjects.contains(where: { subject in
                scienceKeywords.contains(where: subject.contains)
            }) {
                genre = "Science"
            } else if normalizedSubjects.contains(where: { subject in
                historyKeywords.contains(where: subject.contains)
            }) {
                genre = "History"
            } else if normalizedSubjects.contains(where: { subject in
                technologyKeywords.contains(where: subject.contains)
            }) {
                genre = "Technology"
            } else if normalizedSubjects.contains(where: { subject in
                businessKeywords.contains(where: subject.contains)
            }) {
                genre = "Business"
            } else {
                // Try to find any partial match as a fallback
                let allKeywords = fictionKeywords + scienceKeywords + historyKeywords + technologyKeywords + businessKeywords
                if let matchedSubject = normalizedSubjects.first(where: { subject in
                    allKeywords.contains(where: subject.contains)
                }) {
                    // Determine genre based on the matched keyword
                    if fictionKeywords.contains(where: matchedSubject.contains) {
                        genre = "Fiction"
                    } else if scienceKeywords.contains(where: matchedSubject.contains) {
                        genre = "Science"
                    } else if historyKeywords.contains(where: matchedSubject.contains) {
                        genre = "History"
                    } else if technologyKeywords.contains(where: matchedSubject.contains) {
                        genre = "Technology"
                    } else if businessKeywords.contains(where: matchedSubject.contains) {
                        genre = "Business"
                    } else {
                        genre = "Uncategorized"
                    }
                } else {
                    genre = "Uncategorized"
                }
            }
        } else {
            genre = "Uncategorized"
        }
        
        return Book(
            id: UUID(),
            title: title,
            author: authorName,
            isbn: isbn?.first ?? "",
            genre: genre,
            publicationYear: firstPublishYear ?? 0,
            availability: .available,
            reservedBy: nil,
            imageURL: imageURL
        )
    }
}

struct OpenLibraryAuthor: Codable {
    let name: String
}