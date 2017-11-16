;clk timer default 9.8 MHz
;GPIO defines

.org 0x0000
begin:
	rjmp main
	reti
	reti
	rjmp TIM0_OVF
	reti
	rjmp ANA_COMP
	reti
	reti
	reti
	reti
	reti

main:
#define PortB 0x18
#define DDRB  0x17
#define PinB  0x16
                   ;Analog comparator defines****
#define ACSR 0x08  ;Analog comparator control and status register
#define ACIS0 0x00 
#define ACIS1 0x01 ; 00 int. on output toggle, 10 on rising, 11 on fall
#define ACIE  0x03 ;comparator interupt enable, must be disabled while changing output options
#define ACI   0x04 ;comparator interupt flag, cleared when set to 1
#define ACO   0x05 ;comparator output, set when interupt triggered
#define ACD   0x06 ;comparator disable when 1 written to it
                   ;Timer/PWM defines****
#define TCCROA 0x2f;timer register
#define TCCROB 0x33;
#define COMOA0 0x00;
#define COMOA1 0x01; Timer configuration 
#define WGM00 0x00 ;waveform generator bit 0
#define WGM01 0x01 ;waveform generator bit 1 ; 10 for ctc mode
                   ;ADC defines for analog comparator****
#define ADCSRB 0x03;for ACME bit
#define ADCSRA 0x06;for ADEN bit
#define ADEN 0x07  ;cleared for adc channel to be used as negative terminal for comparator
#define ACME 0x06  ;set for adc channel to be used as negative terminal for comparator 
#define ADMUX 0x07 ; for mux control for comparator
#define MUX0 0x00  ; 00 ADC0, 01 ADC1...
#define MUX1 0x01
                   ;Watchdog****
#define MCUSR 0x34 ;MCU status register
#define WDRF 0x03  ; watchdog reset flag, reset by writing 0 to it
#define WDTCR 0x21 ;Watchdog Timer Control Register
#define WDTIE 0x06 ;watchdog timer interupt enable
#define WDE 0x03   ;Watchdog will not cause reset if interupt triggered - if cleared*
#define SREG 0x3f ;status register

cli                ;clear interupts just incase for setup
;sbi WDTCR, WDTIE    ;Watchdog Interupt enabled 
;cbi WDTCR, WDE      ;Watchdog will trigger interupt and not reset
cbi ACSR, ACD       ;comparator enabled
cbi ACSR, ACIE      ;disabled so output trigger can be chosen
cbi ADCSRA, ADEN   
sbi ADCSRB, ACME    ;mux now availble for comparator input
sbi ADMUX, MUX1
cbi ADMUX, MUX0     ;ADC2 of PB4 used for negative terminal of comparator
sbi ACSR, ACIS0
sbi ACSR, ACIS1     ;interrupt on rising edge
sbi ACSR, ACIE      ;analog comparator interupt enabled
cbi PortB, 0x00 ;PB0 cleared
cbi PortB, 0x02 ;PB2 cleared
cbi PortB, 0x03 ;PB3 cleared
cbi PortB, 0x04 ;PB4 cleared
cbi DDRB,  0x00 ;PB0 input
cbi DDRB,  0x04 ;PB4 input PB0 and 4 for analog comparator 
cbi DDRB,  0x02 ;PB2 input
cbi DDRB,  0x03; PB3 input
sbi DDRB,  0x02 ;PB1 output for Solid state relay (SSR) toggle
ldi r20, 0x00
out TCCROA, r20
;cbi TCCROA, COMOA0
;cbi TCCROA, COMOA1 ;Timer set to normal port operation
;cbi TCCROA, 0x00
;cbi TCCROA, 0x01 
ldi r20, 0x01
out TCCROB, r20
;cbi TCCROB, 0x03 ;normal counting up to 0xFF
;sbi TCCROB, 0x01
;cbi TCCROB, 0x02 
;cbi TCCROB, 0x00 ;timer prescaler set to 1024
ldi r19, 0x00 ;counter variable
ldi r16, 0x27 ; 255 counter TOP
sei				   ;Global interupt enabled
LOOP:
ldi r21, 0x27
sbis PinB, 0x03
lsr r21
sbis PinB, 0x03
lsr r21
rjmp LOOP

TIM0_OVF:
in r15, SREG 
mov r18, r21 ;value based on dimming value (ON)
ldi r19, 0x00 ;counter variable
cp r19, r16 ; compare counter with 39 cycles
brge set0
cp r19, r18 ;compare counter with on cycles
brlt turnon ;cycles less than on time = on, greater than = off
cbi PortB, 0x02 ;turn off LED
inc r19
out SREG, r15
reti
turnon:
sbi PortB, 0x02 ; turn on LED
inc r19 ;increment counter
out SREG, r15
reti ;exit handler reset global interrupt
set0:
ldi r19, 0x00 ;counter variable reset to 0
out SREG, r15
reti

ANA_COMP:
in r15, SREG
ldi r22, 0x01
sts 0x39, r22 ;Timer interrupt enabled
cbi ACSR, ACIE ;found 0 no longer need
out SREG, r15
reti
