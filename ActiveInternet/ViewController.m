//
//  ViewController.m
//  ActiveInternet
//
//  Created by senthil on 03/04/25.
//

#import "ViewController.h"
#define kAppOpenTime @"AppOpenTime"
#define kInternetAvailableTime @"InternetAvailableTime"

@interface ViewController ()
@property (nonatomic, strong) NSDate *appStartTime;
@property (nonatomic, strong) NSDate *internetStartTime;
@property (nonatomic, assign) NSTimeInterval totalInternetDuration;
@property (nonatomic, assign) NSTimeInterval storedAppOpenTime;
@property (nonatomic, assign) NSTimeInterval storedInternetTime;
@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Load stored values from UserDefaults
    self.storedAppOpenTime = [[NSUserDefaults standardUserDefaults] doubleForKey:kAppOpenTime];
    self.storedInternetTime = [[NSUserDefaults standardUserDefaults] doubleForKey:kInternetAvailableTime];

    self.appStartTime = [NSDate date];  // Start tracking app open time
    self.totalInternetDuration = 0;     // Reset local internet tracking

    [self startMonitoringInternet];

    // Start UI update timer (Manually checks internet every second)
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(checkInternetManually)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self stopMonitoringInternet];

    // Stop the timer
    [self.timer invalidate];
    self.timer = nil;

    // Store updated values in UserDefaults
    [self saveDataToUserDefaults];
}

// MARK: - Update UI Labels
- (void)updateLabels {
    NSTimeInterval currentAppOpenDuration = [[NSDate date] timeIntervalSinceDate:self.appStartTime];
    
    // Calculate final values (Stored + Current)
    NSTimeInterval totalAppOpenDuration = self.storedAppOpenTime + currentAppOpenDuration;

    // If internet is available, update the internet available duration
    if (self.internetStartTime) {
        NSTimeInterval activeInternetDuration = [[NSDate date] timeIntervalSinceDate:self.internetStartTime];
        self.internetAvailableLabel.text = [NSString stringWithFormat:@"%.2f sec", self.storedInternetTime + activeInternetDuration];
    } else {
        self.internetAvailableLabel.text = [NSString stringWithFormat:@"%.2f sec", self.storedInternetTime];
    }

    // Update app open time label
    self.appOpenTimeLabel.text = [NSString stringWithFormat:@"%.2f sec", totalAppOpenDuration];
}

// MARK: - Monitor Internet Connectivity
- (void)startMonitoringInternet {
    self.reachability = [Reachability reachabilityForInternetConnection];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];

    [self.reachability startNotifier];

    // 🔥 Force Initial Check (Fixes issue where network status change is not detected automatically)
    [self checkInternetManually];
}

- (void)stopMonitoringInternet {
    [self.reachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];

    // If internet was available when the app closed, save the last duration
    if (self.internetStartTime) {
        self.storedInternetTime += [[NSDate date] timeIntervalSinceDate:self.internetStartTime];
        self.internetStartTime = nil;
    }
}

// MARK: - Handle Internet Connectivity Changes
- (void)networkChanged:(NSNotification *)notification {
    [self checkInternetManually];  // 🔥 Force checking manually when network changes
}

// MARK: - Manually Check Internet Every Second (Fix for delayed detection)
- (void)checkInternetManually {
    if (!self.reachability) {
        self.reachability = [Reachability reachabilityForInternetConnection];
    }
    
    NetworkStatus status = [self.reachability currentReachabilityStatus];

    if (status != NotReachable) {
        // INTERNET RESTORED
        if (!self.internetStartTime) {
            self.internetStartTime = [NSDate date]; // Resume Tracking
            NSLog(@"Internet detected! Resuming timer.");
        }
    } else {
        // INTERNET LOST
        if (self.internetStartTime) {
            self.storedInternetTime += [[NSDate date] timeIntervalSinceDate:self.internetStartTime];
            self.internetStartTime = nil; // Pause Tracking
            NSLog(@"Internet lost! Pausing timer.");
        }
    }

    // Update UI labels
    [self updateLabels];
}

// MARK: - Save Data to UserDefaults
- (void)saveDataToUserDefaults {
    NSTimeInterval currentAppOpenDuration = [[NSDate date] timeIntervalSinceDate:self.appStartTime];
    
    // Update stored values
    self.storedAppOpenTime += currentAppOpenDuration;

    // If internet was active when closing the app, store its duration
    if (self.internetStartTime) {
        self.storedInternetTime += [[NSDate date] timeIntervalSinceDate:self.internetStartTime];
        self.internetStartTime = nil;  // Reset tracking
    }

    // Save to UserDefaults
    [[NSUserDefaults standardUserDefaults] setDouble:self.storedAppOpenTime forKey:kAppOpenTime];
    [[NSUserDefaults standardUserDefaults] setDouble:self.storedInternetTime forKey:kInternetAvailableTime];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
