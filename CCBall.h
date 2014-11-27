//
//  CCBall.h
//  Space Cannon
//
//  Created by Andreas Hailu on 11/26/14.
//  Copyright (c) 2014 Andreas Hailu. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface CCBall : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;
-(void)updateTrail;

@end
