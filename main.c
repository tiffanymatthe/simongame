/*
 * Author: Tiffany Matthe           
 * Course: APSC 160, at UBC
 * Lab Section: L1N      
 * Date: 11/23/2019 6:31:28 PM
 *           
 * Purpose: Implements Simon's game. Displays a pattern of LEDS and checks if user pushes the right switches to copy pattern.
 *			Flashes red 3x if wrong, green 3x if round of 5 has been successfully accomplished.
 *
 * Note: Uses a DAQ simulator given by APSC 160.
 */
#define _CRT_SECURE_NO_WARNINGS
#include <DAQlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <Windows.h>

#define MAX_SEQUENCE 5
#define SWITCH0 0
#define SWITCH1 1
#define SWITCH2 2
#define SWITCH3 3
#define LED0 0
#define LED1 1
#define LED2 2
#define LED3 3
#define ON 1
#define OFF 0
#define TRUE 1
#define FALSE 0
#define SECOND 1000
#define LOWER 0
#define UPPER 3
#define NUMSWITCHES 4

/*function prototypes*/
void runSimon(void);
int randInt(int lower, int upper);
void generateSequence(int length, int sequence[]);
void flashLED(int LEDNumber);
void flashLEDS(int LEDNumber, int repeat);
int sequenceCheck(int length, int sequence[]);

int main(void)
{
	/*DAQ setup*/
	int setupNum;

	printf("Please enter a setup number; 6 for DAQ simulator. ");
	scanf("%d", &setupNum);

	if (setupDAQ(setupNum) == TRUE) {
		srand((unsigned)time(NULL));
		runSimon();
	}
	else
		printf("ERROR: Unsuccessful initialization.\n");

	system("PAUSE");
	return 0;
}

/*Runs Simon's game*/
void runSimon(void) {
	int numberOfLEDS = 1;
	int LEDNumber;
	int sequence[MAX_SEQUENCE];

	generateSequence(MAX_SEQUENCE, sequence);

	while (continueSuperLoop()) {
		if (numberOfLEDS <= MAX_SEQUENCE) {
			/*Flash LEDS*/
			for (LEDNumber = 0; LEDNumber < numberOfLEDS; LEDNumber++) {
				flashLED(sequence[LEDNumber]);
				Sleep(0.5 * SECOND);
			}
			/*Check if user pushes correct buttons and increment if yes*/
			if (sequenceCheck(numberOfLEDS, sequence) == 1) {
				numberOfLEDS++;
				Sleep(SECOND);
			}
			/*Else no increment*/
			else {
				numberOfLEDS = 1;
				flashLEDS(LED1, 3);
				generateSequence(MAX_SEQUENCE, sequence);
				Sleep(SECOND);
			}

			if (numberOfLEDS > MAX_SEQUENCE) {
				numberOfLEDS = 1;
				flashLEDS(LED0, 3);
				generateSequence(MAX_SEQUENCE, sequence);
				Sleep (SECOND);
			}

		}
		
	}

}

/*Generates a random number*/
int randInt(int lower, int upper) {
	int random;

	random = rand() % (upper + 1) + lower;

	return random;
}

/*Generates a sequence of random numbers in an array*/
void generateSequence(int length, int sequence[]) {
	int count;

	for (count = 0; count < length; count++) {
		sequence[count] = randInt(LOWER, UPPER);
	}
}

/*Turns on a specific LED*/
void flashLED(int LEDNumber) {
	digitalWrite(LED0, 0);
	digitalWrite(LED1, 0);
	digitalWrite(LED2, 0);
	digitalWrite(LED3, 0);
	
	digitalWrite(LEDNumber, 1);
	Sleep(0.5 * SECOND);
	digitalWrite(LEDNumber, 0);
}

/*Turns on and off a specific LED a number of times*/
void flashLEDS(int LEDNumber, int repeat) {
	int count;

	for (count = 0; count < repeat; count++) {
		flashLED(LEDNumber);
		Sleep(0.2 * SECOND);
	}
}

int sequenceCheck(int length, int sequence[]) {
	//int pushed = -1;
	int count = 0;
	int state[NUMSWITCHES] = { 0 };
	int stateCount;
	//*int check= 0;

	while (count < length) {
		for (stateCount = 0; stateCount < NUMSWITCHES; stateCount++) {
			state[stateCount] = digitalRead(stateCount);

			if (state[stateCount] == 1) {
				if (sequence[count] == stateCount) {
					count++;
					//pushed = stateCount;
				}
				else
					return 0;

				while (digitalRead(stateCount) == 1) {
					Sleep(0.001 * SECOND);
				}
			}
		}

		//check++;
		//printf("Checked %d times. Pushed LED = %d\n", check, pushed);
		//pushed = -1;
	}

	return 1;
}
