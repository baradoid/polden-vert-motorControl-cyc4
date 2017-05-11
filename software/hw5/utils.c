#include <alt_types.h>
#include "altera_avalon_pio_regs.h"
#include "utils.h"
#include "system.h"
#include "stand.h"


alt_u8 RxBuf[RXBUFSIZE];// the receiver buffer.
alt_u32 RxHead = 0; // the circular buffer index
alt_u32 RxTail = 0;

alt_u8 isDataAvailable()
{
	return (RxTail != RxHead);
}

unsigned char _getchar()
{
 alt_u8 temp;
// while (RxTail == RxHead){
//	 nr_delay(1);
// }
 temp = RxBuf[RxTail];
 if (++RxTail > (RXBUFSIZE -1))
 {
	 RxTail = 0;
 }
 return(temp);
}


alt_32 getPos(alt_u8 mNum)
{
	alt_32 pos = 0;
	switch(mNum){
	case 0:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE);
		break;
	case 1:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_1_BASE);
		break;
	case 2:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_2_BASE);
		break;
	case 3:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_3_BASE);
		break;
	case 4:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_4_BASE);
		break;
	case 5:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_5_BASE);
		break;
	case 6:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_6_BASE);
		break;
	case 7:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_7_BASE);
		break;
	case 8:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_8_BASE);
		break;
	case 9:
		pos = IORD_ALTERA_AVALON_PIO_DATA(PIO_9_BASE);
		break;
	}
	return pos;
}

void wr(alt_u8 mNum, alt_u32 d)
{
	switch(mNum){
	case 0:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, d);
		break;
	case 1:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_1_BASE, d);
		break;
	case 2:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_2_BASE, d);
		break;
	case 3:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, d);
		break;
	case 4:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_4_BASE, d);
		break;
	case 5:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_5_BASE, d);
		break;
	case 6:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_6_BASE, d);
		break;
	case 7:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_7_BASE, d);
		break;
	case 8:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_8_BASE, d);
		break;
	case 9:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_9_BASE, d);
		break;
	}
}
void setDiv(alt_u8 mNum, alt_u8 e, alt_u8 dir, alt_u32 div)
{
	alt_u32 d = (MoveDiveInverse<<dirInverseBit)|(e<<21)|(dir<<20)|div;
	wr(mNum, d);

}
void motorSetDir(alt_u8 mNum, alt_u8 dir)
{
	alt_u32 d = (dir<<20);
	switch(mNum){
	case 0:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, d);
		break;
	case 1:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_1_BASE, d);
		break;
	case 2:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_2_BASE, d);
		break;
	case 3:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, d);
		break;
	case 4:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_4_BASE, d);
		break;
	case 5:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_5_BASE, d);
		break;
	case 6:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_6_BASE, d);
		break;
	case 7:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_7_BASE, d);
		break;
	case 8:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_8_BASE, d);
		break;
	case 9:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_9_BASE, d);
		break;
	}
}

void motorPositionReset(alt_u8 mNum)
{
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, 1<<22);
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, 0<<22);
}

void motorDisable(alt_u8 mNum)
{
	alt_u32 d = (MOT_DIS<<21);
	switch(mNum){
	case 0:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, d);
		break;
	case 1:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_1_BASE, d);
		break;
	case 2:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_2_BASE, d);
		break;
	case 3:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, d);
		break;
	case 4:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_4_BASE, d);
		break;
	case 5:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_5_BASE, d);
		break;
	case 6:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_6_BASE, d);
		break;
	case 7:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_7_BASE, d);
		break;
	case 8:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_8_BASE, d);
		break;
	case 9:
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_9_BASE, d);
		break;
	}
}


