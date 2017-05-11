#pragma once
#include <alt_types.h>

#define RXBUFSIZE 128

extern alt_u8 RxBuf[RXBUFSIZE];// the receiver buffer.
alt_u8 _getchar();
extern alt_u32 RxHead; // the circular buffer index
extern alt_u32 RxTail;
alt_u8 isDataAvailable();

void setDiv(alt_u8 mNum, alt_u8 e, alt_u8 dir, alt_u32 div);
alt_32 getPos(alt_u8 mNum);

void motorDisable(alt_u8 mNum);
void motorPositionReset(alt_u8 mNum);
