/*
 * main.cpp
 *
 *  Created on: Feb 8, 2016
 *      Author: tkappenm
 */
#include "xil_types.h"
#include "xil_cache.h"

#include <stdio.h>

#include "xparameters.h"
#include "PmodOLEDrgb.h"

void DemoInitialize();
void DemoRun();

PmodOLEDrgb oledrgb;

#define totalLEDs 67


char *fs = (char *)0x80000000; /* base address of SRAM */
/* NUMBLOCKS must be the same number that is used in mfsgen when creating the
   MFS image that is pre-loaded into RAM */
/* for big file system */
#define NUMBLOCKS 64
/* for small file system */
/* #define NUMBLOCKS 10 */




int main(void)
{
	Xil_ICacheEnable();
	Xil_DCacheEnable();
	spiInit();
	ledRun();

	  // int numbytes;

	  // numbytes = NUMBLOCKS *sizeof(struct mfs_file_block);

	  // mfs_init_fs(numbytes, fs, MFSINIT_ROM_IMAGE);

	  // mfs_ls_r(-1);
	  // mfs_cat("image.mfs"); /* assuming there is a file called xilmfs.h in the pre-loaded file system */



	return 0;
}

//initialize the SPI device using the demo code
void spiInit()
{
	OLEDrgb_begin(&oledrgb, XPAR_PMODOLEDRGB_0_AXI_LITE_GPIO_BASEADDR, XPAR_PMODOLEDRGB_0_AXI_LITE_SPI_BASEADDR);
}


//write start frame for LED strip with 0s to initialize
void initLedFrame()
{
    OLEDrgb_WriteSPICommand(&oledrgb, 0x00);
    OLEDrgb_WriteSPICommand(&oledrgb, 0x00);
    OLEDrgb_WriteSPICommand(&oledrgb, 0x00);
    OLEDrgb_WriteSPICommand(&oledrgb, 0x00);
}

//write end frame for LED strip with 1s to end frame
void endLedFrame()
{
    OLEDrgb_WriteSPICommand(&oledrgb, 0xff);
    OLEDrgb_WriteSPICommand(&oledrgb, 0xff);
    OLEDrgb_WriteSPICommand(&oledrgb, 0xff);
    OLEDrgb_WriteSPICommand(&oledrgb, 0xff);
}

// numLEDs = number of LEDs to be lit
// r = select red pixel;  ex. 0xff selects red else 0x00 clears red
// g = select green pixel; ex. 0xff selects green else 0x00 clears green
// b = select; ex. 0xff selects blue else 0x00 clears blue
// selPixel = which pixel to select; needs to be less than totalLEDs
// can be a group of pixels or a single pixel
void pixelData (int numLEDs, uint8_t r, uint8_t g, uint8_t b, int selPixel)
{
	int n = totalLEDs  - selPixel+numLEDs;
	int i;
	uint8_t cmds[4];
	uint8_t red;
	uint8_t blue;
	uint8_t green;

	if (r)
		red = 0xff;
	else
		red = 0x00;

	if (g)
		green = 0xff;
	else
		green = 0x00;

	if (b)
		blue = 0xff;
	else
		blue = 0x00;

    for (i = 0; i < 4; i++) OLEDrgb_WriteSPICommand(&oledrgb, 0x00);

	for (i = 0; i < selPixel; i++)  {
		cmds[0] = 0xF1;
		cmds[1] = 0x00;
		cmds[2] = 0x00;
		cmds[3] = 0x00;
		OLEDrgb_WriteSPI(&oledrgb, cmds, 4, NULL, 0);
    }

	for (i = 0; i < numLEDs; i++) {
		cmds[0] = 0xF1;
		cmds[1] = blue;
		cmds[2] = green;
		cmds[3] = red;
		OLEDrgb_WriteSPI(&oledrgb, cmds, 4, NULL, 0);
	}

	for (i = 0; i < n; i++) {
		cmds[0] = 0xF1;
		cmds[1] = 0x00;
		cmds[2] = 0x00;
		cmds[3] = 0x00;
		OLEDrgb_WriteSPI(&oledrgb, cmds, 4, NULL, 0);
	}

	for (i = 0; i < 4; i++)	OLEDrgb_WriteSPICommand(&oledrgb, 0xff);

}


void ledRun()
{
    // uint8_t cmds[4];
    int i;
while(1){

	//for (i = 0; i < 10; i++) {

		//pixelData(30, 1, 1, 0, 15+i);
		//usleep(1000);

	//}
	//rising edge
	pixelData(30, 1, 1, 0, 15);
	usleep(10);
	//high level
	pixelData(10, 1, 1, 0, 15);
	usleep(50);

	pixelData(30, 1, 1, 0, 15);
	usleep(10);

	//low level
	pixelData(10, 1, 1, 0, 35);

	usleep(50);
    // initLedFrame();

    // for (i=0;i<55;i++) {
		// cmds[0] = 0xF1;
		// cmds[1] = 0x00;
		// cmds[2] = 0x00;
		// cmds[3] = 0x00;
		// OLEDrgb_WriteSPI(&oledrgb, cmds, 4, NULL, 0);
    // }

	// for (i=0;i<10;i++) {
		// cmds[0] = 0xF1;
		// cmds[1] = 0x00;
		// cmds[2] = 0x00;
		// cmds[3] = 0xff;
		// OLEDrgb_WriteSPI(&oledrgb, cmds, 4, NULL, 0);
    // }

	// for (i=0;i<7;i++) {
		// cmds[0] = 0xF1;
		// cmds[1] = 0xff;
		// cmds[2] = 0x00;
		// cmds[3] = 0x00;
		// OLEDrgb_WriteSPI(&oledrgb, cmds, 4, NULL, 0);
    // }

    // endLedFrame();
    
    // usleep(1000);//Wait 1 seconds
    
    // initLedFrame();

    // for (i=0;i<72;i++) {
		// cmds[0] = 0xF1;
		// cmds[1] = 0x00;
		// cmds[2] = 0x00;
		// cmds[3] = 0xFF;
		// OLEDrgb_WriteSPI(&oledrgb, cmds, 4, NULL, 0);
    // }

    // endLedFrame();
    
    // usleep(1000);//Wait 1 seconds
    }
}
