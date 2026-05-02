import Foundation

public final class Lorem {

    public static var word: String {
        allWords.randomElement()!
    }

    public static var firstName: String {
        firstNames.randomElement()!
    }

    public static var lastName: String {
        lastNames.randomElement()!
    }

    public static var fullName: String {
        "\(firstName) \(lastName)"
    }

    fileprivate static let allWords = ["alias", "consequatur", "aut", "perferendis", "sit", "voluptatem", "accusantium", "doloremque", "aperiam", "eaque", "ipsa", "quae", "ab", "illo", "inventore", "veritatis", "et", "quasi", "architecto", "beatae", "vitae", "dicta", "sunt", "explicabo", "aspernatur"]

    fileprivate static let firstNames = ["Judith", "Angelo", "Margarita", "Kerry", "Elaine", "Lorenzo", "Justice", "Doris", "Raul", "Liliana", "Elise", "Ciaran", "Johnny", "Moses", "Davion", "Penny", "Mohammed", "Harvey", "Sheryl", "Hudson", "Brendan", "Brooklynn", "Denis", "Sadie", "Trisha"]

    fileprivate static let lastNames = ["Chung", "Chen", "Melton", "Hill", "Puckett", "Song", "Hamilton", "Bender", "Wagner", "McLaughlin", "McNamara", "Raynor", "Moon", "Woodard", "Desai", "Wallace", "Lawrence", "Griffin", "Dougherty", "Powers", "May", "Steele", "Teague", "Vick", "Gallagher"]
}
