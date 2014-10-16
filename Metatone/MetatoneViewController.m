//
//  MetatoneViewController.m
//  BirdsNest App View Controller.
//  Designed for Ensemble Evolution performances at PASIC 2013
//  Revised for Ensemble Metatone projects, August 2014.
//
//  Created by Charles Martin on 7/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "MetatoneViewController.h"
#import "MetatoneTouchView.h"
#import "ScaleMaker.h"
#include <stdlib.h>

#define TAP_MODE_FIELDS 0
#define TAP_MODE_MELODY 1
#define TAP_MODE_BOTH 2
#define LOOP_TIME 5000

#define SCALE_MODE_ZERO 0
#define SCALE_MODE_ONE 1
#define SCALE_MODE_TWO 2
#define SCALE_MODE_THREE 3
#define BASS_NOTE_ZERO 48
#define BASS_NOTE_ONE 44
#define BASS_NOTE_TWO 51
#define BASS_NOTE_THREE 49

#define METATONE_SCALE_MESSAGE @"SCALE"

#define METATONE_SWITCH_MESSAGE @"SWITCH"
#define METATONE_FIELDS_MESSAGE @"AUTOFIELDS"
#define METATONE_LOOP_MESSAGE @"LOOP"
#define METATONE_RESET_MESSAGE @"RESET"
#define METATONE_TAPMODE_MESSAGE @"TAPMODE"

#define NOTE_MODE_BIRDS @"chooseFromBirds"
#define NOTE_MODE_NOTES @"chooseFromNotes"
#define NOTE_MODE_ALL @"chooseFromAllSounds"
#define NOTE_MODE_ALL_XYLO @"chooseFromAllSoundsXylo"

#define SWIPE_MODE_ZERO @"swipeModeZero"
#define SWIPE_MODE_ONE @"swipeModeOne"
#define SWIPE_MODE_TWO @"swipeModeTwo"
#define SWIPE_MODE_THREE @"swipeModeThree"

#define HIGHEST_SWIPE_VELOCITY 4000.0;
//#define HIGHEST_SWIPE_VELOCITY 2500.0;


#define LOOPED_NOTE_LIMIT 200
#define STANDARD_NOTE_RANGE 30
#define MAX_NOTE_RELEASE 1500
#define MIN_NOTE_RELEASE 100

@interface MetatoneViewController () {
    NSOperationQueue *queue;
}

@property (strong,nonatomic) PdAudioController *audioController;
//@property (strong, nonatomic) CMMotionManager* motionManager;
@property (nonatomic) Boolean oscLogging;
@property (nonatomic) Boolean accelLogging;
@property (nonatomic) Boolean tapLooping;
@property (weak, nonatomic) IBOutlet UILabel *oscLoggingLabel;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGestureRecognizer;
@property (strong, nonatomic) NSMutableArray *loopedNotes;
@property (weak, nonatomic) IBOutlet MetatoneTouchView *touchView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (nonatomic) int tapMode;
@property (nonatomic) int scaleMode;
@property (nonatomic) int scene;
@property (strong, nonatomic) NSDate* timeOfLastNewIdea;
@property (strong, nonatomic) NSArray* backgroundImages;
@property (nonatomic) int startingDegree;
@property (nonatomic) int noteRange;
@property (nonatomic) int noteRelease;
@property (strong, nonatomic) NSString* noteMode;
@property (strong, nonatomic) NSString* swipeMode;
@property (nonatomic) Boolean resetChangesScene;
@property (nonatomic) int releaseMin;
@property (nonatomic) int releaseMax;
@end

@implementation MetatoneViewController

- (NSMutableArray *) loopedNotes {
    if (!_loopedNotes) _loopedNotes = [[NSMutableArray alloc] init];
    return _loopedNotes;
}

- (PdAudioController *) audioController
{
    if (!_audioController) _audioController = [[PdAudioController alloc] init];
    return _audioController;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [PdBase sendBangToReceiver:@"randomiseSounds"];
}

void arraysize_setup();

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Setup Pd Audio Controller
    if([self.audioController configurePlaybackWithSampleRate:44100 numberChannels:2 inputEnabled:YES mixingEnabled:YES] != PdAudioOK) {
        NSLog(@"failed to initialise audioController");
    } else {
        NSLog(@"audioController initialised.");
    }
    
    // Setup Pd Patch
    arraysize_setup();
    [PdBase openFile:@"birdsnestsounds.pd" path:[[NSBundle mainBundle] bundlePath]];
    [self.audioController setActive: YES];
    [self.audioController print];
    [PdBase setDelegate:self];
    [PdBase sendBangToReceiver:@"randomiseSounds"];
    
    // Setup Midi
    self.midiManager = [[MetatoneMidiManager alloc] init];
    
    // Always OSC Logging
    self.oscLogging = YES;
    [self setupOscLogging];
    
    // Set performance variables
    self.backgroundImages = @[[UIImage imageNamed:@"forest.jpg"],
                              [UIImage imageNamed:@"path.jpg"],
                              [UIImage imageNamed:@"hillpath.jpg"],
                              [UIImage imageNamed:@"treetops.jpg"]];
    self.resetChangesScene = YES;
    self.tapLooping = NO;
    self.tapMode = TAP_MODE_MELODY; // stays like this for whole performance 21/8
    self.scaleMode = 0;
    self.releaseMax = MAX_NOTE_RELEASE;
    self.releaseMin = MIN_NOTE_RELEASE;
    self.sameGestureCount = 0;
    self.scene = 0;
    self.timeOfLastNewIdea = [NSDate date];
    [self updateScene];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateScene) userInfo:Nil repeats:NO];
}



#pragma mark - Composition Methods
-(void) nextScene {
    self.scene = (self.scene + 1) % 4;
    [self updateScene];
    NSLog(@"New Scene: %d", self.scene);
}

-(void) updateBackgroundImage {
    [UIView transitionWithView:self.backgroundImage
                      duration:0.33f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self.backgroundImage setImage:self.backgroundImages[self.scene]];
                    } completion:NULL];
}

-(void) updateScene {
    switch (self.scene) {
        case 0:
            NSLog(@"Starting Scene 0");
            // Birds Only
            self.noteMode = NOTE_MODE_BIRDS;
            self.swipeMode = SWIPE_MODE_ZERO;
            self.releaseMax = 300;
            self.releaseMin = 100;
            break;
        case 1:
            NSLog(@"Starting Scene 1");
            // Birds and a bit of xylo
            self.noteMode = NOTE_MODE_ALL;
            self.swipeMode = SWIPE_MODE_ONE;
            self.releaseMax = 1000;
            self.releaseMin = 100;
            break;
        case 2:
            NSLog(@"Starting Scene 2");
            // Xylo and Blocks only
            self.noteMode = NOTE_MODE_NOTES;
            self.swipeMode = SWIPE_MODE_TWO;
            self.releaseMax = 1500;
            self.releaseMin = 500;
            break;
        case 3:
            NSLog(@"Starting Scene 3");
            // All but emphasises xylo.
            self.noteMode = NOTE_MODE_ALL_XYLO;
            self.swipeMode = SWIPE_MODE_THREE;
            self.releaseMax = 2000;
            self.releaseMin = 800;
            break;
        default:
            NSLog(@"Scene counter out of range: %d, resetting", self.scene);
            self.scene = 0;
            [self updateScene];
            break;
    }
    NSLog(@"Note Mode: %@", self.noteMode);
    [self updateScale];
    [self updateBackgroundImage];
    [self updateNoteVariables];
    [PdBase sendBangToReceiver:self.noteMode];
    [PdBase sendBangToReceiver:self.swipeMode];
}

-(void)updateScale {
    self.scaleMode = self.scene;
    [self.networkManager sendMetatoneMessage:METATONE_SCALE_MESSAGE withState:[NSString stringWithFormat:@"%d", self.scaleMode]];
}

-(void) updateNoteVariables {
    self.startingDegree = arc4random_uniform(15) - 12;
    self.noteRange = STANDARD_NOTE_RANGE;
    self.noteRelease = arc4random_uniform(self.releaseMax - self.releaseMin) + self.releaseMin;
    NSLog(@"Degree: %d, Range: %d, Release: %d", self.startingDegree, self.noteRange, self.noteRelease);
    [PdBase sendFloat:(float) self.noteRelease toReceiver:@"noteRelease"];
}

#pragma mark - Note Methods
-(void)triggerTappedNote:(CGPoint)tapPoint {
    // Send to Pd
    if (self.tapMode == TAP_MODE_FIELDS || self.tapMode == TAP_MODE_BOTH) {
        float tapDistanceProportion = [self calculateDistanceFromCenter:tapPoint]/640.0;
        [PdBase sendFloat:tapDistanceProportion toReceiver:@"tapdistance" ];
    }
    if (self.tapMode == TAP_MODE_MELODY || self.tapMode == TAP_MODE_BOTH) {
        [self sendMidiNoteFromPoint:tapPoint withVelocity:40];
    }
}

-(void)scheduleRecurringTappedNote:(CGPoint)tapPoint {
    LoopingNote *note = [[LoopingNote alloc] initWithNotePoint:tapPoint LoopTime:LOOP_TIME andDelegate:self];
    if ([self.loopedNotes count] > LOOPED_NOTE_LIMIT) {
        LoopingNote *firstNote = [self.loopedNotes objectAtIndex:0];
        [firstNote disable];
        [self.loopedNotes removeObject:firstNote];
    }
    [self.loopedNotes addObject:note];
}

-(void)clearAllLoopedNotes {
    for (LoopingNote *note in self.loopedNotes) {
        [note disable];
    }
    [self.loopedNotes removeAllObjects];
}

-(CGFloat)calculateDistanceFromCenter:(CGPoint)touchPoint {
    CGFloat xDist = (touchPoint.x - self.view.center.y);
    CGFloat yDist = (touchPoint.y - self.view.center.x);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

-(void) loopingNotePlayed:(CGPoint)notePoint {
    if (self.tapLooping) [self triggerTappedNote:notePoint];
    if (self.tapLooping) [self.touchView drawNoteCircleAt:notePoint];
}

#pragma mark - Touch Methods
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    // Velocity
    int velocity = floorf(15 + (110*((touch.majorRadius)/80)));
    NSLog(@"Velocity: %d",velocity);
    if (velocity > 127) velocity = 127;
    if (velocity < 0) velocity = 0;
    
    // Send to Pd - receiver
    if (self.tapMode == TAP_MODE_FIELDS) {
        [PdBase sendFloat:velocity/127.0 toReceiver:@"tapdistance"];
    }
    // Send to Pd as a midi note.
    if (self.tapMode == TAP_MODE_MELODY || self.tapMode == TAP_MODE_BOTH) {
        [self sendMidiNoteFromPoint:touchPoint withVelocity:velocity];
    }
    // Logging, Looping and Display.
    if (self.tapLooping) [self scheduleRecurringTappedNote:touchPoint]; // setup looping note
    if (self.oscLogging) [self.networkManager sendMessageWithTouch:touchPoint Velocity:0.0]; // osc logging
    [self.touchView drawTouchCircleAt:touchPoint]; // draw in the view
}

-(void)sendMidiNoteFromPoint:(CGPoint) point withVelocity:(int) vel
{
    CGFloat distance = [self calculateDistanceFromCenter:point]/640;
    int velocity = vel;
    int note = (int) (distance * self.noteRange) + self.startingDegree;
    
    switch (self.scaleMode) {
        case SCALE_MODE_ZERO:
            note = [ScaleMaker lydian:BASS_NOTE_ZERO withNote:note];
            break;
        case SCALE_MODE_ONE:
            note = [ScaleMaker lydian:BASS_NOTE_ONE withNote:note];
            break;
        case SCALE_MODE_TWO:
            note = [ScaleMaker phrygian:BASS_NOTE_TWO withNote:note];
            break;
        case SCALE_MODE_THREE:
            note = [ScaleMaker mixolydian:BASS_NOTE_THREE withNote:note];
            break;
        default:
            note = [ScaleMaker lydian:BASS_NOTE_ZERO withNote:note];
            break;
    }
    [PdBase sendNoteOn:1 pitch:note velocity:velocity];
    [PdBase sendAftertouch:1 value:velocity];
}

-(void)touchesMoved:(NSSet *) touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGFloat xVelocity = [touch locationInView:self.view].x - [touch previousLocationInView:self.view].x;
    CGFloat yVelocity = [touch locationInView:self.view].y - [touch previousLocationInView:self.view].y;
    CGFloat velocity = sqrt((xVelocity * xVelocity) + (yVelocity * yVelocity));
    if (self.oscLogging) [self.networkManager sendMessageWithTouch:[touch locationInView:self.view] Velocity:velocity];
    [self.touchView drawMovingTouchCircleAt:[touch locationInView:self.view]];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.oscLogging) [self.networkManager sendMessageTouchEnded];
    [self.touchView hideMovingTouchCircle];
}

- (IBAction)panGestureRecognized:(UIPanGestureRecognizer *)sender {
    CGFloat xVelocity = [sender velocityInView:self.view].x;
    CGFloat yVelocity = [sender velocityInView:self.view].y;
    CGFloat velocity = sqrt((xVelocity * xVelocity) + (yVelocity * yVelocity));
//    velocity = velocity / HIGHEST_SWIPE_VELOCITY; // changed out 23/08/2014
    velocity = log(velocity)/10; // changed in 23/08/2014
    if (velocity < 0) velocity = 0.0;
    if (velocity > 1) velocity = 1.0;
    
    if ([sender state] == UIGestureRecognizerStateBegan) {
        // send pan began message
        float tapDistanceProportion = [self calculateDistanceFromCenter:
                                       [sender locationInView:self.view]]/640.0;
        if (!tapDistanceProportion) tapDistanceProportion = 0;
        [PdBase sendFloat:tapDistanceProportion toReceiver:@"panstarted"];
    } else if ([sender state] == UIGestureRecognizerStateChanged) {
        // send normal pan changed message
        [PdBase sendFloat:velocity toReceiver:@"touchvelocity" ];
    } else if (([sender state] == UIGestureRecognizerStateEnded) || ([sender state] == UIGestureRecognizerStateCancelled)) {
        [PdBase sendBangToReceiver:@"touchended" ];
    }
}

#pragma mark - UI Buttons and Switches
// Field Recording auto play Switch
- (IBAction)fieldsOn:(UISwitch *)sender {
    if (self.oscLogging) [self.networkManager sendMesssageSwitch:@"fieldsOn" On:sender.on];
    float value = (sender.on) ? 1 : 0;
    [PdBase sendFloat:value toReceiver:@"autoField"];
}

// Loop Control Button
- (IBAction)loopingOn:(UISwitch *)sender {
    if (self.oscLogging) [self.networkManager sendMesssageSwitch:@"loopingOn" On:sender.on];
    self.tapLooping = sender.on;
    if (!sender.on) [self.loopedNotes removeAllObjects];
    if (sender.on) [self.networkManager sendMetatoneMessage:METATONE_LOOP_MESSAGE withState:@"on"];
}

// Reset Sounds Button
- (IBAction)reset:(id)sender {
    if (self.oscLogging) [self.networkManager sendMesssageSwitch:@"resetButton" On:YES];
    [PdBase sendBangToReceiver:self.noteMode];
    [PdBase sendBangToReceiver:self.swipeMode];
    [self updateNoteVariables];
    
    //    self.tapMode = 1 + ((self.tapMode + 1) % 2);

    [self.networkManager sendMetatoneMessage:METATONE_RESET_MESSAGE withState:@"reset"];
    [self.networkManager sendMetatoneMessage:METATONE_TAPMODE_MESSAGE
                                   withState:[NSString stringWithFormat:@"%d",self.tapMode]];
    if (self.resetChangesScene) {
        if (arc4random_uniform(100)>75) [self nextScene];
    }
}


#pragma mark - Network
- (void)setupOscLogging
{
    self.networkManager = [[MetatoneNetworkManager alloc] initWithDelegate:self shouldOscLog:self.oscLogging];
    if (!self.networkManager) {
        self.oscLogging = NO;
        [self.oscLoggingLabel setText:@"OSC Logging: Not Connected. 😓"];
        NSLog(@"OSC Logging: Not Connected");
        self.resetChangesScene = YES;

    }
}

-(void)stopOscLogging
{
    [self.networkManager stopSearches];
}

- (void) searchingForLoggingServer {
    if (self.oscLogging) {
        [self.oscLoggingLabel setText:@""];
        self.resetChangesScene = YES;
    }
}

-(void) loggingServerFoundWithAddress:(NSString *)address andPort:(int)port andHostname:(NSString *)hostname {
    [self.oscLoggingLabel setText:[NSString stringWithFormat:@"connected to %@ 👍", hostname]];
    [self.fieldSwitch setHidden:YES]; // get rid of fieldswitch when connected to network.
    [self.autoplayLabel setHidden:YES];
    self.resetChangesScene = NO;
}

-(void) stoppedSearchingForLoggingServer {
    if (self.oscLogging) {
        [self.oscLoggingLabel setText: @"server not found! 😰"];
        self.resetChangesScene = YES;
    }
}

-(void) didReceiveMetatoneMessageFrom:(NSString *)device withName:(NSString *)name andState:(NSString *)state {
    //NSLog([NSString stringWithFormat:@"METATONE: Received app message from:%@ with state:%@",device,state]);
    if ([name isEqualToString:METATONE_SCALE_MESSAGE]) {
        NSLog(@"METATONE: Scale Message received.");
        self.scaleMode = [state intValue];
        
    } else if ([name isEqualToString:METATONE_RESET_MESSAGE]) {
        NSLog(@"METATONE: Reset Message received.");
        if (self.resetChangesScene) {
            if (arc4random_uniform(100)>75) [self nextScene];
        }
    } else if ([name isEqualToString:METATONE_TAPMODE_MESSAGE]) {
        NSLog(@"METATONE: TapMode Message received.");
        if (arc4random_uniform(100) > 80) self.tapMode = [state intValue];
    } else if ([name isEqualToString:METATONE_LOOP_MESSAGE]) {
        if (arc4random_uniform(100)>75) {
            NSLog(@"METATONE: Loop Message Received and Actioned.");
            self.tapLooping = YES;
            [self.loopSwitch setOn:YES animated:YES];
        }
    }
}

-(void)didReceiveGestureMessageFor:(NSString *)device withClass:(NSString *)class {
}

-(void)didReceiveEnsembleState:(NSString *)state withSpread:(NSNumber *)spread withRatio:(NSNumber *)ratio {
    // Maybe do something with ensemble state?
}

-(void)didReceiveEnsembleEvent:(NSString *)event forDevice:(NSString *)device withMeasure:(NSNumber *)measure {
    if ([self.timeOfLastNewIdea timeIntervalSinceNow] < -60.0) {
        [self nextScene];
        NSLog(@"Ensemble Event Received: Next Scene.");
        self.timeOfLastNewIdea = [NSDate date];
    } else {
        NSLog(@"Ensemble Event Received: Too soon after last event!");
    }
    
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
