//
//  ViewController.h
//  ActiveInternet
//
//  Created by senthil on 03/04/25.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"


@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *appOpenTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *internetAvailableLabel;
@end

