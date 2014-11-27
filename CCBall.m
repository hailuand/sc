//
//  CCBall.m
//  Space Cannon
//
//  Created by Andreas Hailu on 11/26/14.
//  Copyright (c) 2014 Andreas Hailu. All rights reserved.
//

#import "CCBall.h"

@implementation CCBall

-(void)updateTrail{
    if(self.trail){
        self.trail.position = self.position;
    }
}

-(void)removeFromParent{
    if(self.trail){
        self.trail.particleBirthRate = 0;
        SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime
                                + self.trail.particleLifetimeRange], [SKAction removeFromParent]]];
        [self runAction:removeTrail];
    }
    [super removeFromParent];
}

@end
