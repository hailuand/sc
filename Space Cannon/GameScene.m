//
//  GameScene.m
//  Space Cannon
//
//  Created by Andreas Hailu on 11/21/14.
//  Copyright (c) 2014 Andreas Hailu. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene{
    SKNode *_mainLayer;
    SKSpriteNode* _cannon;
    // these variables are used to group different nodes together
    BOOL didShoot;
}

static inline CGVector radiansToVector(CGFloat radians){
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

static inline CGFloat randomInRange(CGFloat low, CGFloat high){
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat) UINT32_MAX;
    return value * (high - low) + low;
}

static const CGFloat SHOOT_SPEED = 1000.0;
static const CGFloat HALO_LOW_ANGLE = 200.0 * M_PI / 180.0;
static const CGFloat HALO_HIGH_ANGLE = 340.0 * M_PI / 180.0;
static const CGFloat HALO_SPEED = 100.0;
static uint32_t HALO_CATEGORY = 0x1 << 0;
static uint32_t BALL_CATEGORY = 0x1 << 1;
static uint32_t EDGE_CATEGORY = 0X1 << 2;

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    self.size = view.bounds.size;
    self.physicsWorld.contactDelegate = self;
    
    // Add edges
    SKNode *leftEdge = [[SKNode alloc] init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
    leftEdge.position = CGPointZero;
    leftEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:leftEdge];
    
    SKNode *rightEdge = [[SKNode alloc] init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
    rightEdge.position = CGPointMake(self.size.width, 0.0);
    rightEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:rightEdge];
    

    // Turn off gravity - We're in space!
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    
    // Add background
    SKSpriteNode* background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    // Add main layer
    _mainLayer = [[SKNode alloc] init];
    [self addChild:_mainLayer];
    
    // Add cannon
    _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
    _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
    [_mainLayer addChild:_cannon];
    
    // Create cannon rotation actions
    SKAction* rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                  [SKAction rotateByAngle:-M_PI duration:2]]];
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    // Create spawn halo actions
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange: 1],
                           [SKAction performSelector:@selector(spawnHalo) onTarget:self ]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo]];
    
}

-(void)didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    // HALO < BALL < EDGE
    if(contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else{
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == BALL_CATEGORY){
        // halo and ball collided
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
}

-(void)shoot{
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"Ball"];
    ball.name = @"ball";
    CGVector rotationVector = radiansToVector(_cannon.zRotation);
    // Need to have the ball appear the cannon's chute, and we need to take into account
    // the rotation which is why we have rotationVector
    ball.position = CGPointMake(_cannon.position.x + _cannon.size.width * 0.5 * rotationVector.dx,
                                _cannon.position.y + _cannon.size.width * 0.5 * rotationVector.dy);
    // Modify momentum retention after interaction with other physicsBody
    
    ball.physicsBody =  [SKPhysicsBody bodyWithCircleOfRadius:6];
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
    ball.physicsBody.restitution = 1.0f;
    ball.physicsBody.linearDamping = 0.0;
    ball.physicsBody.friction = 0.0;
    ball.physicsBody.categoryBitMask = BALL_CATEGORY;
    ball.physicsBody.collisionBitMask = EDGE_CATEGORY;
    [_mainLayer addChild:ball];
}

-(void)spawnHalo{
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)),
                                self.size.height + (halo.size.height * 0.5));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];
    CGVector direction = radiansToVector(randomInRange(HALO_LOW_ANGLE, HALO_HIGH_ANGLE));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * HALO_SPEED, direction.dy * HALO_SPEED);
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.categoryBitMask = HALO_CATEGORY;
    halo.physicsBody.collisionBitMask = EDGE_CATEGORY | HALO_CATEGORY;
    halo.physicsBody.contactTestBitMask = BALL_CATEGORY;
    [_mainLayer addChild:halo];

    
}

// We remove the node from the parent so that the physics simulator stops processing the balls
// once they have gone off screen (performance)
-(void)didSimulatePhysics{
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if(!CGRectContainsPoint(self.frame, node.position))
            [node removeFromParent];
    }];
    
    if(didShoot == TRUE){
        [self shoot];
        didShoot = FALSE;
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        didShoot = TRUE;

    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
