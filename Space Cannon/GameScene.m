//
//  GameScene.m
//  Space Cannon
//
//  Created by Andreas Hailu on 11/21/14.
//  Copyright (c) 2014 Andreas Hailu. All rights reserved.
//

#import "GameScene.h"
#import "CCMenu.h"
#import "CCBall.h"

@implementation GameScene{
    SKNode *_mainLayer;
    SKNode *_musicLayer;
    SKNode *_haloLayer;
    CCMenu *_menu;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKLabelNode *_scoreLabel;
    SKLabelNode *_pointLabel;
    // these variables are used to group different nodes together
    BOOL didShoot;
    BOOL gameOver;
    SKAction *_haloBoomSound;
    SKAction *_deathSound;
    SKAction *_bgMusic;
    SKAction *_shieldUpSound;
    SKAction *_shootSound;
    SKAction *_bounceSound;
    NSUserDefaults *_userDefaults;
    NSMutableArray *_shieldPool;
    
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
static uint32_t SHIELDUP_CATEGORY = 0x1 << 5;
static uint32_t MULTISHOT_CATERGORY = 0x1 << 6;
static NSString * const keyTopScore = @"TopScore";

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    self.size = view.bounds.size;
    self.physicsWorld.contactDelegate = self;
    self.killCount = 0;
    self.multiShot = NO;
    
    // Load sound files
    _deathSound = [SKAction playSoundFileNamed:@"death.caf" waitForCompletion:NO];
    _bgMusic = [SKAction playSoundFileNamed:@"fncy.caf" waitForCompletion:YES];
    _haloBoomSound = [SKAction playSoundFileNamed:@"halo_boom.caf" waitForCompletion:NO];
    _shootSound = [SKAction playSoundFileNamed:@"shoot.caf" waitForCompletion:NO];
    _shieldUpSound = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
    _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
    
    // Megaman II!
    SKAction *gameMusic = [SKAction repeatActionForever:_bgMusic];
    [self runAction:gameMusic];
    
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
    
    // Add halo layer
    _haloLayer = [[SKNode alloc] init];
    [self addChild:_haloLayer];
    
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
    [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:@"SpawnHalo"];
    
    // Create spawn shield powerup action
    SKAction *spawnShieldPowerUp = [SKAction sequence:@[[SKAction waitForDuration:15 withRange:4],
                                                        [SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
    [self runAction:[SKAction repeatActionForever:spawnShieldPowerUp]];
    [self runAction:spawnShieldPowerUp];
    
    // Setup ammo
    _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
    _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
    _ammoDisplay.position = _cannon.position;
    [self addChild:_ammoDisplay];
    self.ammo = 5;
    SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1], [SKAction runBlock:^{
        if(!self.multiShot)
            self.ammo++;
    }]]];
    [self runAction:[SKAction repeatActionForever:incrementAmmo]];
    
    // Setup point multiplier label
    _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _pointLabel.position = CGPointMake(15, 30);
    _pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _pointLabel.fontSize = 15;
    [self addChild:_pointLabel];
    
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _scoreLabel.position = CGPointMake(15, 10);
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.fontSize = 15;
    [self addChild:_scoreLabel];
    
    // Setup Menu
    _menu = [[CCMenu alloc] init];
    _menu.position = CGPointMake(self.size.width*0.5, self.size.height - 220);
    [self addChild:_menu];
    
    // Instantiate initial values
    self.ammo = 5;
    self.score = 0;
    gameOver = YES;
    _scoreLabel.hidden = YES;
    _pointLabel.hidden =YES;
    
    // Load top score
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _menu.topScore = [_userDefaults integerForKey:keyTopScore];
    
    // Setup shield pool
    _shieldPool = [[NSMutableArray alloc] init];
    
    // Setup shield
    for(int i = 0; i < 6; ++i){
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shield.name = @"shield";
        shield.position = CGPointMake(35 + (50 * i), 90);
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
        shield.physicsBody.collisionBitMask = 0;
        [_shieldPool addObject:shield];
    }
    
    [_menu show];
    
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

-(void)setPointValue:(int)pointValue{
    _pointValue = pointValue;
    _pointLabel.text = [NSString stringWithFormat:@"Points: x%d", _pointValue];
}

-(void)setMultiShot:(BOOL)multiShot{
    _multiShot = multiShot;
    if (multiShot) {
        _cannon.texture = [SKTexture textureWithImageNamed:@"GreenCannon"];
    } else {
        _cannon.texture = [SKTexture textureWithImageNamed:@"Cannon"];
    }
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
    if(firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY){
        // Halo and edge collided
        [self runAction:_bounceSound];
        if([firstBody.node isKindOfClass:[CCBall class]]){
            ((CCBall*)firstBody.node).bounces++;
            if(((CCBall*)firstBody.node).bounces > 3)
                [firstBody.node removeFromParent];
        }
    }
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == BALL_CATEGORY){
        // halo and ball collided
        self.killCount++;
        if(self.killCount % 10 == 0)
            [self spawnMultiShotPowerUp];
        self.score += self.pointValue;
        [self runAction: _haloBoomSound];
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        if ([[firstBody.node.userData valueForKey:@"Multiplier"] boolValue]) {
            self.pointValue++;
        }
        if([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]){
            firstBody.node.name = nil;
            [_haloLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
                [self addExplosion:node.position withName:@"HaloExplosion"];
                [node removeFromParent];
            }];
        }
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == SHIELD_CATEGORY){
        // shield and halo collided
        [self runAction: _haloBoomSound];
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [firstBody.node removeFromParent];
        [_shieldPool addObject:secondBody.node];
        [secondBody.node removeFromParent];
    }
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == LIFEBAR_CATEGORY){
        // lifebar and halo collided, game over
        [self runAction: _deathSound];
        [self addExplosion:firstBody.node.position withName:@"LifeBarExplosion"];
        [secondBody.node removeFromParent];
        [self gameOver];
    }
    if(firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == SHIELDUP_CATEGORY){
        // Shield powerup and ball collision - give a shield back!
        [self runAction:_shieldUpSound];
        if(_shieldPool.count > 0){
            int randomIndex = arc4random_uniform((int)_shieldPool.count);
            [_mainLayer addChild:[_shieldPool objectAtIndex:randomIndex]];
            [_shieldPool removeObjectAtIndex:randomIndex];
            [firstBody.node removeFromParent];
            [secondBody.node removeFromParent];
        }
    }
    if(firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == MULTISHOT_CATERGORY){
        // multishot powerup and ball collision - 5 multishots!
        [_mainLayer enumerateChildNodesWithName:@"multiShot" usingBlock:^(SKNode *node, BOOL *stop) {
            [node removeFromParent];
        }];
        [self runAction:_shieldUpSound];
        self.multiShot = YES;
        self.ammo = 5;
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
}

-(void)newGame{
    [_menu hide];
    // Set initial values
    self.score = 0;
    self.ammo = 5;
    self.pointValue = 1;
    [self actionForKey:@"SpawnHalo"].speed = 1;
    
    _scoreLabel.hidden = NO;
    _pointLabel.hidden = NO;
    gameOver = NO;
    [_mainLayer removeAllChildren];
    [_haloLayer removeAllChildren];
     
    while(_shieldPool.count > 0){
        [_mainLayer addChild:[_shieldPool objectAtIndex:0]];
        [_shieldPool removeObjectAtIndex:0];
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
   
    [_haloLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [_shieldPool addObject:node];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    [_mainLayer removeAllChildren];
    [_musicLayer removeActionForKey:@"gameMusic"];
    
    _menu.score = self.score;
    if(self.score > _menu.topScore){
        _menu.topScore = self.score;
        /* Save this to NSUserData */
        [_userDefaults setInteger:self.score forKey:keyTopScore];
        [_userDefaults synchronize];
    }
    
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    [self runAction:[SKAction waitForDuration:1] completion:^{
        [_menu show];
    }];

    gameOver = YES;
    
}

-(void)shoot{
    // Create ball
    CCBall *ball = [CCBall spriteNodeWithImageNamed:@"Ball"];
    [self runAction:_shootSound];
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
    ball.physicsBody.contactTestBitMask = SHIELDUP_CATEGORY | MULTISHOT_CATERGORY | EDGE_CATEGORY;
    
    // Create ball's particle trail
    NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
    SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
    ballTrail.targetNode = _mainLayer;
    [_mainLayer addChild:ballTrail];
    [_mainLayer addChild:ball];
    ball.trail = ballTrail;
}



-(void)spawnHalo{
    // Increase spawn speed over time
    SKAction *spawnHaloAction = [self actionForKey:@"SpawnHalo"];
    if(spawnHaloAction.speed < 1.5){
        spawnHaloAction.speed += .01;
    }
    
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
    [_haloLayer addChild:halo];
    
    // Random point multiplier
    if(!gameOver && arc4random_uniform(6) == 0){
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"Multiplier"];
    }
    if(!gameOver && arc4random_uniform(4) == 0){
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"Bomb"];
    }

    
}

-(void)spawnShieldPowerUp{
    if(_shieldPool.count > 0){
        SKSpriteNode *shieldUp = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shieldUp.name = @"shieldUp";
        shieldUp.position = CGPointMake(self.size.width + shieldUp.size.width, randomInRange(150, self.size.height - 100));
        shieldUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shieldUp.physicsBody.categoryBitMask = SHIELDUP_CATEGORY;
        shieldUp.physicsBody.collisionBitMask = 0;
        shieldUp.physicsBody.velocity = CGVectorMake(-100, randomInRange(-40, 40));
        shieldUp.physicsBody.angularVelocity = M_PI;
        shieldUp.physicsBody.linearDamping = 0;
        shieldUp.physicsBody.angularDamping = 0;
        [_mainLayer addChild:shieldUp];
    }
}

-(void)spawnMultiShotPowerUp{
        SKSpriteNode *multiShot = [SKSpriteNode spriteNodeWithImageNamed:@"MultiShotPowerUp"];
        multiShot.name = @"multiShot";
        multiShot.position = CGPointMake(self.size.width + multiShot.size.width, randomInRange(150, self.size.height - 100));
        multiShot.physicsBody =  [SKPhysicsBody bodyWithCircleOfRadius:10];
        multiShot.physicsBody.categoryBitMask = MULTISHOT_CATERGORY;
        multiShot.physicsBody.collisionBitMask = 0;
        multiShot.physicsBody.velocity = CGVectorMake(-100, randomInRange(-40, 40));
        multiShot.physicsBody.angularVelocity = M_PI;
        multiShot.physicsBody.angularDamping = 0;
        multiShot.physicsBody.linearDamping = 0;
        [_mainLayer addChild:multiShot];
}

// We remove the node from the parent so that the physics simulator stops processing the balls
// once they have gone off screen (performance)
-(void)didSimulatePhysics{
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if(!CGRectContainsPoint(self.frame, node.position)){
            [node removeFromParent];
            self.pointValue = 1;
        }
        if([node respondsToSelector:@selector(updateTrail)]){
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0.0];
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.x + node.frame.size.width < 0){ // Node is off the screen
            [node removeFromParent];
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"multiShot" usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.x + node.frame.size.width < 0){ // Node is off the screen
            [node removeFromParent];
        }
    }];
    
    
    if (didShoot) {
        if (self.ammo > 0) {
            self.ammo--;
            [self shoot];
            if (self.multiShot) {
                for (int i = 1; i < 5; i++) {
                    [self performSelector:@selector(shoot) withObject:nil afterDelay:0.1 * i];
                }
                if (self.ammo == 0) {
                    self.multiShot = NO;
                    self.ammo = 5;
                }
            }
        }
        didShoot = NO;
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
    
    /* only want to shoot if we're in a game! */
    for (UITouch *touch in touches) {
        if(!gameOver){
            didShoot = TRUE;
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    for (UITouch *touch in touches){
        /* Starts a new game when play button is touched */
        if(gameOver && _menu.touchable){
            SKNode *n = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            if([n.name isEqual:@"Play"]){
                [self newGame];
            }
        }
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
