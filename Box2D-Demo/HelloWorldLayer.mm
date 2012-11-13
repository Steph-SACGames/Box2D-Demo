#import "HelloWorldLayer.h"

@implementation HelloWorldLayer

+ (id)scene {
    CCScene *scene = [CCScene node];
    HelloWorldLayer *layer = [HelloWorldLayer node];
    [scene addChild:layer];
    return scene;
}

- (id)init {
    self = [super init];
    if (self) {
        [self createWorld];
        [self createWorldBoundary];
        [self addNewBallAtPosition:CGPointMake(100, 200)];
        
        [self createResetButton];
        
        self.isAccelerometerEnabled = YES;
        self.touchEnabled = YES;

        [self schedule:@selector(tick:)]; //call a method as often as possible. It is better to call it at a set frequency, like 60 times per second, but to keep it simple, this is fine
    }
    return self;
}

- (void)dealloc {
    delete _world;
    _world = NULL;
    
#ifdef DEBUG
    delete m_debugDraw;
	m_debugDraw = NULL;
#endif
    
    [super dealloc];
}

#pragma mark - Action

- (void)tick:(ccTime)dt {
    _world->Step(dt, 10, 10); //the step function performs the physics simulation. It takes in the delta time, and number of velocity and position iteration. A range of 8-10 is usually good.

#ifndef DEBUG
    //make our sprites match our physics model
    for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) { //iterate through all the bodies
        if (b->GetUserData() != NULL) { //find ones with userData (we know that is a sprite since we set it)
            CCSprite *ballData = (CCSprite *)b->GetUserData(); //get the sprite
            ballData.position = ccp(b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO); //update the sprite's position to match the physics model
            ballData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle()); //update the sprite's rotation to match the physics model
        }
    }
#endif
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    //setup for landscape left
    b2Vec2 gravity(acceleration.y * 15, -acceleration.x *15); //set gravity to be a multiple of acceleration vector
    _world->SetGravity(gravity);
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//Add a new ball at the touched location
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		location = [[CCDirector sharedDirector] convertToGL: location]; //convert to openGL coordinates
		[self addNewBallAtPosition:location];
	}
}

#ifdef DEBUG
- (void)draw {
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	_world->DrawDebugData();
	
	kmGLPopMatrix();
}
#endif

#pragma mark - Setup

- (void)createWorld {
    // Create a world
    b2Vec2 gravity = b2Vec2(0.0f, -30.0f); //gravity is set so bodies will fall towards the bottom of the screen
    _world = new b2World(gravity);

#ifdef DEBUG
    //debug mode
    m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	_world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);
#endif
}

- (void)createWorldBoundary {
    // Create edges around the entire screen
    CGSize winSize = [CCDirector sharedDirector].winSize;

    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0,0); //define a body in lower left corner
    b2Body *groundBody = _world->CreateBody(&groundBodyDef); //have world create body
    
    b2EdgeShape groundEdge; //a shape (in this case an edge, or line) for each edge of the screen
    b2FixtureDef boxShapeDef; //a fixture definition
    boxShapeDef.shape = &groundEdge; //assign the shape to the fixture definition
    
    groundEdge.Set(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RATIO, 0)); //setup the bottom edge, remembering to convert to meters
    groundBody->CreateFixture(&boxShapeDef); //use body to create a fixture object for each edge
    
    groundEdge.Set(b2Vec2(0,0), b2Vec2(0, winSize.height/PTM_RATIO)); //setup the left edge
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(0, winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO)); //setup top edge
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, 0)); //setup right edge
    groundBody->CreateFixture(&boxShapeDef);
}

- (void)addNewBallAtPosition:(CGPoint)p {
	// Create ball body and shape
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody; //the default for bodies is static, which does not move and will not be simulated. We want the ball to move, so we set is as dynamic
    
    ballBodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
    
#ifndef DEBUG
    // Create sprite and add it to the layer
    CCSprite *ball = [CCSprite spriteWithFile:@"ball.png" rect:CGRectMake(0, 0, 26, 26)];
    ball.position = ccp(100, 100); //starting position
    [self addChild:ball]; //add the sprite to the cocos2d scene
    
    ballBodyDef.userData = ball; //we can use userData for anything we want, but it's helpful to use it to store the sprite so we can access it easily
#endif
    
    b2Body *ballBody = _world->CreateBody(&ballBodyDef);
    
    b2CircleShape circle; //this time we want a circle shape
    circle.m_radius = 26.0/PTM_RATIO; //our ball image is 52x52 pixels, or 26x26 points
    
    b2FixtureDef ballShapeDef; //setup the ball fixture
    ballShapeDef.shape = &circle;
    ballShapeDef.density = 0.8f; //mass per unit volume. The more dense an object is, the more mass it has, the harder it is to move
    ballShapeDef.friction = 0.2f; //how easily objects slide against each other, from 0 (no friction) to 1 (tons of friction).
    ballShapeDef.restitution = 0.9f; //how bouncy the ball is, from 0 (no bounce) to 1 (perfectly elastic, meaning it will bounce away with the same velocity that it impaced with)
    ballBody->CreateFixture(&ballShapeDef);
    
}

- (void)createResetButton {
	[CCMenuItemFont setFontSize:22];
    
    CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
	}]; //reset item with block action
	
	CCMenu *menu = [CCMenu menuWithItems:reset, nil]; //create menu
	
	[menu alignItemsVertically];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	[menu setPosition:ccp(size.width/2, size.height/2)]; //set menu position
	
	[self addChild: menu z:-1]; //place the menu behind the world
}


@end