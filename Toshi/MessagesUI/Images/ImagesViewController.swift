import UIKit
import TinyConstraints

protocol ImagesViewControllerDismissDelegate: class {
    func imagesAreDismissed(from indexPath: IndexPath)
}

class ImagesViewController: UIViewController {

    var messages: [MessageModel] = []
    var initialIndexPath: IndexPath!
    weak var dismissDelegate: ImagesViewControllerDismissDelegate?
    var isInitialScroll: Bool = true

    var interactiveTransition: UIPercentDrivenInteractiveTransition?

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
    }()

    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal

        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        view.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .white
        view.delaysContentTouches = false
        view.isPagingEnabled = true

        return view
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let view = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        view.tintColor = Theme.tintColor

        return view
    }()

    var currentIndexPath: IndexPath {
        let collectionViewCenter = CGPoint(x: self.collectionView.contentOffset.x + (self.collectionView.bounds.width / 2), y: self.collectionView.bounds.height / 2)
        let indexPath = self.collectionView.indexPathForItem(at: collectionViewCenter)
        return indexPath ?? self.initialIndexPath
    }

    convenience init(messages: [MessageModel], initialIndexPath: IndexPath) {
        self.init()
        self.messages = messages
        self.initialIndexPath = initialIndexPath

        modalPresentationStyle = .custom
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        collectionView.top(to: view)
        collectionView.left(to: view)
        collectionView.bottom(to: view)
        collectionView.right(to: view)

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.layoutIfNeeded()
        collectionView.reloadData()

        guard let initialIndexPath = initialIndexPath else { return }
        collectionView.scrollToItem(at: initialIndexPath, at: .centeredHorizontally, animated: false)
        isInitialScroll = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        dismissDelegate?.imagesAreDismissed(from: currentIndexPath)
    }

    @objc func done(_: UIBarButtonItem) {
        dismissDelegate?.imagesAreDismissed(from: currentIndexPath)

        dismiss(animated: true, completion: nil)
    }

    @objc func pan(_ gestureRecognizer: UIPanGestureRecognizer) {

        switch gestureRecognizer.state {
        case .began:
            interactiveTransition = UIPercentDrivenInteractiveTransition()
            dismiss(animated: true, completion: nil)
        case .changed:
            let translation = gestureRecognizer.translation(in: view)
            let progress = max(translation.y / view.bounds.height, 0)
            interactiveTransition?.update(progress)
        case .ended:
            let translation = gestureRecognizer.translation(in: view)
            let velocity = gestureRecognizer.velocity(in: view)
            let shouldComplete = translation.y > 50 && velocity.y >= 0

            if shouldComplete {
                interactiveTransition?.finish()
            } else {
                interactiveTransition?.update(0)
                interactiveTransition?.cancel()
                interactiveTransition = nil
            }
        case .cancelled:
            interactiveTransition?.cancel()
            interactiveTransition = nil
        default:
            break
        }
    }
}

extension ImagesViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer == panGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            return translation.y > translation.x
        }

        return true
    }
}

extension ImagesViewController: UICollectionViewDataSource {

    func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ImageCell else { return }
        cell.imageView.image = messages[indexPath.row].image
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath)
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return messages.count
    }

    func scrollViewDidScroll(_: UIScrollView) {
        if !isInitialScroll {
            dismissDelegate?.imagesAreDismissed(from: currentIndexPath)
        }
    }
}

extension ImagesViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if messages[indexPath.row].image != nil {
            return CGSize(width: view.bounds.width, height: view.bounds.height - 64)
        }

        return CGSize(width: 0, height: view.bounds.height - 64)
    }
}
