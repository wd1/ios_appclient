// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit
import SweetUIKit

struct Word {
    let index: Int
    let text: String

    init(_ index: Int, _ text: String) {
        self.index = index
        self.text = text
    }
}

typealias Phrase = [Word]
typealias Layout = [NSLayoutConstraint]

protocol AddDelegate: class {
    func add(_ wordView: PassphraseWordView)
}

protocol RemoveDelegate: class {
    func remove(_ wordView: PassphraseWordView)
}

protocol VerificationDelegate: class {
    func verify(_ phrase: Phrase) -> VerificationStatus
}

enum PassphraseType {
    case original
    case shuffled
    case verification
}

enum VerificationStatus {
    case unverified
    case tooShort
    case correct
    case incorrect
}

class PassphraseView: UIView {

    private var type: PassphraseType = .original

    var verificationStatus: VerificationStatus = .unverified {
        didSet {
            if self.verificationStatus == .incorrect {
                DispatchQueue.main.asyncAfter(seconds: 0.5) {
                    self.shake()
                }
            } else {
                TokenUser.current?.updateVerificationState(self.verificationStatus == .correct)
            }
        }
    }

    private var originalPhrase: Phrase = []
    private var currentPhrase: Phrase = []
    private var layout: Layout = []

    let margin: CGFloat = 10
    let maxWidth = UIScreen.main.bounds.width - 30

    weak var addDelegate: AddDelegate?
    weak var removeDelegate: RemoveDelegate?
    weak var verificationDelegate: VerificationDelegate?

    var wordViews: [PassphraseWordView] = []
    var containers: [UILayoutGuide] = []

    convenience init(with originalPhrase: [String], for type: PassphraseType) {
        self.init(withAutoLayout: true)
        self.type = type

        assert(originalPhrase.count <= 12, "Too large")

        self.originalPhrase = originalPhrase.enumerated().map { index, text in Word(index, text) }
        wordViews = wordViews(for: self.originalPhrase)

        for wordView in wordViews {
            addSubview(wordView)
        }

        switch self.type {
        case .original:
            isUserInteractionEnabled = false
            currentPhrase.append(contentsOf: self.originalPhrase)
            activateNewLayout()
        case .shuffled:
            self.originalPhrase.shuffle()
            currentPhrase.append(contentsOf: self.originalPhrase)
            activateNewLayout()
        case .verification:
            backgroundColor = Theme.lightGrayBackgroundColor
            layer.cornerRadius = 4
            clipsToBounds = true
            activateNewLayout()
        }
    }

    func add(_ word: Word) {
        currentPhrase.append(word)

        deactivateLayout()
        activateNewLayout()
        animateLayout()

        wordViews.filter { wordView in
            if let index = wordView.word?.index {
                return self.currentPhrase.map { word in word.index }.contains(index)
            } else {
                return false
            }
        }.forEach { wordView in

            if word.index == wordView.word?.index {
                self.sendSubview(toBack: wordView)
                wordView.alpha = 0
            }

            UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
                wordView.alpha = 1
            }, completion: nil)
        }

        verificationStatus = verificationDelegate?.verify(currentPhrase) ?? .unverified
    }

    func remove(_ word: Word) {
        currentPhrase = currentPhrase.filter { currentWord in
            currentWord.index != word.index
        }

        deactivateLayout()
        activateNewLayout()
        animateLayout()

        wordViews.filter { wordView in

            if let index = wordView.word?.index {
                return !self.currentPhrase.map { word in word.index }.contains(index)
            } else {
                return false
            }

        }.forEach { wordView in
            wordView.alpha = 0
        }
    }

    func reset(_ word: Word) {

        wordViews.filter { wordView in
            wordView.word?.index == word.index
        }.forEach { wordView in
            wordView.isAddedForVerification = false
            wordView.isEnabled = true
            wordView.bounce()
        }
    }

    func animateLayout(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            self.superview?.layoutIfNeeded()
        }, completion: completion)
    }

    func deactivateLayout() {
        NSLayoutConstraint.deactivate(layout)

        for container in containers {
            removeLayoutGuide(container)
        }

        layout.removeAll()
    }

    func wordViews(for phrase: Phrase) -> [PassphraseWordView] {

        return phrase.map { word -> PassphraseWordView in
            let wordView = PassphraseWordView(with: word)
            wordView.isAddedForVerification = false
            wordView.addTarget(self, action: #selector(toggleAddedState(for:)), for: .touchUpInside)

            return wordView
        }
    }

    func newContainer(withOffset offset: CGFloat) -> UILayoutGuide {
        let container = UILayoutGuide()
        containers.append(container)
        addLayoutGuide(container)

        layout.append(container.centerXAnchor.constraint(equalTo: centerXAnchor))
        layout.append(container.topAnchor.constraint(equalTo: topAnchor, constant: offset))

        return container
    }

    func currentWordViews() -> [PassphraseWordView] {
        var views: [PassphraseWordView] = []

        for currentWord in currentPhrase {
            for wordView in wordViews {
                if let word = wordView.word, word.index == currentWord.index {
                    views.append(wordView)

                    if case .verification = type {
                        wordView.isAddedForVerification = false
                    }
                }
            }
        }

        return views
    }

    private func activateNewLayout() {
        var origin = CGPoint(x: 0, y: margin)
        var container = newContainer(withOffset: origin.y)
        let currentWordViews = self.currentWordViews()
        var previousWordView: UIView?

        for wordView in currentWordViews {
            let size = wordView.getSize()
            let newWidth = origin.x + size.width + margin

            if newWidth > maxWidth {
                origin.y += PassphraseWordView.height + margin
                origin.x = 0

                if let previousWordView = previousWordView {
                    layout.append(previousWordView.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -margin))
                }

                container = newContainer(withOffset: origin.y)

                previousWordView = nil
            }

            layout.append(wordView.topAnchor.constraint(equalTo: container.topAnchor))
            layout.append(wordView.leftAnchor.constraint(equalTo: previousWordView?.rightAnchor ?? container.leftAnchor, constant: margin))
            layout.append(wordView.bottomAnchor.constraint(equalTo: container.bottomAnchor))

            if let lastWordView = currentWordViews.last, lastWordView == wordView {
                layout.append(wordView.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -margin))
            }

            previousWordView = wordView
            origin.x += size.width + margin
        }

        prepareHiddenViews(for: origin)

        layout.append(container.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -margin))

        NSLayoutConstraint.activate(layout)
    }

    func prepareHiddenViews(for origin: CGPoint) {
        guard let lastContainer = containers.last else { return }

        wordViews.filter { wordView in

            if let index = wordView.word?.index {
                return !self.currentPhrase.map { word in word.index }.contains(index)
            } else {
                return false
            }

        }.forEach { wordView in
            wordView.alpha = 0

            let size = wordView.getSize()
            let newWidth = origin.x + size.width + self.margin

            self.layout.append(wordView.topAnchor.constraint(equalTo: lastContainer.topAnchor, constant: newWidth > self.maxWidth ? PassphraseWordView.height + self.margin : 0))
            self.layout.append(wordView.centerXAnchor.constraint(equalTo: lastContainer.centerXAnchor))
        }
    }

    @objc func toggleAddedState(for wordView: PassphraseWordView) {
        wordView.isAddedForVerification = !wordView.isAddedForVerification

        if wordView.isAddedForVerification {
            addDelegate?.add(wordView)
            removeDelegate?.remove(wordView)
        }
    }
}
