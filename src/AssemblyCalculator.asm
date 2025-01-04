		LIST 	P=PIC16F877
		include	<p16f877.inc>
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_ON & _CPD_OFF


;declare variables
Variable EQU 0X70 ; extra variable

RESULT EQU 0X60

CMD EQU 0X50

OpA EQU 0x30 

OpB EQU 0x40


		org		0x00		
reset:	goto	start

		org		0x10
start:	bcf		STATUS, RP0
		bcf		STATUS, RP1			; Bank0 

		clrf	PORTD
		clrf	PORTE
		
		bsf		STATUS, RP0		;Bank 1
		movlw	0x06
		movwf	ADCON1 ; make the ports output 

		clrf	TRISE		;porte output 
		clrf	TRISD		;portd output
		movlw   0x0F	;4 Low bits of PORTB are input,4 High bits output - keybord
		movwf   TRISB
		
		MOVLW 0X08 ; The number of bits in register (Counter)
		MOVWF 0X21 ; Register for the Counter
		
		bcf     OPTION_REG,0x07 ; RBPU is ON -->Pull UP on PORTB is enabled 
	
		bcf		STATUS, RP0		;Bank 0
		bcf		STATUS, IRP 	;For indirect addressing
		call	init

		clrf	INTCON ;disable all interrupt
		
		clrf CMD
		clrf OpB
		clrf OpA
		clrf RESULT
		call display_variabls ;wrire on the screen 

main:
		clrf CMD
		clrf OpB
		clrf OpA
		clrf RESULT

KeyboardInputs:
		call input_letter
		movwf 0x69 ; 69 contains the information of wich opperand to enter
		btfsc 0x69,0x0 ;if the fist bit of 69 is 1 letter is A:
			movlw OpA 
		btfsc 0x69,0x1 ;if the seconed bit of 69 is 1 letter is B:
			movlw OpB
		btfsc 0x69,0x2 ;if the third bit of 69 is 1 letter is C:
			movlw CMD
		movwf FSR ;File select register pointer of the adress of the bank

		clrf RESULT 
		bcf FSR,0x7  ;bank 0 address 
		call input_iteral;subroutine to input four digits from keyboard
		movlw 0x0
		subwf CMD,W 
		btfsc STATUS,Z ;if OPCODE is 000, goto input ;bit 2 in status is named z. It checks if the result of an opperation is zero
			goto KeyboardInputs
		;call input_iterals ;get input from the user
		
		;checks what CMD we have chosen by subtracting the number of the CMD from a nuber set into w
		;if the result is  zero the CMD is set

		movlw 0x02
		subwf CMD,W 
		btfsc STATUS,Z ;if OPCODE is 0010, return A-B
			call SubAfromB	
		
		movlw 0x04
		subwf CMD,W
		btfsc STATUS,Z ;if OPCODE is 0100, return A*B
			call AmultB
		
		movlw 0x06
		subwf CMD,W
		btfsc STATUS,Z ;if OPCODE is 0110, return A/B
			call AdivideB

		movlw 0x08
		subwf CMD,W
		btfsc STATUS,Z ;if OPCODE is 1000, return A^B
			call ApowerB

		movlw 0x0A
		subwf CMD,W
		btfsc STATUS,Z ;if OPCODE is 1010, return bit 1 in A
			call OnesCounter

		movlw 0x0C
		subwf CMD,W
		btfsc STATUS,Z ;if OPCODE is 1100, return bit 0 in B
			call firstBitB
		
		movlw 0x0B 
		subwf CMD,W
		btfsc STATUS,Z ;if OPCODE is 1011, return 
			call PirsOfOnes

		call display_variabls

		goto KeyboardInputs
		
;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;Subtract operand A form B 
;
SubAfromB:
	clrf RESULT
	movf OpA,W
	movwf 0x41 ;A
	movf OpB,W
	movwf 0x42 ;B

	movf 0x42,W
	subwf 0x41,W 
	movwf RESULT ; 41-42	A-B

	btfsc STATUS,C ;if the result positive
		return
	movf 0x41,W
	subwf 0x42,W
	movwf RESULT
	
	bsf RESULT,0x4 ;if the number negative
	return

;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;Multiplay A with B 
;
AmultB: 
	movf OpA,W
	movwf 0x41
	movf OpB,W
	movwf 0x42

	clrf RESULT
	movf 0x42,W
	btfsc STATUS,Z ;if B==0, return 0
		return
	multLoop: ;do{
		movf 0x41,W
		addwf RESULT,f ;result +=A
		
		;handle overflow:
		btfsc RESULT,4
			goto Error2Display
		btfsc RESULT,5
			goto Error2Display
		btfsc RESULT,6
			goto Error2Display
		btfsc RESULT,7
			goto Error2Display

		decf 0x42,f ;B--
		btfss STATUS,Z ;}while(B!=0)
			goto multLoop
	return
	
;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;subroutine to preform dev
;
AdivideB:
	movf OpA,W
	movwf 0x41
	movf OpB,W
	movwf 0x42

	clrf RESULT
	movf 0x42,W
	btfsc STATUS,Z ;if B==0, return 0
		goto Error2Display ;write error
	devLoop: ;do
		movf 0x42 ,W
		subwf 0x41,f ;A -=B
		btfss STATUS, C ;if A<0, return
			return
		incf RESULT,f ;RES++
		goto devLoop ;while A>0 
	return
	
;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;subroutine to preform pow
;	
ApowerB:
	clrf RESULT
	movf OpA,W
	btfss STATUS,Z ;if A!=0:
		goto startPow
	movf OpB,W
	btfss STATUS,Z ;if B!=0:
		goto startPow
	goto Error2Display ;if A==0 and B==0 display error
	startPow:
	movlw 0x1
	movwf RESULT ;res=1
	
	movf OpA,W
	movwf 0x43
	movf OpB,W
	btfsc STATUS,Z; if b==0:
		return ; return 1
	movwf 0x44
	movf OpA,W
	movwf RESULT ;res = A
	clrf 0x61
	movf OpB,W
	movwf 0x62
	movf OpA,W
	movwf OpB;B=A
	powLoop:
		decf 0x62 ;C--
		btfsc STATUS,Z ;if c==0, exit 
		    goto powEnd
		call AmultB;RES=A*B
		movf RESULT,W
		movwf OpA ;A=RES
		goto powLoop
	powEnd:
	;movf 0x41,W
	;movwf RESULT
	movf 0x43,W
	movwf OpA
	movf 0x44,W
	movwf OpB
	return

;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;Counte 1 bits of A
;		

OnesCounter:
	clrf RESULT
	MOVLW 0X08 ; The number of bits in register (Counter)
	MOVWF 0X25 ; Register for the Counter
	MOVF OpA,W
	MOVWF 0x27

	
NewNumber:
		BTFSC 0x27,0	
		goto One		;If the bit is one
		goto Zero		;If the bit is zero

One:	incf RESULT		;Add one to the Pair Result


Zero:	RRF 0x27,1 		;Rotate right
		DECFSZ 0X25,1	;Countdown
		goto	NewNumber
	return

;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;Counte 0 bits of B
;		

firstBitB:
	clrf RESULT
	btfss OpB,0
		incf RESULT,f
	btfss OpB,1
		incf RESULT,f
	btfss OpB,2
		incf RESULT,f
	btfss OpB,3
		incf RESULT,f
	return


;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;Counte the pires of one in operand B
;
PirsOfOnes:

	clrf RESULT
	MOVLW 0X08 ; The number of bits in register (Counter)
	MOVWF 0X25 ; Register for the Counter
	CLRF  0X26 ; The result of the sum of zeros
	MOVF OpB,W
	MOVWF 0x27

	
NewNumber:
		BTFSC 0x27,0	
		goto One		;If the bit is one
		goto Zero		;If the bit is zero

One:	incf 0X26		;Add one to the Pair check

		btfsc 0X26, 1 	;Checks if there is a pair and add one to the result
		incf RESULT  
		
		btfsc 0X26, 1 	;If it's pair clear Pair check
		clrf 0X26


Zero:	RRF 0x27,1 		;Rotate right
		DECFSZ 0X25,1	;Countdown
		goto	NewNumber
		return


;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;subroutine to input four digits from keyboard
;
input_iterals:
	;call display_variabls
	input_A:
		call input_letter
		movwf 0x69
		btfss 0x69,0x0 ;if letter is not A:
			goto Error2Display
		
		movlw	0x01		; display clear
		movwf	0x20
		call 	lcdc
		call	mdel

		call display_variabls
		call input_digit
		movwf 0x31
		btfsc 0x31,0x0
			bsf OpA,0x3
		call display_variabls

		call Delay
		call input_digit
		movwf 0x31
		btfsc 0x31,0x0
			bsf OpA,0x2
		call Delay
		call display_variabls

		call input_digit
		movwf 0x31
		btfsc 0x31,0
			bsf OpA,0x1
		call display_variabls

		call Delay

		call input_digit
		movwf 0x31
		btfsc 0x31,0x0
			bsf OpA,0x0
		movf OpA
		call display_variabls

	input_B
		call input_letter
		movwf 0x69
		btfss 0x69,0x1 ;if letter is not B:
			goto Error2Display ;write error
		call Delay

		call input_digit ;input first digit
		movwf 0x31
		btfsc 0x31,0x0
			bsf OpB,0x3
		call display_variabls 
		
		call Delay
		call input_digit ; input second digit
		movwf 0x31
		btfsc 0x31,0x0
			bsf OpB,0x2
		call display_variabls
		
		call Delay
		call input_digit ; input thered digit
		movwf 0x31
		btfsc 0x31,0
			bsf OpB,0x1
		call display_variabls
		
		call Delay	
		call input_digit ; input fourth digit
		movwf 0x31
		btfsc 0x31,0x0
			bsf OpB,0x0

		movf OpB,W
		call display_variabls

	input_C
		call input_letter
		movwf 0x69
		btfss 0x69,0x2 ;if letter is not C:
			goto Error2Display
		call Delay

		call input_digit
		movwf 0x31
		btfsc 0x31,0x0
			bsf CMD,0x2
		call display_variabls
		
		call Delay
		call input_digit
		movwf 0x31
		btfsc 0x31,0x0
			bsf CMD,0x1
		call display_variabls
		call Delay
		
		call input_digit
		movwf 0x31
		btfsc 0x31,0
			bsf CMD,0x0
	
		call display_variabls
	return
;---------------------------------------------------------------------------------------
;
;subroutine to input digit from keyboard, check if get digit 
;
input_digit:
	call Input2W ; checks the number inputed from keyboard saves it in w
	movwf 0x31 ; moves the input to reg.31
	btfsc 0x31, 0x3 ;if input is letter:
		goto Error2Display
	return 

;---------------------------------------------------------------------------------------
;
;subroutine to input letter from keyboard
;
input_letter:
	call Input2W ; checks the number inputed from keyboard saves it in w
	movwf 0x31
	btfss 0x31, 0x3 ;if input is number:
		goto Error2Display
	return 

;---------------------------------------------------------------------------------------
;
;subroutine to input four digits from keyboard into pointer in FSR
;
input_iteral:
		movlw	0x01		; display clear
		movwf	0x20
		call 	lcdc
		call	mdel
		
		clrf INDF

		call display_variabls

		;movlw CMD  
		;subwf FSR,w
		;btfsc STATUS,Z ;if FSR is CMD, skip first digit
		;	goto sec_digit

		call input_digit
		movwf 0x31
		btfsc 0x31,0x0 ;if input is 1
			bsf INDF,0x3 ; put 1 in bit 4
		call display_variabls
		call Delay

sec_digit: ;check input from seconed digit
		call input_digit
		movwf 0x31
		btfsc 0x31,0x0 ;if input is 1
			bsf INDF,0x2 ; put 1 in bit 3
		call Delay
		call display_variabls

		call input_digit
		movwf 0x31
		btfsc 0x31,0 ;if input is 1
			bsf INDF,0x1; put 1 in bit 2
		call display_variabls

		call Delay

		call input_digit
		movwf 0x31
		btfsc 0x31,0x0 ;if input is 1
			bsf INDF,0x0; put 1 in bit 1
		movf INDF
		
		call display_variabls


;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;subroutine to display variables
;
display_variabls:
;---------DISPLAY A-----------
	movlw	0x80			 ;PLACE for the data on the LCD
	movwf	0x20
	call 	lcdc

	movlw	'A'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
		
	movlw	':'			; CHAR (the data )
	movwf	0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc OpA,3 ;check if bit is 1
		incf 0x20 ; if its 1 add 1 to ascii code of zero wich is the ascii code of 1
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc OpA,2
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc OpA,1
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc OpA,0
		incf 0x20
	call 	lcdd

	;---------DISPLAY B-----------
	movlw	0x87			 ;PLACE for the data on the LCD
	movwf	0x20
	call 	lcdc

	movlw	'B'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
		
	movlw	':'			; CHAR (the data )
	movwf	0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc OpB,3
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc OpB,2
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc OpB,1
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc OpB,0
		incf 0x20
	call 	lcdd
	
	call	mdel

;---------DISPLAY C-----------
	movlw	0xc0			 ;PLACE for the data on the LCD
	movwf	0x20
	call 	lcdc

	movlw	'C'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
		
	movlw	':'			; CHAR (the data )
	movwf	0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc CMD,3
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc CMD,2
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc CMD,1
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc CMD,0
		incf 0x20
	call 	lcdd
;---------DISPLAY RES-----------
	movlw	0xc6			 ;PLACE for the data on the LCD
	movwf	0x20
	call 	lcdc

	movlw	' '			; CHAR (the data )
	movwf	0x20
	call 	lcdd
	
	movlw	'R'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
		
	movlw	':'			; CHAR (the data )
	movwf	0x20
	call 	lcdd

	movlw '-'
	movwf	0x20
	btfsc RESULT,4 ;if number is negative, write '-'
		call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc RESULT,3
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc RESULT,2
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc RESULT,1
		incf 0x20
	call 	lcdd

	movlw '0'
	movwf	0x20
	btfsc RESULT,0
		incf 0x20
	call 	lcdd
	
	call	mdel
	return

;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;subroutine to write error on the LCD
;
Error2Display:
	movlw	0x01		; display clear
	movwf	0x20
	call 	lcdc
	call	mdel

	movlw	0x80		;PLACE for the data on the LCD
	movwf	0x20
	call 	lcdc

	movlw	'E'			; Write E
	movwf	0x20
	call 	lcdd
		
	movlw	'R'			; Write R twice
	movwf	0x20
	call 	lcdd
	call 	lcdd

	movlw	'O'			; Write O
	movwf	0x20
	call 	lcdd

	movlw	'R'			; Write R
	movwf	0x20
	call 	lcdd

	call mdel
	
	goto main
;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;subroutine to initialize LCD
;
init	movlw	0x30
		movwf	0x20
		call 	lcdc
		call	del_41

		movlw	0x30
		movwf	0x20
		call 	lcdc
		call	del_01

		movlw	0x30
		movwf	0x20
		call 	lcdc
		call	mdel

		movlw	0x01		; display clear
		movwf	0x20
		call 	lcdc
		call	mdel

		movlw	0x06		; ID=1,S=0 increment,no  shift 000001 ID S
		movwf	0x20
		call 	lcdc
		call	mdel

		movlw	0x0c		; D=1,C=B=0 set display ,no cursor, no blinking
		movwf	0x20
		call 	lcdc
		call	mdel

		movlw	0x38		; dl=1 ( 8 bits interface,n=12 lines,f=05x8 dots)
		movwf	0x20
		call 	lcdc
		call	mdel
		return

;
;subroutine to write CMD to LCD
;

lcdc	movlw	0x00		; E=0,RS=0 
		movwf	PORTE
		movf	0x20,w
		movwf	PORTD
		movlw	0x01		; E=1,RS=0
		movwf	PORTE
        call	sdel
		movlw	0x00		; E=0,RS=0
		movwf	PORTE
		return

;
;subroutine to write data to LCD
;

lcdd	movlw		0x02		; E=0, RS=1
		movwf		PORTE
		movf		0x20,w
		movwf		PORTD
        movlw		0x03		; E=1, rs=1  
		movwf		PORTE
		call		sdel
		movlw		0x02		; E=0, rs=1  
		movwf		PORTE
		return

;----------------------------------------------------------

del_41	movlw		0xcd
		movwf		0x23
lulaa6	movlw		0x20
		movwf		0x22
lulaa7	decfsz		0x22,1
		goto		lulaa7
		decfsz		0x23,1
		goto 		lulaa6 
		return


del_01	movlw		0x20
		movwf		0x22
lulaa8	decfsz		0x22,1
		goto		lulaa8
		return


sdel	movlw		0x19		; movlw = 1 cycle
		movwf		0x23		; movwf	= 1 cycle
lulaa2	movlw		0xfa
		movwf		0x22
lulaa1	decfsz		0x22,1		; decfsz= 12 cycle
		goto		lulaa1		; goto	= 2 cycles
		decfsz		0x23,1
		goto 		lulaa2 
		return


mdel	movlw		0x0a
		movwf		0x24
lulaa5	movlw		0x19
		movwf		0x23
lulaa4	movlw		0xfa
		movwf		0x22
lulaa3	decfsz		0x22,1
		goto		lulaa3
		decfsz		0x23,1
		goto 		lulaa4 
		decfsz		0x24,1
		goto		lulaa5
		return


;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;subroutine to get input binary digit from keyboard
;
Input2W:
;-----------------------------------------------------------------------
wkb:    bcf             PORTB,0x4     ;Line 0 of Matrix is enabled
        bsf             PORTB,0x5
        bsf             PORTB,0x6
        bsf             PORTB,0x7
;-----------------------------------------------------------------------
        btfss           PORTB,0x0     ;Scan for 1,2,3,A
        goto            kb01
        btfss           PORTB,0x1
        goto            kb02
        btfss           PORTB,0x2
        goto            kb03
        btfss           PORTB,0x3
        goto            kb0a
;-----------------------------------------------------------------------
        bsf             PORTB,0x4	;Line 1 of Matrix is enabled
        bcf             PORTB,0x5
;-----------------------------------------------------------------------
        btfss           PORTB,0x0	;Scan for 4,5,6,B
        goto            kb04
        btfss           PORTB,0x1
        goto            kb05
        btfss           PORTB,0x2
        goto            kb06
        btfss           PORTB,0x3
        goto            kb0b
;-----------------------------------------------------------------------	
        bsf             PORTB,0x5	;Line 2 of Matrix is enabled
        bcf             PORTB,0x6
;-----------------------------------------------------------------------
        btfss           PORTB,0x0	;Scan for 7,8,9,C
        goto            kb07
        btfss           PORTB,0x1
        goto            kb08
        btfss           PORTB,0x2
        goto            kb09
        btfss           PORTB,0x3
        goto            kb0c
;-----------------------------------------------------------------------
        bsf             PORTB,0x6	;Line 3 of Matrix is enabled
        bcf             PORTB,0x7
;----------------------------------------------------------------------
        btfss           PORTB,0x0	;Scan for *,0,#,D
        goto            kb0e ;*
        btfss           PORTB,0x1
        goto            kb00
        btfss           PORTB,0x2
        goto            kb0f ;#
        btfss           PORTB,0x3
        goto            kb0b
;----------------------------------------------------------------------


        goto            wkb

kb00:   movlw           0x00;0000 - 1
        goto            disp	
kb01:   movlw           0x01;0001 - 2
        goto            disp	
kb02:   movlw           0x02
        goto            Error2Display
kb03:   movlw           0x03
        goto            Error2Display		
kb04:   movlw           0x04
        goto            Error2Display
kb05:   movlw           0x05
        goto            Error2Display
kb06:   movlw           0x06
        goto            Error2Display
kb07:   movlw           0x07
        goto            Error2Display
kb08:   movlw           0x08
        goto            Error2Display
kb09:   movlw           0x09
        goto            Error2Display
kb0a:   movlw           0x09 ;1001 - A
        goto            disp	
kb0b:   movlw           0x0a ;1010 - B
        goto            disp	
kb0c:   movlw           0x0c ;1100 - C
        goto            disp	
kb0d:   movlw           0x0d
        goto            Error2Display
kb0e:   movlw           0x0e
        goto            Error2Display
kb0f:   movlw           0x0f
        goto            Error2Display


disp:return


;=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;Delay 500ms
;

Delay:					;-----> 500ms delay
		movlw		0x24			;N1 = 50d
		movwf		0x51
CONT5:	movlw		0x80			;N2 = 128d
		movwf		0x52
CONT6:	movlw		0x80			;N3 = 128d
		movwf		0x53
CONT7:	decfsz		0x53, f
		goto		CONT7
		decfsz		0x52, f
		goto		CONT6
		decfsz		0x51, f
		goto		CONT5
		return

		end
