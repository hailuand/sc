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
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKLabelNode *_scoreLabel;
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
static uint32_t SHIELD_CATEGORY = 0x1 << 3;
static uint32_t LIFEBAR_CATEGORY = 0x1 << 4;

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
    [self addChild:_cannon];
    
    // Create cannon rotation actions
    SKAction* rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                  [SKAction rotateByAngle:-M_PI duration:2]]];
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    // Create spawn halo actions
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange: 1],
                           [SKAction performSelector:@selector(spawnHalo) onTarget:self ]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo]];
    
    // Setup ammo
    _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
    _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
    _ammoDisplay.position = _cannon.position;
    [self addChild:_ammoDisplay];
    self.ammo = 5;
    SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1], [SKAction runBlock:^{
        self.ammo++;
    }]]];
    [self runAction:[SKAction repeatActionForever:incrementAmmo]];
    
    // Setup score display
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _scoreLabel.position = CGPointMake(15, 10);
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.fontSize = 15;
    [self addChild:_scoreLabel];
    
    [self newGame];
    
}

-(void)setAmmo:(int)ammo{
    if(ammo >= 0 && ammo <= 5){
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}

-(void)setScore:(int)score{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
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
        self.score++;
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == SHIELD_CATEGORY){
        // shield and halo collided
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == LIFEBAR_CATEGORY){
        // lifebar and halo collided, game over
        [self addExplosion:firstBody.node.position withName:@"LifeBarExplosion"];
        [secondBody.node removeFromParent];
        [self gameOver];
    }
}

-(void)newGame{
    self.ammo = 5;
    self.score = 0;
    [_mainLayer removeAllChildren];
    
    // Setup shield
    for(int i = 0; i < 6; ++i){
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shield.name = @"shield";
        shield.position = CGPointMake(35 + (50 * i), 90);
        [_mainLayer addChild:shield];
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
        shield.physicsBody.collisionBitMask = 0;
    }
    
    // Setup life bar
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:
                           CGPointMake(lifeBar.size.width * 0.5, 0)];
    lifeBar.physicsBody.categoryBitMask = LIFEBAR_CATEGORY;
    [_mainLayer addChild:lifeBar];
}

-(void)gameOver{
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    // New game after 3s
    [self performSelector:@selector(newGame) withObject:nil afterDelay:3];
}

-(void)shoot{
    if(self.ammo > 0){
        self.ammo--;
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
}

-(void)spawnHalo{
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"halo";
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
    halo.physicsBody.contactTestBitMask = BALL_CATEGORY | SHIELD_CATEGORY | LIFEBAR_CATEGORY;
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

-(void)addExplosion:(CGPoint) position withName:(NSString*)name{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    // We need to remove the explosion form the scene after it's done executing so that
    // performance doesn't get hindered.
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
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
