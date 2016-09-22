//
//  GameView.m
//  BubbleAsteroids
//
//  Created by Eric Liang on 7/12/12.
//  Copyright (c) 2012 St.Stephen's. All rights reserved.
//

#import "GameView.h"
#include <OpenGL/gl.h>
#include <GLUT/glut.h>

#define kScreenHalfX 1.6
#define kScreenHalfY 1.0
#define kInitialAsteroidsRadius 0.13
#define kInitialBackgroundStarRadius 0.1
#define kmaxBulletNumber 300
#define kmaxAsteroidsNumber 1000
#define kmaxSpaceshipMoonNumber 10
#define kmaxBackgroundStarsNumber 50
#define kmaxGameLevel 100

#pragma mark --Image loading support--

#define numberOfImagesLoaded 8
typedef struct image_t{
unsigned int size_x;
unsigned int size_y;
unsigned char *data;
} image_t;


void drawString (char *string, double px, double py, double color[3],void *font) {
    glColor3dv(color);
    glRasterPos2d(px, py);
    while (*string) {
        glutBitmapCharacter(font, *string);
        string ++;
    }
}

image_t gImages[numberOfImagesLoaded];
NSArray* gImageFileNames;
GLuint gTextures[numberOfImagesLoaded];
char* imageNames[numberOfImagesLoaded];

static unsigned int getint(FILE* fp){
    int c, c1, c2, c3;
    
    // get 4 bytes
    c = getc(fp);  
    c1 = getc(fp);  
    c2 = getc(fp);  
    c3 = getc(fp);
    
    return ((unsigned int) c) +   
    (((unsigned int) c1) << 8) + 
    (((unsigned int) c2) << 16) +
    (((unsigned int) c3) << 24);
}
static unsigned int getshort(FILE* fp){
    int c, c1;
    
    //get 2 bytes
    c = getc(fp);  
    c1 = getc(fp);
    
    return ((unsigned int) c) + (((unsigned int) c1) << 8);
}

int ImageLoad( char* filename, image_t* image ){
    FILE *file;
    // size of the image in bytes.
    unsigned long size;
    // standard counter.
    unsigned long i;
    // number of planes in image (must be 1)
    unsigned short int planes;
    // number of bits per pixel (must be 24)
    unsigned short int bpp;
    // used to convert bgr to rgb color.
    char temp;
    
    // make sure the file is there.
    if ((file = fopen(filename, "rb"))==NULL) {
        printf("File Not Found : %s\n",filename);
        return 0;
    }
    
    // seek through the bmp header, up to the width/height:
    fseek(file, 18, SEEK_CUR);
    
    // No 100% errorchecking anymore!!!
    
    // read the width
    image->size_x = getint (file);
    printf("Width of %s: %u\n", filename, image->size_x );
    
    // read the height 
    image->size_y = getint (file);
    printf("Height of %s: %u\n", filename, image->size_y );
    
    // calculate the size (assuming 24 bits or 3 bytes per pixel).
    size = image->size_x * image->size_y * 3;
    
    // read the planes
    planes = getshort(file);
    if (planes != 1) {
        printf("Planes from %s is not 1: %u\n", filename, planes);
        return 0;
    }
    
    // read the bpp
    bpp = getshort(file);
    if (bpp != 24) {
        printf("Bpp from %s is not 24: %u\n", filename, bpp);
        return 0;
    }
    
    // seek past the rest of the bitmap header.
    fseek(file, 24, SEEK_CUR);
    
    // read the data. 
    image->data = (unsigned char*) malloc(size);
    if (image->data == NULL) {
        printf("Error allocating memory for color-corrected image data");
        return 0;	
    }
    
    if ((i = fread(image->data, size, 1, file)) != 1) {
        printf("Error reading image data from %s.\n", filename);
        return 0;
    }
    
    for (i=0;i<size;i+=3) { // reverse all of the colors. (bgr -> rgb)
        temp = image->data[i];
        image->data[i] = image->data[i+2];
        image->data[i+2] = temp;
    }
    
    // we're done.
    return 1;
}
void loadGLTexture( char* textureFileName, image_t* image, GLuint* texName ){	
    // allocate space for texture
    image = (image_t*)malloc(sizeof(image_t));
    if( image == NULL ){
        printf("Error allocating space for image");
        exit(0);
    }
    
    if( !ImageLoad(textureFileName, image) ){
        exit(1);
    }        
    
    // Create Textures
    glGenTextures( 1, texName );
    
    // linear filtered texture
    glBindTexture(GL_TEXTURE_2D, *texName);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexImage2D( GL_TEXTURE_2D, 0, 3, image->size_x, image->size_y, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, image->data );
}

#pragma mark --Data Preprocessor--
#define kFileName @"ILoveHallieAyres.plist"
//#keys in data
#define kDataKeySpaceshipHalfWidth @"f1nsd091bdfg98ud0fu"
#define kDataKeySpaceshipHalfHeight @"rg2t8udnfs9df8hg0rhib"
#define kDataKeySpaceshipColorA0 @"asdfjknasd;knda;fd"
#define kDataKeySpaceshipColorA1 @"asdfljbxckjbaldskjb"
#define kDataKeySpaceshipColorA2 @"_+DN+DSDMSDNNINDA+"
#define kDataKeySpaceshipColorB0 @"330nfudadnvipdiofnapa"
#define kDataKeySpaceshipColorB1 @"skahkhdkjhfaldhf"
#define kDataKeySpaceshipColorB2 @"asghkjshgfkjasdhgfjsdf"
#define kDataKeySpaceshipBoostSpeed @"dkfgkhgjdskgfasdfg"
#define kDataKeySpaceshipRecoil @"fbjdskadhfdkfhjbsdkajfb"
#define kDataKeySpaceshipRotationSpeed @"nsdlkanlzkjslfadlskjnasjfndlk"
#define kDataKeySpaceshipBulletSpeed @"1bdnlvcnxvnldfddnl"
#define kDataKeySpaceshipUpdateBulletInterval @"1dsjjkncjklasnkfdlbvbjl"
#define kDataKeySpaceshipEscapeCoins @"djfjklvcndfasf"
#define kDataKeySpaceshipLives @"uewygbadciauyncxahxew"
#define kDataKeyIsBulletsColorRandom @"asfkncwinuoiduaowudhxowdi"
#define kDataKeyInitialAsteroidsSpeed @"kajsdhfbkdjhfbasdjkhfbkjfhb"
#define kDataKeyPlayerScore @"wuyginweufygewuqonweiuhoiuh"
#define kDataKeySpaceshipMoonNumber @"asdfbsadnvfewihurwoerhonnsd"
#define kDataKeyGameLevel @"fn3fnsd9rqndsf08dfdsaf9n"

#pragma mark --Global Enum--
typedef enum {
    GameMenuWindow,
    GamePlayWindow,
    GameAboutWindow,
    ObjectivesWindow,
    HelpWindow,
    GameWinWindow,
    GameLoseWindow
}WindowState;

enum {
    StarIamge,
    BubbleAsteroidsIamge,
    AsteroidsMenuImage,
    ThanksToImage,
    HelpQuestionMarkImage,
    HelpInfoImage,
    YouWinImage,
    YouLoseImage
};

enum {
    MoonType1 = 1,
    MoonType2 = 2,
    MoonType3 = 3
}moonType;

#pragma mark --Global Struct--
typedef struct spaceShip { 
//drawing 
double translation[3];
double rotation;
BOOL isThrusting;
double speed[3];
int moonRotation;
unsigned short int moonRotationSpeed;
//properties
double halfWidth;
double halfHeight;
double colorA[3];
double colorB[3];
unsigned short int moonNumber;
double shipBoostSpeed;
double shipRecoil;
double shipRotationSpeed;
double bulletSpeed;

unsigned short int updateBulletInterval;
unsigned short int escapeCoins;
unsigned short int lives;
}spaceShip;

typedef struct spaceMoon {
//drawing
double rotation;
BOOL isAlive;
short int rotationSign;
//properties
double rotationSpeed;
double rotationRadius;
short int moonType;
}spaceMoon;

typedef struct asteroids {
//drawing
BOOL isAlive;
double translation[3];
double angle;
double color[3];
//properties
double radius;
double speed;
} asteroids;

typedef struct bullet {
//drawing
BOOL isAlive;
double startPoint[3];
double endPoint[3];
double position[3];
//properties
double color[3];
}buttlet;

typedef struct backgroundStars {
//drawing
double translation[3];
double radius;
double rotation;
short int rotationSign;
}backgroundStars;
double backgroundStarsSpeed;
double backgroundStarsAngle;

typedef struct powerUp {
double center[3];
double halfHeight;
double halfHidth;
}powerUp;


#pragma mark --Global Variables--

BOOL gSpacePressed, gUpPressed,gLeftPressed,gRightPressed;
WindowState windowState;

spaceShip mySpaceShip;

spaceMoon mySpaceMoon[kmaxSpaceshipMoonNumber];

backgroundStars myBackgoundStars[kmaxBackgroundStarsNumber];


buttlet mybullets[kmaxBulletNumber];
unsigned int bulletNumber;
unsigned long int updateRateCounterForBullets;
BOOL isBulletsColorRandom;


asteroids myAsteroids[kmaxAsteroidsNumber];
unsigned int asteroidsNumber;
double initialAsteroidsSpeed;

unsigned int playerScore;
unsigned int gameLevel;

@implementation GameView

#pragma mark --Data Methods


-(NSString *) saveFilePath {
    NSString* path = [NSString stringWithFormat:@"%@%@",[[NSBundle mainBundle] resourcePath],kFileName];
    return path;
}
-(void) saveData {
    NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithDouble:mySpaceShip.halfWidth]       ,kDataKeySpaceshipHalfWidth  ,
                        [NSNumber numberWithDouble:mySpaceShip.halfHeight]      ,kDataKeySpaceshipHalfHeight ,
                        [NSNumber numberWithDouble:mySpaceShip.colorA[0]]       ,kDataKeySpaceshipColorA0    ,
                        [NSNumber numberWithDouble:mySpaceShip.colorA[1]]       ,kDataKeySpaceshipColorA1    ,
                        [NSNumber numberWithDouble:mySpaceShip.colorA[2]]       ,kDataKeySpaceshipColorA2    ,
                        [NSNumber numberWithDouble:mySpaceShip.colorB[0]]       ,kDataKeySpaceshipColorB0    ,
                        [NSNumber numberWithDouble:mySpaceShip.colorB[1]]       ,kDataKeySpaceshipColorB1    ,
                        [NSNumber numberWithDouble:mySpaceShip.colorB[2]]       ,kDataKeySpaceshipColorB2    ,
                        [NSNumber numberWithDouble:mySpaceShip.shipBoostSpeed]  ,kDataKeySpaceshipBoostSpeed ,
                        [NSNumber numberWithDouble:mySpaceShip.shipRecoil]      ,kDataKeySpaceshipRecoil     ,
                        [NSNumber numberWithDouble:mySpaceShip.shipRotationSpeed],kDataKeySpaceshipRotationSpeed,
                        [NSNumber numberWithDouble:mySpaceShip.bulletSpeed]     ,kDataKeySpaceshipBulletSpeed,
                        [NSNumber numberWithUnsignedShort:mySpaceShip.updateBulletInterval],kDataKeySpaceshipUpdateBulletInterval,
                        [NSNumber numberWithUnsignedShort:mySpaceShip.escapeCoins],kDataKeySpaceshipEscapeCoins,
                        [NSNumber numberWithUnsignedShort:mySpaceShip.lives]    ,kDataKeySpaceshipLives,
                        [NSNumber numberWithBool:isBulletsColorRandom]          ,kDataKeyIsBulletsColorRandom,
                        [NSNumber numberWithDouble:initialAsteroidsSpeed]       ,kDataKeyInitialAsteroidsSpeed,
                        [NSNumber numberWithInt:playerScore]                    ,kDataKeyPlayerScore         ,
                        [NSNumber numberWithUnsignedShort:mySpaceShip.moonNumber],kDataKeySpaceshipMoonNumber,
                        [NSNumber numberWithUnsignedShort:gameLevel]            ,kDataKeyGameLevel,
                        
                        nil];
    [dict writeToFile:[self saveFilePath] atomically:YES];
}
-(void) loadSavedDataFromFileOrInitialize {
    if ([[NSFileManager defaultManager]fileExistsAtPath:[self saveFilePath]]) {
        NSDictionary *dictionary=[[NSDictionary alloc]initWithContentsOfFile:[self saveFilePath]];
        mySpaceShip.halfWidth=[[dictionary objectForKey:kDataKeySpaceshipHalfWidth]doubleValue];
        mySpaceShip.halfHeight=[[dictionary objectForKey:kDataKeySpaceshipHalfHeight]doubleValue];
        mySpaceShip.colorA[0]=[[dictionary objectForKey:kDataKeySpaceshipColorA0]doubleValue];
        mySpaceShip.colorA[1]=[[dictionary objectForKey:kDataKeySpaceshipColorA1]doubleValue];
        mySpaceShip.colorA[2]=[[dictionary objectForKey:kDataKeySpaceshipColorA2]doubleValue];
        mySpaceShip.colorB[0]=[[dictionary objectForKey:kDataKeySpaceshipColorB0]doubleValue];
        mySpaceShip.colorB[1]=[[dictionary objectForKey:kDataKeySpaceshipColorB1]doubleValue];
        mySpaceShip.colorB[2]=[[dictionary objectForKey:kDataKeySpaceshipColorB2]doubleValue];
        mySpaceShip.shipBoostSpeed=[[dictionary objectForKey:kDataKeySpaceshipBoostSpeed]doubleValue];
        mySpaceShip.shipRecoil=[[dictionary objectForKey:kDataKeySpaceshipRecoil]doubleValue];
        mySpaceShip.shipRotationSpeed=[[dictionary objectForKey:kDataKeySpaceshipRotationSpeed]doubleValue];
        mySpaceShip.bulletSpeed=[[dictionary objectForKey:kDataKeySpaceshipBulletSpeed]doubleValue];
        mySpaceShip.updateBulletInterval=[[dictionary objectForKey:kDataKeySpaceshipUpdateBulletInterval]unsignedShortValue];
        mySpaceShip.escapeCoins=[[dictionary objectForKey:kDataKeySpaceshipEscapeCoins]unsignedShortValue];
        mySpaceShip.lives=[[dictionary objectForKey:kDataKeySpaceshipLives]unsignedShortValue];
        isBulletsColorRandom=[[dictionary objectForKey:kDataKeyIsBulletsColorRandom]boolValue];
        initialAsteroidsSpeed=[[dictionary objectForKey:kDataKeyInitialAsteroidsSpeed]doubleValue];
        playerScore=[[dictionary objectForKey:kDataKeyPlayerScore]intValue];
        mySpaceShip.moonNumber=[[dictionary objectForKey:kDataKeySpaceshipMoonNumber]unsignedShortValue];
        gameLevel=[[dictionary objectForKey:kDataKeyGameLevel]unsignedShortValue];
        
    }
    else {
        mySpaceShip.halfWidth=0.02;
        mySpaceShip.halfHeight=0.05;
        mySpaceShip.colorA[0]=1.0;
        mySpaceShip.colorA[1]=1.0;
        mySpaceShip.colorA[2]=1.0;
        mySpaceShip.colorB[0]=1.0;
        mySpaceShip.colorB[1]=1.0;
        mySpaceShip.colorB[2]=1.0;
        mySpaceShip.shipBoostSpeed=0.0002;
        mySpaceShip.shipRecoil=0.0005;
        mySpaceShip.shipRotationSpeed=5;
        mySpaceShip.bulletSpeed=0.01;
        mySpaceShip.updateBulletInterval=6;
        mySpaceShip.escapeCoins=10;
        mySpaceShip.lives=3;
        isBulletsColorRandom=NO;
        initialAsteroidsSpeed=0.002;
        playerScore=0;
        mySpaceShip.moonNumber=0;
        gameLevel=1;
        if (mySpaceShip.moonNumber>kmaxSpaceshipMoonNumber) {
            mySpaceShip.moonNumber=kmaxSpaceshipMoonNumber;
        }
    }
}

-(void) initializeData {
    //srand( time(NULL) );

    
    NSString *fileNameOne=[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"Star.bmp"];
    NSString *fileNameTwo=[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"BubbleAsteroids.bmp"];
    NSString *fileNameThree=[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"AsteroidsMenu.bmp"];
    NSString *fileNameFour=[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"ThanksTo.bmp"];
    NSString *fileNameFive=[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"HelpQuestionMark.bmp"];
    NSString *fileNameSix=[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"HelpInfo.bmp"];
    NSString *fileNameSeven=[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"YouWinLabel.bmp"];
    NSString *fileNameEight=[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"YouLoseLabel.bmp"];
    gImageFileNames=[NSArray arrayWithObjects:fileNameOne,fileNameTwo,fileNameThree,fileNameFour,fileNameFive,fileNameSix,fileNameSeven,fileNameEight, nil];

    
    gSpacePressed= gUpPressed=gLeftPressed=gRightPressed=NO;
    updateRateCounterForBullets=0;
    
    //init spaceship drawing
    mySpaceShip.translation[0]=0.0;
    mySpaceShip.translation[1]=0.0;
    mySpaceShip.translation[2]=0.0;
    
    mySpaceShip.speed[0]=0.0;
    mySpaceShip.speed[1]=0.0;
    mySpaceShip.speed[2]=0.0;
    mySpaceShip.rotation=90;
    mySpaceShip.moonRotationSpeed=4;
    
    //drawing
    bulletNumber=0;
    mySpaceShip.isThrusting=NO;
    
    [self loadSavedDataFromFileOrInitialize];
    
    for (int i=0; i<kmaxSpaceshipMoonNumber; i++) {
        mySpaceMoon[i].rotationSpeed=(10-i)/3+0.5;
        
        mySpaceMoon[i].rotationRadius=0.04+i*0.05;
        mySpaceMoon[i].isAlive=NO;
        mySpaceMoon[i].rotation=(int)((double)rand()/(double)RAND_MAX*360);
        mySpaceMoon[i].moonType=i%3;
    }
    for (int i=0; i<mySpaceShip.moonNumber; i++) {
        mySpaceMoon[i].isAlive=YES;
    }
    
    //init bullets
    for (int i=0; i<kmaxBulletNumber;i++) {
        if (isBulletsColorRandom) {
            mybullets[i].color[0]=(double)rand()/(double)RAND_MAX;
            mybullets[i].color[1]=(double)rand()/(double)RAND_MAX;
            mybullets[i].color[2]=(double)rand()/(double)RAND_MAX;
        }
        else {
            mybullets[i].color[0]=1.0;
            mybullets[i].color[1]=1.0;
            mybullets[i].color[2]=1.0;
        }
        mybullets[i].isAlive=NO;
    }
    for (int i=0; i<kmaxSpaceshipMoonNumber; i++) {
        double sign = 1.0;
        if( rand( ) % 2 ){
            sign = -1.0;
        }
        mySpaceMoon[i].rotationSign=(int)sign;
    }
    //setup asteroids
    for (int i=0; i<kmaxAsteroidsNumber; i++) {
        myAsteroids[i].isAlive=NO;
        myAsteroids[i].radius=kInitialAsteroidsRadius;        
        double signX = 1.0;
        if( rand( ) % 2 ){
            signX = -1.0;
        }
        double signY = 1.0;
        if( rand( ) % 2 ){
            signY = -1.0;
        }
        myAsteroids[i].translation[0]=(double)rand()/(double)RAND_MAX *signX*kScreenHalfX;
        myAsteroids[i].translation[1]=(double)rand()/(double)RAND_MAX *signY*kScreenHalfY;
        myAsteroids[i].translation[2]=0.0;
        
        while ((myAsteroids[i].translation[0]<0.2 && myAsteroids[i].translation[0]>-0.2) || (myAsteroids[i].translation[0]<0.2 && myAsteroids[i].translation[0]>-0.2)) {
            myAsteroids[i].translation[0]=(double)rand()/(double)RAND_MAX *signX*kScreenHalfX;
            myAsteroids[i].translation[1]=(double)rand()/(double)RAND_MAX *signY*kScreenHalfY;
        }
        myAsteroids[i].color[0]=(double)rand()/(double)RAND_MAX;
        myAsteroids[i].color[1]=(double)rand()/(double)RAND_MAX;
        myAsteroids[i].color[2]=(double)rand()/(double)RAND_MAX;
        myAsteroids[i].angle=(double)rand()/(double)RAND_MAX*360;
        myAsteroids[i].speed=initialAsteroidsSpeed;
    }
    
    asteroidsNumber=gameLevel/2+1;    
    //init asteroids
    for (int i=0; i<asteroidsNumber; i++) {
        myAsteroids[i].isAlive=YES;
    } 
    
    //setup background stars
    
    for (int i=0; i<kmaxBackgroundStarsNumber; i++) {
        myBackgoundStars[i].radius=kInitialBackgroundStarRadius*(double)rand()/(double)RAND_MAX;
        
        double signX = 1.0;
        if( rand( ) % 2 ){
            signX = -1.0;
        }
        double signY = 1.0;
        if( rand( ) % 2 ){
            signY = -1.0;
        }
        
        myBackgoundStars[i].translation[0]=(double)rand()/(double)RAND_MAX *signX*kScreenHalfX;
        myBackgoundStars[i].translation[1]=(double)rand()/(double)RAND_MAX *signY*kScreenHalfY;
        myBackgoundStars[i].translation[2]=0.0;
        myBackgoundStars[i].rotation=(int)((double)rand()/(double)RAND_MAX*360);
        
        myBackgoundStars[i].rotationSign=1.0;
        if (rand( ) % 2 ) {
            myBackgoundStars[i].rotationSign=-1.0;
        }
    }
    backgroundStarsSpeed=initialAsteroidsSpeed/5;
    backgroundStarsAngle=(double)rand()/(double)RAND_MAX*360;
}

#pragma mark --user interface methods
-(BOOL) enoughEscapeCoins: (spaceShip *)aShip {
    BOOL returnValue=YES;
    if ((aShip->escapeCoins)<=0) {
        returnValue=NO;
        aShip->escapeCoins=0;
    }
    return returnValue;
}
-(void) escape:(spaceShip *)aShip {
    if ([self enoughEscapeCoins:aShip]) {
        double sign = 1.0;
        if( rand( ) % 2 ){
            sign = -1.0;
        }
        aShip->translation[0]=(double)rand()/(double)RAND_MAX *sign*kScreenHalfX;
        aShip->translation[1]=(double)rand()/(double)RAND_MAX *sign*kScreenHalfY;
        aShip->translation[2]=0.0;
        aShip->speed[0]=0.0;
        aShip->speed[1]=0.0;
        aShip->speed[2]=0.0;
        aShip->escapeCoins-=1;
    }
}
-(void)keyDown:(NSEvent *)theEvent {
    unichar c = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    switch (c) {
        case 27:
            if (windowState==GameMenuWindow) {
                [self saveData];
                exit(0);
            }
            else {
                windowState=GameMenuWindow;
            }
            break;
        case 32:
            gSpacePressed=YES;
            break;  
        case 13:
            if (windowState!=GamePlayWindow) {
                windowState=GamePlayWindow;
                [self updateView];
            }
            break;
        case '1':
            if (windowState!=ObjectivesWindow) {
                windowState=ObjectivesWindow;
                [self updateView];
            }
            break;
        case '2':
            if (windowState!=HelpWindow) {
                windowState=HelpWindow;
                [self updateView];
            }
            break;    
        case '3':
            if (windowState!=GameAboutWindow) {
                windowState=GameAboutWindow;
                [self updateView];
            }
            break;
        case NSUpArrowFunctionKey:       // up arrow
            gUpPressed=YES;
            break;
        case NSDownArrowFunctionKey:       // down arrow
            [self escape:&mySpaceShip];
            break;
        case NSRightArrowFunctionKey:       // right arrow
            gRightPressed=YES;
            break;
        case NSLeftArrowFunctionKey:       // left arrow
            gLeftPressed=YES;
            break;
    }
}

-(void)keyUp:(NSEvent *)theEvent {
    unichar c = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    switch (c) {
        case 32:
            gSpacePressed=NO;
            break;
        case NSUpArrowFunctionKey:
            gUpPressed=NO;
            mySpaceShip.isThrusting=NO;
            break;
        case NSRightArrowFunctionKey:
            gRightPressed=NO;
            break;
        case NSLeftArrowFunctionKey:
            gLeftPressed=NO;
            break;
    }
}

- (void) awakeFromNib 
{
    [self enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
    windowState=GameMenuWindow;
    NSString *popSoundResourcePath = [[NSBundle mainBundle] pathForResource:@"pop" ofType:@"wav"];
    popSound=[[NSSound alloc]initWithContentsOfFile:popSoundResourcePath byReference:YES];
    popSound.volume=0.1;
    
    NSString *MissyouResourcePath = [[NSBundle mainBundle] pathForResource:@"Fanticia" ofType:@"mp3"];
    backgroundMusic=[[NSSound alloc]initWithContentsOfFile:MissyouResourcePath byReference:YES];
    backgroundMusic.volume=1.0;
    [backgroundMusic setDelegate:self];
    [backgroundMusic play];

    NSTimer *timer=[NSTimer timerWithTimeInterval:(1.0f/60.0f) target:self selector:@selector(updateView) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}

#pragma mark --Display Functions
-(void)drawBackgroundStars {
    for (int i=0; i<kmaxBackgroundStarsNumber; i++) {
        glPushMatrix();
        glEnable(GL_TEXTURE_2D);
        glBindTexture( GL_TEXTURE_2D, gTextures[StarIamge] );
        glTranslated(myBackgoundStars[i].translation[0], myBackgoundStars[i].translation[1], myBackgoundStars[i].translation[2]);
        glRotated(myBackgoundStars[i].rotation, 0.0, 0.0, 1.0);
        //glTranslated(-myBackgoundStars[i].translation[0], -myBackgoundStars[i].translation[1], myBackgoundStars[i].translation[2]);
        
        glBegin(GL_QUADS);
        glTexCoord2f(0.0f, 0.0f); glVertex3f( -myBackgoundStars[i].radius, -myBackgoundStars[i].radius, 0.0f );
        glTexCoord2f(1.0f, 0.0f); glVertex3f( myBackgoundStars[i].radius, -myBackgoundStars[i].radius, 0.0f );
        glTexCoord2f(1.0f, 1.0f); glVertex3f( myBackgoundStars[i].radius, myBackgoundStars[i].radius, 0.0f );
        glTexCoord2f(0.0f, 1.0f); glVertex3f( -myBackgoundStars[i].radius, myBackgoundStars[i].radius, 0.0f );
        glEnd();
        glDisable(GL_TEXTURE_2D);
        glPopMatrix();        
    }
}

-(void)gamePlayDisplay {
    
    //draw ship
    glPushMatrix();
    glTranslated(mySpaceShip.translation[0], mySpaceShip.translation[1], 0.0);
    glRotated(mySpaceShip.rotation, 0.0, 0.0, 1.0);
    glTranslated(-mySpaceShip.translation[0], -mySpaceShip.translation[1], 0.0);
    glLineWidth(4);
    glBegin(GL_LINE_LOOP);
    glColor3dv(mySpaceShip.colorA);
    glVertex3d(mySpaceShip.translation[0]-mySpaceShip.halfHeight,mySpaceShip.translation[1]+mySpaceShip.halfWidth,0.0);
    glVertex3d(mySpaceShip.translation[0]-mySpaceShip.halfHeight,mySpaceShip.translation[1]-mySpaceShip.halfWidth,0.0);
    glColor3dv(mySpaceShip.colorB);
    glVertex3d(mySpaceShip.translation[0]+mySpaceShip.halfWidth,mySpaceShip.translation[1],0.0 );
    glEnd();
    glDisable(GL_LINE_WIDTH);
    //draw thrust
    if (mySpaceShip.isThrusting) {
        glBegin(GL_TRIANGLES);
        glColor3d(1.0, 1.0, 0.0);
        glVertex3d(mySpaceShip.translation[0]-mySpaceShip.halfHeight, mySpaceShip.translation[1]+mySpaceShip.halfWidth/2, 0.0);
        glColor3d(1.0, 0.0, 0.0);
        glVertex3d(mySpaceShip.translation[0]-mySpaceShip.halfHeight*1.7, mySpaceShip.translation[1], 0.0);
        glColor3d(1.0, 1.0, 0.0);
        glVertex3d(mySpaceShip.translation[0]-mySpaceShip.halfHeight, mySpaceShip.translation[1]-mySpaceShip.halfWidth/2, 0.0);
        glEnd();
    }
    glPopMatrix();
    
    
    //draw moons
    for (int i=0; i <kmaxSpaceshipMoonNumber; i++) {
        if (mySpaceMoon[i].isAlive) {
            glPushMatrix();
            glEnable(GL_TEXTURE_2D);
            glBindTexture( GL_TEXTURE_2D, gTextures[StarIamge] );
            glTranslated(mySpaceShip.translation[0], mySpaceShip.translation[1], 0.0);
            glRotated(mySpaceMoon[i].rotation, 0.0, 0.0, 1.0);
            glTranslated(-mySpaceShip.translation[0], -mySpaceShip.translation[1], 0.0);
            glBegin( GL_QUADS );
            glTexCoord2f(0.0f, 0.0f); glVertex3f( mySpaceShip.translation[0]+mySpaceShip.halfHeight+mySpaceMoon[i].rotationRadius, mySpaceShip.translation[1]-0.025f, 0.0f );
            glTexCoord2f(1.0f, 0.0f); glVertex3f( mySpaceShip.translation[0]+mySpaceShip.halfHeight+mySpaceMoon[i].rotationRadius+0.05, mySpaceShip.translation[1]-0.025f, 0.0f );
            glTexCoord2f(1.0f, 1.0f); glVertex3f( mySpaceShip.translation[0]+mySpaceShip.halfHeight+mySpaceMoon[i].rotationRadius+0.05, mySpaceShip.translation[1]+ 0.025f, 0.0f );
            glTexCoord2f(0.0f, 1.0f); glVertex3f( mySpaceShip.translation[0]+mySpaceShip.halfHeight+mySpaceMoon[i].rotationRadius, mySpaceShip.translation[1]+ 0.025f, 0.0f );
            glEnd( );
            glDisable(GL_TEXTURE_2D);
            glPopMatrix();
        }
    }
    
    
    //draw asteroids
    for(int i = 0; i < kmaxAsteroidsNumber; i++ ){
        if (myAsteroids[i].isAlive) {
            glPushMatrix( );
            glTranslated(myAsteroids[i].translation[0], myAsteroids[i].translation[1], myAsteroids[i].translation[2]);
            glLineWidth(3);
            glBegin( GL_LINE_LOOP );
            for (double a=0.0; a<2*M_PI; a+=0.1) {
                float alpha=a;
                float beta=(a+1);
                glColor3dv(myAsteroids[i].color);
                glVertex3d(cosf(alpha)*myAsteroids[i].radius,sinf(alpha)*myAsteroids[i].radius, 0.0);
                glVertex3d(cosf(beta)*myAsteroids[i].radius,sinf(beta)*myAsteroids[i].radius, 0.0);
            }
            glEnd( );
            glPopMatrix();
        }
    }
    
    //draw lives
    for (int i=0; i<mySpaceShip.lives; i++) {
        glPushMatrix();
        glTranslated(-(1.5-(double)(i*0.07)), 0.95, 0.0);
        glRotated(90, 0.0, 0.0, 1.0);
        glTranslated(1.5-(double)(i*0.07), -0.95, 0.0);
        glLineWidth(4);
        glBegin(GL_LINE_LOOP);
        glColor3dv(mySpaceShip.colorA);
        glVertex3d(-(1.5-(double)(i*0.07))-mySpaceShip.halfHeight,0.95+mySpaceShip.halfWidth,0.0);
        glVertex3d(-(1.5-(double)(i*0.07))-mySpaceShip.halfHeight,0.95-mySpaceShip.halfWidth,0.0);
        glColor3dv(mySpaceShip.colorB);
        glVertex3d(-(1.5-(double)(i*0.07))+mySpaceShip.halfWidth,0.95,0.0 );
        glEnd();
        glPopMatrix();
    }
    //draw bullets
    for (int i=0; i<kmaxBulletNumber; i++) {
        
        if (mybullets[i].isAlive) {
            glPushMatrix();
            glPointSize(8);
            glEnable(GL_POINT_SMOOTH);
            glBegin(GL_POINTS);
            glColor3dv(mybullets[i].color);
            glVertex3dv(mybullets[i].position);
            glPopMatrix();
            glEnd();
        }
    }
    
    
    
    
    const char *str="score %d";
    char buffer[40];
    sprintf(buffer, str,playerScore);
    double textColor[3]={1.0,1.0,1.0};
    drawString( (char *)buffer, -0.05, 0.9,textColor,GLUT_BITMAP_HELVETICA_18);
     

    //draw background Stars
    [self drawBackgroundStars];

}
-(void)gameMenuDisplay {
    //draw back ground stars
    [self drawBackgroundStars];

    //load title image
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[BubbleAsteroidsIamge] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -1.0, 0.08, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0 , 0.08, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0 , 1.08, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -1.0, 1.08, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    //load menu image
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[AsteroidsMenuImage] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -1.0, -0.9, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0 , -0.9, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0 , 0.08, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -1.0, 0.08, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
}
-(void)gameAboutDisplay {
    //draw back ground stars
    [self drawBackgroundStars];

    
    //load title image
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[BubbleAsteroidsIamge] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -1.0, 0.08, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0 , 0.08, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0 , 1.08, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -1.0, 1.08, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    
    //load thanks_to image
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[ThanksToImage] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -0.9, -1.0, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 0.9 , -1.0, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 0.9 , 0.2, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -0.9, 0.2, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    
}
-(void)objectivesDisplay {
    //draw back ground stars
    [self drawBackgroundStars];
    
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[BubbleAsteroidsIamge] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -1.0, 0.08, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0 , 0.08, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0 , 1.08, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -1.0, 1.08, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
}
-(void)helpDisplay {
    //draw back ground stars
    [self drawBackgroundStars];
    
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[BubbleAsteroidsIamge] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -1.0, 0.08, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0 , 0.08, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0 , 1.08, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -1.0, 1.08, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    
    //draw help mark
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[HelpQuestionMarkImage] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( 0.8, 0.0, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.6 , 0.0, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.6 , 1.00, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( 0.8, 1.00, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[HelpInfoImage] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -1.0, -0.9, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0 , -0.9, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0 , 0.0, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -1.0, 0.0, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
}
-(void)winDisplay {
    //draw back ground stars
    [self drawBackgroundStars];
    
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[YouWinImage] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -1.0, 0.08, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0 , 0.08, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0 , 1.08, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -1.0, 1.08, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    
    /*
    const char *str="Level %d";
    char buffer[40];
    sprintf(buffer, str,gameLevel);
    double textColor[3]={1.0,1.0,1.0};
    drawString( (char *)buffer, -0.05, 0.2,textColor,GLUT_BITMAP_TIMES_ROMAN_24);
     */
}
-(void)loseDisplay {
    //draw back ground stars
    [self drawBackgroundStars];
    
    glPushMatrix();
    glEnable(GL_TEXTURE_2D);
    glBindTexture( GL_TEXTURE_2D, gTextures[YouLoseImage] );
    glBegin( GL_QUADS );
    glTexCoord2f(0.0f, 0.0f); glVertex3f( -1.0, 0.08, 0.0 );
    glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0 , 0.08, 0.0 );
    glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0 , 1.08, 0.0 );
    glTexCoord2f(0.0f, 1.0f); glVertex3f( -1.0, 1.08, 0.0 );
    glEnd( );
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    
    const char *str="Level %d";
    char buffer[40];
    sprintf(buffer, str,gameLevel);
    double textColor[3]={1.0,1.0,1.0};
    drawString( (char *)buffer, -0.05, 0.2,textColor,GLUT_BITMAP_TIMES_ROMAN_24);
}
- (void) drawRect:(NSRect)rect { 
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glMatrixMode(GL_MODELVIEW); 
    glLoadIdentity();
    /*
    double offset=0.005;
    glColorMask(true, true, true, true);
    glClear(GL_COLOR_BUFFER_BIT);
    glTranslatef(+offset, 0.0, 0.0);
    glColorMask(true, false, false, false);
    */
    
    
    switch (windowState) {
        case GameMenuWindow:
            [self gameMenuDisplay];
            break;
        case GamePlayWindow:
            [self gamePlayDisplay];
            break;
        case GameAboutWindow:
            [self gameAboutDisplay];
            break;
        case ObjectivesWindow:
            [self objectivesDisplay];
            break;
        case HelpWindow:
            [self helpDisplay];
            break;
        case GameWinWindow:
            [self winDisplay];
            break;
        case GameLoseWindow:
            [self loseDisplay];
            break;
    }
    /*
    glLoadIdentity();
    glClear(GL_DEPTH_BUFFER_BIT) ;
    glColorMask(false, true, true, false);
    glTranslatef(-offset, 0.0, 0.0);
    
    switch (windowState) {
        case GameMenuWindow:
            [self gameMenuDisplay];
            break;
        case GamePlayWindow:
            [self gamePlayDisplay];
            break;
        case GameAboutWindow:
            [self gameAboutDisplay];
            break;
        case ObjectivesWindow:
            [self objectivesDisplay];
            break;
        case HelpWindow:
            [self helpDisplay];
            break;
        case GameWinWindow:
            [self winDisplay];
            break;
        case GameLoseWindow:
            [self loseDisplay];
            break;
    }
    */
    
    // i'm not using doublebuffering, so i should not need flushBuffer: 
    //if ([self inLiveResize]) 
    glFlush();
    //else 
    [[self openGLContext] flushBuffer]; 
} 

#pragma mark --Update Functions
//Gameplay update support

-(void) checkBulletsCollsionWithAsteroids{
    for (int b=0; b<kmaxBulletNumber; b++) {
        for (int a=0; a<kmaxAsteroidsNumber; a++) {
            if (mybullets[b].isAlive==YES && myAsteroids[a].isAlive==YES) {
                double distanceSquare=(mybullets[b].position[0]-myAsteroids[a].translation[0]) * (mybullets[b].position[0]-myAsteroids[a].translation[0]) + (mybullets[b].position[1]-myAsteroids[a].translation[1]) * (mybullets[b].position[1]-myAsteroids[a].translation[1]);
                if (distanceSquare<=(myAsteroids[a].radius)*(myAsteroids[a].radius) && myAsteroids[a].radius>=(kInitialAsteroidsRadius/1.4/1.4+0.0001)) {//knoced
                    //and asteriods not smallest
                    if (asteroidsNumber<kmaxAsteroidsNumber) {
                        myAsteroids[asteroidsNumber].isAlive=YES;
                        myAsteroids[asteroidsNumber].radius=myAsteroids[a].radius/1.4;
                        myAsteroids[asteroidsNumber].translation[0]=myAsteroids[a].translation[0];
                        myAsteroids[asteroidsNumber].translation[1]=myAsteroids[a].translation[1];
                        myAsteroids[asteroidsNumber].translation[2]=0.0;
                        myAsteroids[asteroidsNumber].speed=2*myAsteroids[a].speed;
                        myAsteroids[asteroidsNumber].color[0]=myAsteroids[a].color[1];
                        myAsteroids[asteroidsNumber].color[1]=myAsteroids[a].color[2];
                        myAsteroids[asteroidsNumber].color[2]=myAsteroids[a].color[0];
                        asteroidsNumber+=1;
                    }
                    myAsteroids[a].radius/=1.4;
                    myAsteroids[a].speed*=2;
                    playerScore+=20;
                    mybullets[b].isAlive=NO;
                    [popSound play];
                    break;
                }
                else if (distanceSquare<=(myAsteroids[a].radius)*(myAsteroids[a].radius) && myAsteroids[a].radius<=(kInitialAsteroidsRadius/1.4/1.4+0.0001)) {
                    //small enough
                    myAsteroids[a].isAlive=NO;
                    mybullets[b].isAlive=NO;
                    playerScore+=20;
                    [popSound play];
                    break;
                }
            }
        }
    }
}

-(BOOL) checkShipCollision{
    BOOL isKnocked= NO;
    for (int i=0; i<asteroidsNumber; i++) {
        double distanceSquare=(myAsteroids[i].translation[0]-mySpaceShip.translation[0])*(myAsteroids[i].translation[0]-mySpaceShip.translation[0])+ (myAsteroids[i].translation[1]-mySpaceShip.translation[1])*(myAsteroids[i].translation[1]-mySpaceShip.translation[1]);
        if (distanceSquare<(mySpaceShip.halfHeight+myAsteroids[i].radius)*(mySpaceShip.halfHeight+myAsteroids[i].radius) && myAsteroids[i].isAlive) {
            isKnocked=YES;
            break;
        }
    }
    return isKnocked;
}
-(BOOL) checkIfPlayerWin {
    BOOL isWin=NO;
    int numberOfAsteroidsAlive=0;
    for (int i=0; i<asteroidsNumber; i++) {
        if (myAsteroids[i].isAlive) {
            numberOfAsteroidsAlive++;
        }
    }
    if (numberOfAsteroidsAlive==0) {
        isWin=YES;
    }
    return isWin;
}
-(void) restart{
    [self initializeData];
}
-(void) shoot {
    if (bulletNumber<kmaxBulletNumber) {
        bulletNumber+=1;
    }
    else {
        bulletNumber=1;
    }
    mybullets[bulletNumber-1].isAlive=YES;
    mybullets[bulletNumber-1].startPoint[0]=mySpaceShip.translation[0]+cos(mySpaceShip.rotation/180*M_PI)*mySpaceShip.halfWidth;
    mybullets[bulletNumber-1].startPoint[1]=mySpaceShip.translation[1]+sin(mySpaceShip.rotation/180*M_PI)*mySpaceShip.halfWidth;
    mybullets[bulletNumber-1].startPoint[2]=0.0;
    mybullets[bulletNumber-1].position[0]=mybullets[bulletNumber-1].startPoint[0];
    mybullets[bulletNumber-1].position[1]=mybullets[bulletNumber-1].startPoint[1];
    mybullets[bulletNumber-1].position[2]=mybullets[bulletNumber-1].startPoint[2];
    mybullets[bulletNumber-1].endPoint[0]=5 * cos(mySpaceShip.rotation/180*M_PI)+mySpaceShip.translation[0];
    mybullets[bulletNumber-1].endPoint[1]=5 * sin(mySpaceShip.rotation/180*M_PI)+mySpaceShip.translation[1];
    mybullets[bulletNumber-1].endPoint[2]=0.0;
    mySpaceShip.speed[0]-=cos(mySpaceShip.rotation/180*M_PI)*mySpaceShip.shipRecoil;
    mySpaceShip.speed[1]-=sin(mySpaceShip.rotation/180*M_PI)*mySpaceShip.shipRecoil;
    mySpaceShip.speed[2]=0.0;
}
-(void) thrust{
    mySpaceShip.speed[0]+=cos(mySpaceShip.rotation/180*M_PI)*mySpaceShip.shipBoostSpeed;
    mySpaceShip.speed[1]+=sin(mySpaceShip.rotation/180*M_PI)*mySpaceShip.shipBoostSpeed;
    mySpaceShip.isThrusting=YES;
}
-(void) rotateLeft {
    mySpaceShip.rotation+=mySpaceShip.shipRotationSpeed;    
}
-(void) rotateRight {
    mySpaceShip.rotation-=mySpaceShip.shipRotationSpeed;
}
-(void)upgradeSpaceshipColor {
    //update spaceship color
    if (gameLevel>=1 && gameLevel<=5) {
        mySpaceShip.colorA[0]=1.0;
        mySpaceShip.colorA[1]=1.0;
        mySpaceShip.colorA[2]=1.0;
        mySpaceShip.colorB[0]=1.0;
        mySpaceShip.colorB[1]=1.0;
        mySpaceShip.colorB[2]=1.0;
    }
    else if (gameLevel>5 &&gameLevel<=12) {
        mySpaceShip.colorA[0]=0.2;
        mySpaceShip.colorA[1]=1.0;
        mySpaceShip.colorA[2]=0.2;
        mySpaceShip.colorB[0]=0.2;
        mySpaceShip.colorB[1]=1.0;
        mySpaceShip.colorB[2]=0.2;
    }
    else if (gameLevel>12 && gameLevel<=20) {
        mySpaceShip.colorA[0]=0.3;
        mySpaceShip.colorA[1]=0.3;
        mySpaceShip.colorA[2]=1.0;
        mySpaceShip.colorB[0]=0.3;
        mySpaceShip.colorB[1]=0.3;
        mySpaceShip.colorB[2]=1.0;
    }
    else if (gameLevel>20 && gameLevel<=30) {
        mySpaceShip.colorA[0]=0.0;
        mySpaceShip.colorA[1]=0.0;
        mySpaceShip.colorA[2]=1.0;
        mySpaceShip.colorB[0]=1.0;
        mySpaceShip.colorB[1]=1.0;
        mySpaceShip.colorB[2]=1.0;
    }
}
-(void)gamePlayUpdate {
    if (gUpPressed) {
        [self thrust];
    }
    if (gLeftPressed) {
        [self rotateLeft];
    }
    if (gRightPressed) {
        [self rotateRight];
    }
    if (gSpacePressed) {
        updateRateCounterForBullets++;
    }
    else if (!gSpacePressed) {
        updateRateCounterForBullets=mySpaceShip.updateBulletInterval-1;
    }
    if (gSpacePressed && updateRateCounterForBullets%(mySpaceShip.updateBulletInterval)==0) {
        [self shoot];
    }
    if (mySpaceShip.rotation>360) {
        mySpaceShip.rotation-=360;
    }
    if (mySpaceShip.rotation<0) {
        mySpaceShip.rotation+=360;
    }
    //move spaceship 
    mySpaceShip.translation[0]+=mySpaceShip.speed[0];
    mySpaceShip.translation[1]+=mySpaceShip.speed[1];
    mySpaceShip.translation[2]=0.0;
    //check if ship out of bounds
    if (mySpaceShip.translation[0]>=kScreenHalfX || mySpaceShip.translation[0]<=-kScreenHalfX) {
        mySpaceShip.translation[0]=-mySpaceShip.translation[0];
    }
    if (mySpaceShip.translation[1]>=kScreenHalfY || mySpaceShip.translation[1]<=-kScreenHalfY) {
        mySpaceShip.translation[1]=-mySpaceShip.translation[1];
    }
    
    if (asteroidsNumber>kmaxAsteroidsNumber) {
        asteroidsNumber=kmaxAsteroidsNumber;
    }
    
    //update bullets
    for (int i=0; i<kmaxBulletNumber; i++) {
        double totalX=mybullets[i].endPoint[0]-mybullets[i].position[0];
        double totalY=mybullets[i].endPoint[1]-mybullets[i].position[1];
        double totalDistance=sqrt(totalX*totalX+totalY*totalY);
        double XoverXY=totalX/totalDistance;
        double YoverXY=totalY/totalDistance;
        mybullets[i].position[0]+=XoverXY*mySpaceShip.bulletSpeed;
        mybullets[i].position[1]+=YoverXY*mySpaceShip.bulletSpeed;
    }
    //update moons
    for (int i=0; i<kmaxSpaceshipMoonNumber; i++) {
        if (mySpaceMoon[i].isAlive) {
            mySpaceMoon[i].rotation+=mySpaceMoon[i].rotationSign*mySpaceMoon[i].rotationSpeed;
        }
    }
    //update background stars
    for (int i=0; i<kmaxBackgroundStarsNumber; i++) {
        myBackgoundStars[i].translation[0]+=backgroundStarsSpeed*cos(backgroundStarsAngle);
        myBackgoundStars[i].translation[1]+=backgroundStarsSpeed*sin(backgroundStarsAngle);
        myBackgoundStars[i].rotation+=myBackgoundStars[i].rotationSign*0.3;
        //check if background stars out of bounds
        if (myBackgoundStars[i].translation[0]>=kScreenHalfX+kInitialBackgroundStarRadius || myBackgoundStars[i].translation[0]<=-(kScreenHalfX+kInitialBackgroundStarRadius)) {
            myBackgoundStars[i].translation[0]=-myBackgoundStars[i].translation[0];
        }
        if (myBackgoundStars[i].translation[1]>=kScreenHalfY+kInitialBackgroundStarRadius || myBackgoundStars[i].translation[1]<=-(kScreenHalfY+kInitialBackgroundStarRadius)) {
            myBackgoundStars[i].translation[1]=-myBackgoundStars[i].translation[1];
        }
        
    }    
    
    //update asteroids
    for( int i = 0; i < kmaxAsteroidsNumber; i++ ){
        if (myAsteroids[i].isAlive) {
            myAsteroids[i].translation[0]+=myAsteroids[i].speed*cos(myAsteroids[i].angle);
            myAsteroids[i].translation[1]+=myAsteroids[i].speed*sin(myAsteroids[i].angle);
            
            //check if asteroids out of bounds
            if (myAsteroids[i].translation[0]>=kScreenHalfX+kInitialAsteroidsRadius || myAsteroids[i].translation[0]<=-(kScreenHalfX+kInitialAsteroidsRadius)) {
                myAsteroids[i].translation[0]=-myAsteroids[i].translation[0];
            }
            if (myAsteroids[i].translation[1]>=kScreenHalfY+kInitialAsteroidsRadius || myAsteroids[i].translation[1]<=-(kScreenHalfY+kInitialAsteroidsRadius)) {
                myAsteroids[i].translation[1]=-myAsteroids[i].translation[1];
            }
            myAsteroids[i].color[0]+=0.00003;
            myAsteroids[i].color[1]+=0.00003;
            myAsteroids[i].color[2]+=0.00003;
        }   
    }
    [self checkBulletsCollsionWithAsteroids];
    
    if ([self checkShipCollision]) {
        if (mySpaceShip.lives>0) {
            mySpaceShip.lives=mySpaceShip.lives-1;
        }
        else {
            if (gameLevel>1) {
                mySpaceShip.lives=3;
                gameLevel-=1;
                if (playerScore>100*gameLevel) {
                    playerScore-=100*gameLevel;
                }
                else {
                    playerScore=0;
                }
                windowState=GameLoseWindow;
            }
            else {
                mySpaceShip.lives=3;
                playerScore=0;
                gameLevel=1;
                windowState=GameLoseWindow;
            }
        }
        [self saveData];
        [self restart];
    }
    if ([self checkIfPlayerWin]) {
        mySpaceShip.lives=3;
        //see if need to level up
        if (gameLevel<kmaxGameLevel) {
            gameLevel++;
        }
        else {
            gameLevel=kmaxGameLevel;
        }
        //update moon number
        mySpaceShip.moonNumber=(gameLevel- gameLevel%10)/10;
        
        //update bullets random
        if (gameLevel>=30) {
            isBulletsColorRandom=YES;
        }
        else {
            isBulletsColorRandom=NO;
        }
        
        [self upgradeSpaceshipColor];
        
        windowState=GameWinWindow;
        [self saveData];
        [self restart];
    }
}
-(void)gameMenuUpdate {
    ;
}
-(void)gameAboutUpdate {
    ;
}
-(void)objectivesUpdate {
    ;
}
-(void)helpUpdate {
    ;
}
-(void)winUpdate {
    ;
}
-(void)loseUpdate {
    ;
}
//update
-(void)updateView {
    
    switch (windowState) {
        case GameMenuWindow:
            [self gameMenuUpdate];
            break;
        case GamePlayWindow:
            [self gamePlayUpdate];
            break;
        case GameAboutWindow:
            [self gameAboutUpdate];
            break;
        case ObjectivesWindow:
            [self objectivesUpdate];
            break;
        case HelpWindow:
            [self helpUpdate];
            break;
        case GameWinWindow:
            [self winUpdate];
            break;
        case GameLoseWindow:
            [self loseUpdate];
            break;
    }

    [self drawRect:[self bounds]]; 
}

//initGL
-(void)prepareOpenGL {
    [self initializeData];
    glShadeModel(GL_SMOOTH); 
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f); 
    glClearDepth(1.0f); 
    glFrontFace(GL_CCW);// set the front counter clockwise
    glCullFace(GL_BACK);
    glDepthRange(0.0, 1.0);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glEnable(GL_DEPTH_TEST); 
    glDepthFunc(GL_LEQUAL);
    
    glEnable(GL_TEXTURE_2D);
    for( int i = 0; i < numberOfImagesLoaded; i++ ){
        NSString *string=[gImageFileNames objectAtIndex:i];
        imageNames[i]=(char *)[string fileSystemRepresentation];
        loadGLTexture( imageNames[i], (gImages+i), (gTextures+i) );
    }
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-kScreenHalfX, kScreenHalfX, -kScreenHalfY, kScreenHalfY, -1.0, 1.0);//set distance from the origin
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

#pragma mark --NSSound Delegate

-(void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
    if (aBool) {
        [sound play];
    }
}
@end
