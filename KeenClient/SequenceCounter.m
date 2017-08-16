//
//  SequenceCounter.m
//  KeenClientExampleObjCCocoaPods
//
//  Created by Brian Baumhover on 8/15/17.
//  Copyright © 2017 Keen IO. All rights reserved.
//

#import "SequenceCounter.h"
#import <stdatomic.h>

@implementation SequenceCounter

+ (int)getSequence {
    static _Atomic(int) s_sequence = 0;
    
    return atomic_fetch_add_explicit(&s_sequence, 1, memory_order_relaxed);
}

@end
