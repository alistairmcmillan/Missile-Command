/*
	Missile Command 0.2
	Developed by Mark Pazolli
	
	This code is in the public domain, which means its use is unrestricted. You
	may redistribute it in modified or original form as you see fit. It would be
	appreciated if you provided me with credit where appropriate. You can
	contact me via e-mailing me at:
	
	quirinus@bigpond.com
*/

#import "MissileView.h"

@implementation MissileView

/*
	This is NSView's designated initializer. It is overidden so we can
	initialize our instance variables after we have called the super's
	initializer.
*/
- (id)initWithFrame:(NSRect)frame
{
	int cityOffX, cityOffY;
	int i;
	
	// Call the super's initializer
	self = [super initWithFrame:frame];
	
	// Randomize the random number generator
	srandom((uint)time(nil));

	// Set game state to display the splash screen
	gameState = kSplashScreen;
	
	// Specify ourselves as the NSApp delegate - which means our applicationWillTerminate: method will be called before exiting
	[NSApp setDelegate:self];
	
	// Determine the image rectangles of the cities
	for (i = 0; i < 6; i++) {
		cityOffX = ([self bounds].size.width / 2) - 32 + (i - 2.5) * 96;
		cityOffY = 12;
		cityRect[i] = NSMakeRect(cityOffX, cityOffY, 64, 64);
	}
	
	return self;
}

/*
	This method is called for all instances of a class that originate from a NIB
	file when the NIB file is fully loaded. This is important because a number
	IBOutlets which cannot be manipulated at initialization can when this method
	is called.
*/
- (void)awakeFromNib
{
	NSPoint windowPos;
	
	// Centre the window
	windowPos.x = [[[self window] screen] frame].size.width / 2 - [[self window] frame].size.width / 2;
	windowPos.y = [[[self window] screen] frame].size.height / 2 - [[self window] frame].size.height / 2;
	[[self window] setFrameOrigin:windowPos];	
	
	// Load the high score from the preferences file (conveniently the number returned if there is no preferences file is zero)
	highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"];
	
	// Display the high score in its text box
	[highBox setStringValue:[NSString stringWithFormat:@"High Score: %ld", highScore]];
}

/*
	This method is called directly by the Cocoa framework upon exiting if the
	object is set as the NSApp delegate. The method is used to save the 
	player's high score.
*/
- (void)applicationWillTerminate:(NSNotification *)notification
{
	// Save the high score to preferences
	[[NSUserDefaults standardUserDefaults] setInteger:highScore forKey:@"highScore"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

/*
	Views such as ours which are entirely opaque should override isOpaque and
	set it to YES for optimization purposes.
*/
- (BOOL)isOpaque 
{
    return YES;
}

/*
	This is where we specify what should be drawn in the view, it is called by
	mechanisms external to this class. You can force the view to be redrawn
	during the next available period by calling "[self setNeedsDisplay:YES]".
	In most games you would only redraw the parts of the screen that need
	updating. However since the graphics in Missile Commmand are so lightweight
	we can afford to redraw the whole game screen for each frame of the game.
	Apple's SillyBalls or the Inkubator's Hooptie offer examples of partial
	updating.
*/
- (void)drawRect:(NSRect)rect
{
	NSImage *turtle;
	NSPoint turtlePoint;
	NSSize turtleSize;
	NSRect bombRect;
	NSBezierPath *missilePath;
	NSString *displayString;
	NSFont *displayFont;
	NSDictionary *displayAttributes;
	int i;
	
	// Draw the Missile Command border
    [[NSColor whiteColor] set];
    [[NSBezierPath bezierPathWithRect:[self bounds]] fill];
	[[NSColor blackColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] stroke];
	
	switch (gameState) {
		case kSplashScreen:
		
			// Draw the splash screen - a single centred image
			turtle = [NSImage imageNamed:@"title.tiff"];
			turtlePoint.x = ([self bounds].origin.x + ([self bounds].size.width / 2)) - ([turtle size].width / 2);
			turtlePoint.y = ([self bounds].origin.y + ([self bounds].size.height / 2)) - ([turtle size].height / 2);
			[turtle drawAtPoint:turtlePoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

		break;
		case kGamePlay:
			
			// Draw the cities
			for (i = 0; i < 6; i++) {
				if (hasCity[i] == YES) {
					turtle = [NSImage imageNamed:@"city.tiff"];
					[turtle drawAtPoint:cityRect[i].origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
				}
			}
			
			// Draw the missiles - essentially lines
			for (i = 0; i < maxBombs; i++) {
				if (missile[i].active == YES) {
					missilePath = [NSBezierPath bezierPath];
					[missilePath setLineWidth:2];
					[missilePath moveToPoint:missile[i].origin];
					[missilePath lineToPoint:missile[i].currently];
					[missilePath closePath];
					[missilePath stroke];
				}
			}
			
			// Draw the bombs - essentially circles
			[[NSColor blackColor] set];
			for (i = 0; i < maxBombs; i++) {
				if (bomb[i].active == YES) {
					bombRect = NSMakeRect(bomb[i].x - bomb[i].radius, bomb[i].y - bomb[i].radius, bomb[i].radius * 2, bomb[i].radius * 2);
					[[NSBezierPath bezierPathWithOvalInRect:bombRect] fill];
				}
			}

		break;
		case kGameLevelDisplay:
			
			// Draw the "Level XX" string - centered
			displayString = [NSString stringWithFormat:@"Level %d",level];
			displayFont = [NSFont fontWithName:@"Chicago" size:24];
            if(displayFont == nil) {
                displayFont = [NSFont systemFontOfSize:24];
            }
            displayAttributes = [NSDictionary dictionaryWithObject:displayFont forKey:NSFontAttributeName];
			turtleSize = [displayString sizeWithAttributes:displayAttributes];
			turtlePoint.x = ([self bounds].size.width / 2) - (turtleSize.width / 2);
			turtlePoint.y = ([self bounds].size.height / 2) - (turtleSize.height / 2) + 12;
			[displayString drawAtPoint:turtlePoint withAttributes:displayAttributes];
			
			// Draw the cities
			for (i = 0; i < 6; i++) {
				if (hasCity[i] == YES) {
					turtle = [NSImage imageNamed:@"city.tiff"];
					[turtle drawAtPoint:cityRect[i].origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
				}
			}
			
		break;
		case kGamePaused:
		
			// Draw the "Paused" string centred
			displayString = @"Paused";
			displayFont = [NSFont fontWithName:@"Chicago" size:24];
            if(displayFont == nil) {
                displayFont = [NSFont systemFontOfSize:24];
            }
            displayAttributes = [NSDictionary dictionaryWithObject:displayFont forKey:NSFontAttributeName];
			turtleSize = [displayString sizeWithAttributes:displayAttributes];
			turtlePoint.x = ([self bounds].size.width / 2) - (turtleSize.width / 2);
			turtlePoint.y = ([self bounds].size.height / 2) - (turtleSize.height / 2);
			[displayString drawAtPoint:turtlePoint withAttributes:displayAttributes];
		
		break;
	}
}

/*
	This method is called directly by the Cocoa framework when the user selects 
	the "New Game" or "End Game" menu item.  It adjusts the game state and other 
	instance variables in preparation to end a game or start a new one. It also 
	kills or creates the periodic timer around which the game revolves.
*/
- (IBAction)newGame:(id)sender
{
	int i;
	
	// Start a game or end a game depending on the game state
	switch (gameState) {
		case kSplashScreen:
		
			// Set the "New Game" menu item to "End Game"
			[sender setTitle:@"End Game"];
			
			// Reset the loopsWithoutLaunch
			loopsWithoutLaunch = 0;
			
			// Change to the game playing state
			gameState = kGamePlay;
			
			// Give the player 6 cities to begin with
			cities = 6;
			for (i = 0; i< 6; i++)
				hasCity[i] = YES;
				
			// Start from level 1 with a score of 0
			level = 1;
			score = 0;
			
			// Distribute missiles
			playerMissiles = levelMissiles + 4;
			computerMissiles = levelMissiles;
			
			// Deactivate all missiles and bombs
			for (i = 0; i < maxBombs; i++) {
				bomb[i].active = NO;
				missile[i].active = NO;
			}
			
			// Reflect the current settings in the game window
			[levelBox setStringValue:[NSString stringWithFormat:@"Level: %d", level]];
			[scoreBox setStringValue:[NSString stringWithFormat:@"Score: %ld", (long)score]];
			[yourBox setStringValue:[NSString stringWithFormat:@"Yours Left: %d", playerMissiles]];
			[hisBox setStringValue:[NSString stringWithFormat:@"His Left: %d", computerMissiles]];
			
			// Set the displayCount to -1 to signify that it is inactive
			displayCount = -1;
			
			// Initiate the periodic timer for game play
			missileTimer =  [NSTimer scheduledTimerWithTimeInterval:framePeriod target:self selector:@selector(periodicUpdate:) userInfo:nil repeats:YES];
				
		break;
		case kGamePaused:
		case kGameLevelDisplay:
		case kGamePlay:
		
			// Set the "End Game" menu item to "New Game"
			[sender setTitle:@"New Game"];
			
			// Free our periodic timer
			[missileTimer invalidate];
			missileTimer = nil;
			
			// Return to the splash screen state
			gameState = kSplashScreen;
		
		break;
	}
	
	// Demand an update of the game screen
    [self setNeedsDisplay:YES];
}

/*
	This method is called directly by the Cocoa framework when the user selects 
	the "Pause Game" or "Resume Game" menu item.  It adjusts the game state and 
	kills or reinstates the periodic timer to pause or resume game play.
*/
- (IBAction)toggleGamePause:(id)sender
{
	// Pause the game or resume the game depending on the game state
	switch (gameState) {
		case kGamePlay:
		case kGameLevelDisplay:
		
			// Set the "Pause Game" menu item to display "Resume Game"
			[sender setTitle:@"Resume Game"];
			
			// Free our periodic timer
			[missileTimer invalidate];
			missileTimer = nil;
			
			// Get the game state to resume to and then switch to the paused state
			resumeGameState = gameState;
			gameState = kGamePaused;
		
		break;
		case kGamePaused:
		
			// Set the "Resume Game" menu item to display "Pause Game"
			[sender setTitle:@"Pause Game"];
			
			// Restore to appropriate state
			gameState = resumeGameState;
			
			// Reinstate our periodic timer
			missileTimer =  [NSTimer scheduledTimerWithTimeInterval:framePeriod target:self selector:@selector(periodicUpdate:) userInfo:nil repeats:YES];
		
		break;
	}
	
	// Demand an update of the game screen
	[self setNeedsDisplay:YES];
}

/*
	This method is called directly by the Cocoa framework when the user selects 
	the "Reset High Score" menu item. It sets both the high score and score back 
	to zero. It will only be called during the kSplashScreen state (see 
	validateMenuItem: for why).
*/
- (IBAction)resetHighScore:(id)sender
{
	// Set the high score and score to zero
	highScore = 0;
	score = 0;
	
	// Reflect these changes in the appropriate text boxes
	[highBox setStringValue:[NSString stringWithFormat:@"High Score: %ld", highScore]];
	[scoreBox setStringValue:[NSString stringWithFormat:@"Score: %ld", (long)score]];
}

/*
	This method launches a missile for the computer by simply configuring the 
	concerned instance variables correctly.
*/
- (void)launchMissile
{
	int i;
	
	// Since a missile has been launched reset the loopsWithoutLaunch variable
	loopsWithoutLaunch = 0;
	
	// If the computer has no missiles left don't commence a launch
	if (computerMissiles <= 0) 
		return;
	
	// Find an inactive missile
	for (i = 0; i < maxBombs; i++) {
		if (missile[i].active == NO) {
			
			// Take away one from the computer's arsenal and reflect this in the text box
			computerMissiles--;
			[hisBox setStringValue:[NSString stringWithFormat:@"His Left: %d", computerMissiles]];
			
			// Configure the missile for launch
			missile[i].active = YES;
			missile[i].length = 0;
			missile[i].origin.y = [self frame].size.height;
			missile[i].origin.x = random() % (int)[self frame].size.width;
			missile[i].currently = missile[0].origin;
			missile[i].target.y = missileLine;
			missile[i].targetCity = random() % 6;			
			missile[i].target.x = cityRect[missile[i].targetCity].origin.x + 32;
				
			// We're all done
			return;
		
		}
	}
}

/*
	This method detonates a bomb by simply configuring the concerned instance 
	variables correctly. Bombs may detonated on behalf of either the player or
	computer. Computer bombs are due to missiles hitting the ground or a city.
*/
- (void)detonateBomb:(NSPoint)where isPlayer:(BOOL)isPlayer destroyCity:(int)whichCity
{
	int i;
	
	// If the bomb is that of the player, don't continue if the player has an insufficient arsenal
	if (isPlayer && playerMissiles <= 0)
		return;
		
	// Only continue if the bomb is above the minumum line or is a computer bomb
	if (where.y > playerLine || !isPlayer) {
			
		// Find an inactive bomb
		for (i = 0; i < maxBombs; i++) {
			if (bomb[i].active == NO) {
			
					// If the bomb is that of a player deplete his arsenal and update the associated text
					if (isPlayer) {
						playerMissiles--;
						[yourBox setStringValue:[NSString stringWithFormat:@"Yours Left: %d", playerMissiles]];
					}
					
					// Configure the bomb for detonation
					bomb[i].active = YES;
					bomb[i].radius = 0;
					bomb[i].x = where.x;
					bomb[i].y = where.y;
					bomb[i].peaked = NO;
					bomb[i].targetCity = whichCity;
					
					// We're all done
					return;
				
			}
		}
	
	}
	
}

/*
	This method is called directly by the Cocoa Framework when the user clicks 
	on the view, it simply detonates a bomb for the player.
*/
- (void)mouseDown:(NSEvent *)event {
    NSPoint eventLocation = [event locationInWindow];
	
	// Convert to a valid view co-ordinate
	eventLocation.x -= [self frame].origin.x;
	eventLocation.y -= [self frame].origin.y;
	
	// Detonate a player's bomb at that location
    [self detonateBomb:eventLocation isPlayer:YES destroyCity:-1];
}

/*
	This method consists of two parts. The first part occasionally launches a 
	new missile based on a number of variables. The second part advances all 
	active missiles. The method is called for each frame of the game.
*/
- (void)updateMissiles
{
	int frequencyToUse, actMissileFracs, i;
	
	// Part 1: Launch a new missile if appropriate
	
	// Increment how many loops have passed since the last missile launch
	loopsWithoutLaunch++;
	
	// Determine the probability of a launch using various definitions from the header (notice how the probability increases if there has been no launch for a while)
	frequencyToUse = alphaMissileFrequency;
	if (loopsWithoutLaunch > (2 / framePeriod)) {
		frequencyToUse = betaMissileFrequency;
	}
	if (loopsWithoutLaunch > (4 / framePeriod)) {
		frequencyToUse = gammaMissileFrequency;
	}
	if (loopsWithoutLaunch > (6 / framePeriod)) {
		[self launchMissile];
		return;
	}

	// Then use the frequency to determine whether to launch
	if (frequencyToUse > minFrequency) {
		if (random() % frequencyToUse == 1)
			[self launchMissile];
	}
	else {
		if (random() % minFrequency == 1)
			[self launchMissile];
	}
	
	// Part 2: Advance all active missiles

	// Go through all active missiles
	for (i = 0; i < maxBombs; i++) {
		if (missile[i].active == YES) {
		
			// Determine the fractions into which the missile path should be divided
			actMissileFracs = missileFracs;
			if (actMissileFracs < minMissileFracs)
				actMissileFracs = minMissileFracs;
				
			// Depending on whether the missile's length exceeds the number of fractions either destroy the target city
			// or simply advance the missile's length. Note: Length is only used here (where it determines whether to
			// detonate the missile)
			if (missile[i].length < actMissileFracs)
				missile[i].length += 1;
			else {
				missile[i].active = NO;
				[self detonateBomb:missile[i].target isPlayer:NO destroyCity:missile[i].targetCity];
			}
			
			// And then for our drawing procedure determine where the missile should end on screen
			missile[i].currently.x = missile[i].origin.x + ((missile[i].target.x - missile[i].origin.x) * missile[i].length) / actMissileFracs;
			missile[i].currently.y = missile[i].origin.y + ((missile[i].target.y - missile[i].origin.y) * missile[i].length) / actMissileFracs;
		
		}
	}
}

/*
	This method causes the game to progress to the next level, it is called 
	after the final bomb finishes its detonation by the "updateBombs" method.
*/
- (void)progressLevel
{
	int i, currentCities;
	
	// Start the display count
	displayCount = 0;
	
	// Switch to the level display state
	gameState = kGameLevelDisplay;
	
	// Increment the level and update the text box to reflect this
	level++;
	[levelBox setStringValue:[NSString stringWithFormat:@"Level: %d", level]];
	
	// Every four levels award an extra city (city overloading is implemented)
	if (level % 4 == 0) 
		cities++;
		
	// Restore the computer's arsenal and increase the player's as well and reflect that in the text boxes
	computerMissiles = levelMissiles;
	playerMissiles += levelMissiles + 1;
	[hisBox setStringValue:[NSString stringWithFormat:@"His Left: %d", computerMissiles]];
	[yourBox setStringValue:[NSString stringWithFormat:@"Yours Left: %d", playerMissiles]];
	
	// Count the current cities
	currentCities = 0;
	for (i = 0; i < 6; i++) {
		if (hasCity[i] == YES)
			currentCities++;
	}
	
	// Apply city bonus and reflect this in the associated text box (then call for the high scores to be kept in sync)
	score += currentCities * 50;
	[scoreBox setStringValue:[NSString stringWithFormat:@"Score: %ld", (long)score]];
	[self updateHighScore];
	
	// Restore cities if necessary
	for (i = 0; i < 6; i++) {
		if (currentCities < cities && hasCity[i] == NO) {
			hasCity[i] = YES;
			currentCities++;
		}
	}
	
	// Make sure all bombs are inactive
	for (i = 0; i < maxBombs; i++)
		bomb[i].active = NO;
}

/*
	This method handles the growth and decay of detonated bombs as well as their
	destruction of cities. It is called for each frame of the game and is
	responsible for ending the game and progressing it to the next level.
*/
- (void)updateBombs
{
	BOOL lifeFound;
	int i, i2, i3;
	
	// Go through all active bombs
	for (i = 0; i < maxBombs; i++) {
		if (bomb[i].active == YES) {
		
			// If the bomb has peaked...
			if (bomb[i].peaked) {
			
				// Reduce its radius
				bomb[i].radius--;
				
				// If its radius is below zero...
				if (bomb[i].radius <= 0) { 
				
					// Deactivate the bomb
					bomb[i].active = NO;
					
					// If the bomb was one which might have blown up a city...
					if (bomb[i].targetCity > -1) {
					
						// Go through and try and find a city which is still present
						lifeFound = NO;
						for (i2 = 0; (i2 < 6) && (lifeFound == NO); i2++) 
							lifeFound = hasCity[i2];
						
						// If one can't be found...
						if (lifeFound == NO) {
						
							// End the game (calling newGame may seem a strange way to do it but it works see the method's code for why)
							[self newGame:newGameItem];

						}

					}
					
					// If the computer has more missiles to spend...
					if (computerMissiles > 0) {
					
						// Forget about progressing to the next level
						return;
					
					}
					
					// Do a check for any remaining missiles or bombs
					for (i3 = 0; i3 < maxBombs; i3++) {
					
						// If an active missile is found...
						if (missile[i3].active == YES) {
							
							// Forget about progressing to the next level
							return;
						
						}
						
						// If an active bomb is found...
						if (bomb[i3].active == YES) {
							
							// Forget about progressing to the next level
							return;
						
						}
						
					}
					
					// Otherwise progress to the next level
					[self progressLevel];

					return;

					
				}
				
			}
			else {
				
				// In cases where the bomb hasn't peaked increase the radius
				bomb[i].radius++;
				
				// If the bomb has reached a radius of greater than 30...
				if (bomb[i].radius > 30) {
				
					// Set it to have peaked
					bomb[i].peaked = YES;
					
					// Check the bomb's target city and if it exists...
					if (bomb[i].targetCity > -1) {
						if (hasCity[bomb[i].targetCity] == YES) {
						
							// Set the city to have been destroyed
							hasCity[bomb[i].targetCity] = NO;
							
							// Take one off the city count
							cities--;
						
						}
					}
					
				}
				
			}
		
		}
	}
	
}

/*
	This method handles the collision of a bomb with a missile. It is called for 
	each frame of the game.
*/
- (void)updateCollisions
{
	int lengthToMissile;
	int i, i2;
	
	// Go through all bombs (i) and all missiles (i2)
	for (i = 0; i < maxBombs; i++) {
		for (i2 = 0; i2 < maxBombs; i2++) {
		
			// If we have an active missile/bomb combination...
			if (missile[i2].active == YES && bomb[i].active == YES) {
			
				// Use Pythagoras' Rule to determine a length to the missile's front from bomb's detonation point
				lengthToMissile = (int)(abs(sqrt(pow(missile[i2].currently.x - bomb[i].x, 2) + pow(missile[i2].currently.y - bomb[i].y, 2))));
				
				// See if this distance is less than the bomb's radius
				if (lengthToMissile <= bomb[i].radius) {
					
					// If so, disable the missile
					missile[i2].active = NO;
					
					// And if bomb is not blowing up a city...
					if (bomb[i].targetCity == -1) {
						
						// Increment the score by twenty and reflect changes in associated text boxes
						score += 20;
						[scoreBox setStringValue:[NSString stringWithFormat:@"Score: %ld", (long)score]];
						[self updateHighScore];
						
						// Cause the missile to spawn another detonation
						[self detonateBomb:missile[i2].currently isPlayer:NO destroyCity:-1];
						
					}
					
				}
	
			}
		}
	}
}

/*
	This method is called periodically by the game's timer which is created when 
	the player elects to start a new game. It updates all the game objects and then
	specifies the game screen as needing to be refreshed.
*/
- (void)periodicUpdate:(id)timer
{	
	// Increment the displayCount if it's above -1 
	if (displayCount > -1) 
		displayCount++;
	
	// Switch back from level display state if the displayCount is above fifty
	if (gameState == kGameLevelDisplay) {
		if (displayCount >= 50) {
			displayCount = -1;
			gameState = kGamePlay;
		}
		else
			return;
	}
	
	// Handle all the missiles
	[self updateMissiles];
	
	// Handle all collisions
	[self updateCollisions];
	
	// Handle all the bombs
	[self updateBombs];
	
	// Demand an update of the game screen
	[self setNeedsDisplay:YES];
}

/*
	This method is called after most changes to the score variable to see 
	whether such a change affects the high score.
*/
- (void)updateHighScore
{
	// If the current score exceeds the high score...
	if (score > highScore) {
	
		// Set the high score to the current score
		highScore = score;
		
		// Update the high score text box
		[highBox setStringValue:[NSString stringWithFormat:@"High Score: %ld", highScore]];
	
	}
}

/*
	This method is called by the Cocoa framework every time the user selects 
	something in the application's menu bar. It returns YES or NO based on 
	whether the given item should appear enabled or disabled. An instance is 
	only asked to validate menu items for which it is the target for. To make 
	use of this easy assign each menu item a unique "tag" in the Interface
	Builder.
*/
- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	long itemTag = [anItem tag];
	
	// If the mode is not the splash screen and the menu item is the "Reset High Score" one return NO
	if (gameState != kSplashScreen && itemTag == 3)
		return NO;
		
	// Otherwise return YES
	return YES;
}

@end
