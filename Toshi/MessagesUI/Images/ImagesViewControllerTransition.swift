import UIKit

enum ControllerTransitionOperation: Int {
    case present
    case dismiss
}

class ImagesViewControllerTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let operation: ControllerTransitionOperation

    private var duration: TimeInterval {
        switch operation {
        case .present:
            return 0.5
        case .dismiss:
            return 0.3
        }
    }

    var isPresenting: Bool {
        return operation == .present
    }

    init(operation: ControllerTransitionOperation) {
        self.operation = operation

        super.init()
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        if isPresenting {
            guard let tabBarController = transitionContext.viewController(forKey: .from) as? TabBarController else { return }
            guard let messagesViewController = tabBarController.messagingController.topViewController as? ChatViewController else { return }
            guard let imagesViewController = transitionContext.viewController(forKey: .to) as? ImagesViewController else { return }

            transitionContext.containerView.addSubview(imagesViewController.view)

            animate(with: transitionContext, messagesViewController, imagesViewController)
        } else {
            guard let tabBarController = transitionContext.viewController(forKey: .to) as? TabBarController else { return }
            guard let messagesViewController = tabBarController.messagingController.topViewController as? ChatViewController else { return }
            guard let imagesViewController = transitionContext.viewController(forKey: .from) as? ImagesViewController else { return }

            animate(with: transitionContext, messagesViewController, imagesViewController)
        }
    }

    func thumbnailImageView(for messagesViewController: ChatViewController, _ imagesViewController: ImagesViewController) -> UIImageView? {
        messagesViewController.view.setNeedsLayout()
        messagesViewController.view.layoutIfNeeded()

        if !isPresenting {
            messagesViewController.tableView.scrollToRow(at: imagesViewController.currentIndexPath, at: .middle, animated: false)
        }

        guard let cell = messagesViewController.tableView.cellForRow(at: imagesViewController.currentIndexPath) as? MessagesImageCell else { return nil }

        return cell.messageImageView
    }

    func fullsizeImageView(for messagesViewController: ChatViewController, _ imagesViewController: ImagesViewController) -> UIImageView? {
        imagesViewController.view.setNeedsLayout()
        imagesViewController.view.layoutIfNeeded()

        if !isPresenting {
            messagesViewController.tableView.scrollToRow(at: imagesViewController.currentIndexPath, at: .middle, animated: false)
        }
        
        guard let toCell = imagesViewController.collectionView.visibleCells.flatMap({ cell in cell as? ImageCell }).first(where: { imageCell in imageCell.frame.width != 0 }) else { return nil }

        return toCell.imageView
    }
    
    func cornerType(for messagesViewController: ChatViewController, at indexPath: IndexPath) -> MessagesCornerType? {
        guard let cell = messagesViewController.tableView.cellForRow(at: indexPath) as? MessagesBasicCell else { return nil }
        
        return cell.messagesCornerView.type
    }

    func animate(with context: UIViewControllerContextTransitioning, _ messagesViewController: ChatViewController, _ imagesViewController: ImagesViewController) {

        if !isPresenting {
            messagesViewController.tableView.scrollToRow(at: imagesViewController.currentIndexPath, at: .middle, animated: false)
        }

        guard let thumbnail = thumbnailImageView(for: messagesViewController, imagesViewController) else { return }
        guard let fullsize = fullsizeImageView(for: messagesViewController, imagesViewController) else { return }

        thumbnail.isHidden = true
        fullsize.isHidden = true

        var beginFrame = isPresenting ? context.containerView.convert(thumbnail.frame, from: thumbnail.superview) : context.containerView.convert(fullsize.frame, from: fullsize)
        var endFrame = isPresenting ? context.containerView.convert(fullsize.frame, from: fullsize) : context.containerView.convert(thumbnail.frame, from: thumbnail.superview)

        imagesViewController.view.alpha = isPresenting ? 0 : 1

        let navigationBarHeight: CGFloat = 64
        let topBarHeight: CGFloat = 48
        let bottomBarHeight: CGFloat = 51

        let fadingBackground = UIView()
        fadingBackground.backgroundColor = Theme.viewBackgroundColor
        fadingBackground.frame = CGRect(x: 0, y: navigationBarHeight, width: context.containerView.bounds.width, height: context.containerView.bounds.height - navigationBarHeight)
        fadingBackground.alpha = isPresenting ? 0 : 1
        context.containerView.addSubview(fadingBackground)

        let messagesFrame = CGRect(x: 0, y: navigationBarHeight + topBarHeight, width: context.containerView.bounds.width, height: context.containerView.bounds.height - (navigationBarHeight + topBarHeight + bottomBarHeight))
        let imageFrame = CGRect(x: 0, y: navigationBarHeight, width: context.containerView.bounds.width, height: context.containerView.bounds.height - navigationBarHeight)

        let mask = UIView()
        mask.clipsToBounds = true
        mask.frame = isPresenting ? messagesFrame : imageFrame
        context.containerView.addSubview(mask)

        beginFrame.origin.y -= isPresenting ? navigationBarHeight + topBarHeight : navigationBarHeight
        endFrame.origin.y -= isPresenting ? navigationBarHeight : navigationBarHeight + topBarHeight

        let clippingContainer = UIView()
        clippingContainer.clipsToBounds = true
        clippingContainer.frame = beginFrame
        mask.addSubview(clippingContainer)
        
        let cornerView = MessagesCornerView()
        cornerView.type = cornerType(for: messagesViewController, at: imagesViewController.currentIndexPath)
        cornerView.alpha = isPresenting ? 1 : 0
        cornerView.frame = beginFrame
        mask.addSubview(cornerView)
        
        guard let scalingImageView = fullsize.duplicate() else { return }
        scalingImageView.contentMode = fullsize.contentMode
        scalingImageView.clipsToBounds = true
        scalingImageView.frame = isPresenting ? endFrame : beginFrame
        clippingContainer.addSubview(scalingImageView)

        guard let fullsizeImageSize = fullsize.contentModeAwareImageSize() else { return }
        guard let thumbnailImageSize = thumbnail.contentModeAwareImageSize() else { return }

        let scaleFactor = thumbnailImageSize.width / fullsizeImageSize.width
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)

        scalingImageView.center = CGPoint(x: beginFrame.width / 2, y: beginFrame.height / 2)
        scalingImageView.transform = isPresenting ? scale : .identity
        
        UIView.animate(withDuration: 0.1, delay: isPresenting ? 0 : (duration - 0.1), options: [.curveEaseIn], animations: {
            cornerView.alpha = self.isPresenting ? 0 : 1
        }, completion: nil)

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
            fadingBackground.alpha = self.isPresenting ? 1 : 0
            imagesViewController.view.alpha = self.isPresenting ? 1 : 0
        }, completion: nil)

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeInOutFromCurrentStateWithUserInteraction, animations: {
            clippingContainer.frame = endFrame
            cornerView.frame = endFrame
            mask.frame = self.isPresenting ? imageFrame : messagesFrame
            scalingImageView.center = CGPoint(x: endFrame.width / 2, y: endFrame.height / 2)
            scalingImageView.transform = self.isPresenting ? .identity : scale
        }, completion: { _ in
            fadingBackground.removeFromSuperview()
            mask.removeFromSuperview()
            cornerView.removeFromSuperview()
            clippingContainer.removeFromSuperview()
            thumbnail.isHidden = false
            fullsize.isHidden = false

            context.completeTransition(!context.transitionWasCancelled)
        })
    }
}
