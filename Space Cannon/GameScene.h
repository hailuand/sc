//
//  GameScene.h
//  Space Cannon
//

//  Copyright (c) 2014 Andreas Hailu. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic) int ammo;
@property (nonatomic) int score;
@property (nonatomic) int pointValue;

@end
