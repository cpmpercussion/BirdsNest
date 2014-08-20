//
//  ScaleMaker.m
//  Metatone ENP
//
//  Created by Charles Martin on 6/07/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "ScaleMaker.h"

#define DEGREE @[@1,@2,@3,@4,@5,@6,@7]
#define LYDFIVE @[@0,@2,@4,@6,@8,@9,@11]
#define LYDIAN @[@0,@2,@4,@6,@7,@9,@11]
#define MAJOR @[@0,@2,@4,@5,@7,@9,@11]
#define MIXOLYDIAN @[@0,@2,@4,@5,@7,@9,@10]
#define DORIAN @[@0,@2,@3,@5,@7,@9,@10]
#define MINOR @[@0,@2,@3,@5,@7,@8,@10]
#define PHRYGIAN @[@0,@1,@3,@5,@7,@8,@10]
#define LOCHRIAN @[@0,@1,@3,@5,@6,@8,@10]

@implementation ScaleMaker

+(int)calculateNoteFor:(NSArray *)scale withBase:(int)base andNote:(int)note {
    int octave = 0;
    int scalenote = 0;
    if (note < 0) {
        note = abs(note);
        octave = (-1 * (note / [scale count])) - 1;
        scalenote = [scale[([scale count] -1) - (note % [scale count])] intValue];
    } else {
        octave = note / [scale count];
        scalenote = [scale[note % [scale count]] intValue];
    }
    return base + (octave *12) + scalenote;
//    NSLog(@"Scale calc in:%d, octave: %d, scalenote: %d, base: %d",
//           note,octave,scalenote,base);
}

+(int)lydianSharpFive:(int)base withNote:(int)note {
    NSArray *scale = LYDFIVE;
    return [self calculateNoteFor:scale withBase:base andNote:note];
}

+(int)lydian:(int)base withNote:(int)note {
    NSArray *scale = LYDIAN;
    return [self calculateNoteFor:scale withBase:base andNote:note];
}

+(int)major:(int)base withNote:(int)note {
    NSArray *scale = MAJOR;
    return [self calculateNoteFor:scale withBase:base andNote:note];
}

+(int)dorian:(int)base withNote:(int)note {
    NSArray *scale = DORIAN;
    return [self calculateNoteFor:scale withBase:base andNote:note];
}

+(int)mixolydian:(int)base withNote:(int)note {
    NSArray *scale = MIXOLYDIAN;
    return [self calculateNoteFor:scale withBase:base andNote:note];
}

+(int)aeolian:(int)base withNote:(int)note {
    NSArray *scale = MINOR;
    return [self calculateNoteFor:scale withBase:base andNote:note];
}

+(int)phrygian:(int)base withNote:(int)note {
    NSArray *scale = PHRYGIAN;
    return [self calculateNoteFor:scale withBase:base andNote:note];
}

+(int)lochrian:(int)base withNote:(int)note {
    NSArray *scale = LOCHRIAN;
    return [self calculateNoteFor:scale withBase:base andNote:note];
}

@end
