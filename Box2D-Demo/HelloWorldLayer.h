// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

#import "Box2D.h"

#import "GLES-Render.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32.0


@interface HelloWorldLayer : CCLayer {
    b2World *_world; //model of the physics world
    GLESDebugDraw *m_debugDraw; //debug mode
}

+ (id)scene;

@end