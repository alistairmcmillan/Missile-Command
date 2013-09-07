#import <Cocoa/Cocoa.h>

// The various game states
enum {
	kSplashScreen = 1,
	kGamePlay = 2,
	kGamePaused = 3,
	kGameLevelDisplay = 4
};

// The bomb structure
typedef struct {
	int x;
	int y;
	int radius;
	int targetCity;
	BOOL active;
	BOOL peaked;
} BombStruct;

// The missile structure
typedef struct {
	int length;
	NSPoint origin;
	NSPoint target;
	NSPoint currently;
	int targetCity;
	BOOL active;
} MissileStruct;

// The number of missiles a computer will shoot during this level
#define levelMissiles 5 + level

// The maximum number of bombs and missiles
#define maxBombs 36

// The line after which the player can't launch bombs
#define playerLine 80

// The line at which missiles detonate
#define missileLine cityRect[0].origin.y + 22

// The fractions into which the missile path is divided
#define missileFracs 200 - (level / 3) * 20

// The minimum number of fractions into which the missile path is divided
#define minMissileFracs 80

// The frame period - the inverse of the frame frequency (25 fps)
#define framePeriod 0.04

// A frequency function which tells the computer how often to shoot missiles
// Alpha missile frequency is used for the first 2 seconds, beta for the next 2, gamma for the next 2 and a missile is shot regardless afterwards
#define alphaMissileFrequency 150 - level * 8
#define betaMissileFrequency 75 - (level / 2) * 8
#define gammaMissileFrequency 35 - (level / 4) * 8

// The minimum acceptable frequency (below this the frequency functions are ignored)
#define minFrequency 10

@interface MissileView : NSView
{
	
	// The game state
	int gameState;
	
	// The level box
	IBOutlet id levelBox;
	
	// The score box
	IBOutlet id scoreBox;

	// The "Yours left" box
	IBOutlet id yourBox;
	
	// The "His Left" box
	IBOutlet id hisBox;
	
	// The "High Scores" box
	IBOutlet id highBox;
	
	// The menu item that starts a new game
	IBOutlet id newGameItem;
	
	// The timer that updates the game regularly
	id missileTimer;
	
	// The number of cities the player has (not all cities may be active)
	int cities;
	
	// The current level
	int level;
	
	// The number of missiles you as a player have left
	int playerMissiles;
	
	// The number of missiles the computer has left to shoot
	int computerMissiles;
	
	// Whether the player has a city in the given slot
	BOOL hasCity[6];
	
	// Where each city is located
	NSRect cityRect[6];
	
	// All the active bombs
	BombStruct bomb[maxBombs];
	
	// All the active missiles
	MissileStruct missile[maxBombs];
	
	// Current player's score
	int score;
	
	// Current high score
	int highScore;
	
	// How many loops have passed without a launch
	int loopsWithoutLaunch;
	
	// The state of the game before pausing
	int resumeGameState;
	
	// This display count can be set to 0 whenever and will increment with each run of the periodicUpdate method.
	// It is largely used to kill the level display when the count reaches 50 (2 seconds) and should be set to
	// -1 when inactive.
	int displayCount;
	
}

// Initializes the instance variables of this class
- (id)initWithFrame:(NSRect)frame;

// Centres the game window and retrieves the high score
- (void)awakeFromNib;

// Saves the high score upon exit
- (void)applicationWillTerminate:(NSNotification *)notification;

// Returns YES for optimizing purposes
- (BOOL)isOpaque;

// Draws the game view
- (void)drawRect:(NSRect)rect;

// Starts a new game
- (IBAction)newGame:(id)sender;

// Pauses/unpauses the game
- (IBAction)toggleGamePause:(id)sender;

// Resets the high score
- (IBAction)resetHighScore:(id)sender;

// Detonates a bomb
- (void)detonateBomb:(NSPoint)where isPlayer:(BOOL)isPlayer destroyCity:(int)whichCity;

// Launches a missile
- (void)launchMissile;

// Called periodically to determine whether or not to launch a missile and then advance all active missiles
- (void)updateMissiles;

// Called periodically to handle the growth, decay and destruction of detonated bombs
- (void)updateBombs;

// Called periodically to handle any collisions that might have occurred between a bomb and a missile
- (void)updateCollisions;

// Handle a mouse down event detonating a bomb when necessary
- (void)mouseDown:(NSEvent *)event;

// Called periodically to update the game (calls updateMissiles, updateBombs and updateCollisions)
- (void)periodicUpdate:(id)timer;

// Called to update the high score if the current score exceeds it
- (void)updateHighScore;

// Called to check whether a menu item should be enabled (disables the "Reset High Score" menu item during game play)
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

@end
