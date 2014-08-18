//
//  MetatoneViewController.h
//  Metatone
//
//  Created by Charles Martin on 7/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "PdAudioController.h"
#import "PdBase.h"
#import "LoopingNote.h"
#import "MetatoneNetworkManager.h"


@interface MetatoneViewController : UIViewController <PdReceiverDelegate, LoopingNoteDelegate,MetatoneNetworkManagerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *loopSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *fieldSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *cymbalSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *noteSwitch;
@property (strong, nonatomic) NSString* lastGesture;
@property (nonatomic) int sameGestureCount;
@property (strong,nonatomic) MetatoneNetworkManager *networkManager;

@property (weak, nonatomic) IBOutlet UILabel *autoplayLabel;
@property (weak, nonatomic) IBOutlet UILabel *loopingLabel;

- (void)setupOscLogging;
- (void)stopOscLogging;
- (void)clearAllLoopedNotes;

@end
