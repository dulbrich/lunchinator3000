//
//  ReviewsPageViewController.swift
//  Lunchinator 3000
//
//  Created by David Ulbrich on 7/12/17.
//  Copyright © 2017 David Ulbrich. All rights reserved.
//

import UIKit

class ReviewsPageViewController: UIPageViewController {
    
    private(set) lazy var reviewViews: [UIViewController] = {
        return [self.newReviewView(),
                self.newReviewView(),
                self.newReviewView()]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        if let firstViewController = reviewViews.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: false,
                               completion: nil)
        }
    }
    
    private func newReviewView() -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Review")
    }
    
}

extension ReviewsPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = reviewViews.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard reviewViews.count > previousIndex else {
            return nil
        }
        
        return reviewViews[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = reviewViews.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = reviewViews.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return reviewViews[nextIndex]
    }
    
    
    
}
