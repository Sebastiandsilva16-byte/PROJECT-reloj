
// Creado: 16/02/2026
// Autor : Sebastian Da Silva
// Descripcion:Reloj proyecto

.include "M328PDEF.inc"

.dseg
.org    SRAM_START

.cseg
.org 0x0000
    RJMP SETUP
.org 0x0008
	RJMP INTBOTONES //interrpciones de botones portB
.org 0x0016         
    RJMP TIMER1_COMPA	// Vector de interrupción para TIMER1_COMPA 



.org 0x0034

SETUP:
    // Configuraci?n de la pila
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16
		
// ------------------------------------
	SBI DDRB, DDB5    // led para probar
    CBI PORTB, PORTB5

	WDT_disable:
    LDI R16, (1<<WDCE) | (1<<WDE)
    STS WDTCSR, R16
    LDI R16, (0<<WDE)
    STS WDTCSR, R16

	
//input botones (pullup)
	CBI DDRB, DDB0
	SBI PORTB, PORTB0
	CBI DDRB, DDB1
	SBI PORTB, PORTB1
	CBI DDRB, DDB2
	SBI PORTB, PORTB2
	CBI DDRB, DDB3
	SBI PORTB, PORTB3
// Salidas LEDs (PC0-PC5) y (PD3) (apagados) (7 segmentos)
	SBI DDRC, DDC0    // PC0 salida
    CBI PORTC, PORTC0
	SBI DDRC, DDC1    // PC1 salida
    CBI PORTC, PORTC1
	SBI DDRC, DDC2    // PC2 salida
    CBI PORTC, PORTC2
	SBI DDRC, DDC3    // PC3 salida
    CBI PORTC, PORTC3
	SBI DDRC, DDC4    // PC4 salida
    CBI PORTC, PORTC4
	SBI DDRC, DDC5    // PC5 salida
    CBI PORTC, PORTC5
	SBI DDRD, DDD2    // PD2 Salida
    CBI PORTD, PORTD2 
	// Salidas para habilitar que display actualizar (PD3-PD6)
	SBI DDRD, DDD3    // PD3 Salida
    CBI PORTD, PORTD3 
	SBI DDRD, DDD4    // PD4 Salida
    CBI PORTD, PORTD4
	SBI DDRD, DDD5    // PD5 Salida
    CBI PORTD, PORTD5 
	SBI DDRD, DDD6    // PD6 Salida
    CBI PORTD, PORTD6  

	// Configuración Timer1 para 1 minuto en modo CTC ----------------------------------------------------------------------------------


	// Configurar modo CTC (WGM12=1) y prescaler 1024 (CS12=1, CS10=1) 
	LDI R16, (1 << WGM12) | (1 << CS12) | (0 << CS11) | (1 << CS10)
	STS TCCR1B, R16

	// Cargar OCR1A (para 16 MHz) ( 15625 | 0x3D09) (ya cuenta 1 min aprox hay que revisar mejor)
	
	LDI R16, 0x3D
	STS OCR1AH, R16
	LDI R16, 0x09
	STS OCR1AL, R16


	// Inicializar TCNT1 a 0
	CLR R16
	STS TCNT1H, R16
	STS TCNT1L, R16

	LDI R16, (1 << OCIE1A)
    STS TIMSK1, R16

		
	// Habilita interrupciones del puertoB --------------------------------
	LDI r16, (1 << PCIE0)
	STS PCICR, r16
	// Botones PB0 -> PB3
	LDI r16, (1 << PCINT0) | (1 << PCINT1) | (1 << PCINT2) | (1 << PCINT3)
	STS PCMSK0, r16


    // Inicializar registros
    CLR R16		//
    CLR R17		// Contador de segundos
    CLR R18		// Cuenta unidades Minutos
	CLR R19		// in del portb para saber el estado de los botones
	CLR R20		// in pasado del portb
    CLR R21		// Seleciona Display
	CLR R22		// Cuenta Decenas Minutos
	CLR R23		// Valor a buscar en el .db
	CLR R24		// Cuenta HORAS
	CLR R25		// Agarra los valores de R23 Para Actualizar el display
	CLR R26		// Decenas de HORAS

    SEI        // Habilitar interrupciones globales

//------------------------------------------------------------------------------------- ACABA CONFIG----------------------------------------------------------------------------------------

MAIN_LOOP:
    CALL TIEMPO
	CALL DISPF
	CALL BOTONES
	RJMP MAIN_LOOP

BOTONES:
	
	CP R19, R20	
	BRNE FINBOTONES
	IN	R19, PINB
	
	SBRS R19, PB0
	CALL boton_PB0
	SBRS R19, PB1
	CALL boton_PB1
	SBRS R19, PB2
	CALL boton_PB2
	SBRS R19, PB3
	CALL boton_PB3

	FINBOTONES:
	MOV R20, R19 //guarda el estado pasado de portb
	RET

boton_PB0:
	SBI PINB, PINB5 
	RET
boton_PB1:
	RET
boton_PB2:
	RET
boton_PB3:
	RET


DISPF:
    CPI R21, 4
	BRLO DISPSEL     // Si R21 < 4, está bien
    CLR R21          // Si R21 >= 4, resetea a 0    
	RET

DISPSEL:
	CALL DISPLAYSEL
	INC R21 //Va haciendo la cuenta para actulizar los contadores individualmente
    RET

DISPLAYSEL:

    CPI R21, 0 // Compara con 0
    BREQ DISP0 // Salta a DISP0 si R21 = 0
    CPI R21, 1 // Compara con 1
    BREQ DISP1 // Salta a DISP1 si R21 = 1
    CPI R21, 2 // Compara con 2
    BREQ DISP2 // Salta a DISP2 si R21 = 2
    CPI R21, 3 // Compara con 3
    BREQ DISP3 // Salta a DISP3 si R21 = 3
	//nunca deberia pasar sin saltar

DISP0:
    CBI PORTD, 4    // Apaga PD4
    CBI PORTD, 5    // Apaga PD5
    CBI PORTD, 6    // Apaga PD6
    SBI PORTD, 3    // Enciende PD3 (DISP0)
	MOV R23, R18	// Cuenta de Unidades S a R23
	RJMP DISPLAY

DISP1:
    CBI PORTD, 3    // Apaga PD3
    CBI PORTD, 5    // Apaga PD5
    CBI PORTD, 6    // Apaga PD6
    SBI PORTD, 4    // Enciende PD4 (DISP1)
	MOV R23, R22	// Cuenta de Decenas S a R23
    RJMP DISPLAY

DISP2:
    CBI PORTD, 3    // Apaga PD3
    CBI PORTD, 4    // Apaga PD4
    CBI PORTD, 6    // Apaga PD6
    SBI PORTD, 5    // Enciende PD5 (DISP2)
	MOV R23, R24	// Cuenta de Unidades S a R23
    RJMP DISPLAY

DISP3:
    CBI PORTD, 3    // Apaga PD3
    CBI PORTD, 4    // Apaga PD4
    CBI PORTD, 5    // Apaga PD5
    SBI PORTD, 6    // Enciende PD6 (DISP3)
	MOV R23, R26	// Cuenta de Decenas S a R23
    RJMP DISPLAY

DISPLAY:
	PUSH R20
	PUSH ZH
    PUSH ZL

    LDI ZH, HIGH(disp7seg << 1)
    LDI ZL, LOW(disp7seg << 1)

	// busca los valores para el 7 segmentos
	lsl R23		//mueve los bits a la iz (multiplica por 2)
	ADD ZL, R23
	LDI R20, 0
	ADC ZH, R20
	LPM R23, Z

	POP ZL
    POP ZH
	POP R20

	//Actualiza todo el portC (6 segmentos)
	MOV R25, R23
	OUT PORTC, R25  
	//Actualiza el ultimo segmento
	SBRC R25, 6
    SBI PORTD, PORTD2
    SBRS R25, 6
    CBI PORTD, PORTD2

	//Limpia para que no afecte los otros diplays
	CLR R25
	OUT PORTC, R25  
	//Actualiza el ultimo segmento
	SBRC R25, 6
    SBI PORTD, PORTD2
    SBRS R25, 6
    CBI PORTD, PORTD2 
RET


TIEMPO:
	
	CPI R17, 59 //segundos
    BRLO TIMER_RET
	CLR R17

	//Unidades de Minutos
	INC R18
    CPI R18, 10
    BRLO TIMER_RET
	CLR R18

	INC R22			//Decenas de Minutos
	CPI R22, 6
	BRLO TIMER_RET
	CLR R22

	INC R24			//Unidades de Horas
	CPI R26, 2	
	BRNE ZEROoDIEZ // revisa que no ha llegado a 20
	CPI R24, 4
	BRLO TIMER_RET
	CLR R24
	RJMP DECENASdeHORAS
ZEROoDIEZ:
	CPI R24, 10
	BRLO TIMER_RET
	CLR R24

DECENASdeHORAS:
	INC R26			//Decenas de Horas
	CPI R26, 3
	BRLO TIMER_RET
	CLR R26

TIMER_RET:
    RET


// Rutina de interrupci?n del Timer1 - Modo COMPARE MATCH
TIMER1_COMPA:      
    PUSH R16
    IN R16, SREG
    PUSH R16
    
    INC R17                 // Incrementar contador de ciclos
	IN R19, PINB			// Guarda el estado actual del portb
	//SBI PINB, PINB5       //deshabilitado temporalmente
 
	POP R16      
	OUT SREG, R16 
	POP R16     
	RETI

// Rutina de interrupci?n del PORTB
INTBOTONES:
	PUSH R16
	IN R16, SREG
	PUSH R16	
	
	IN	R19, PINB

	POP R16
	OUT SREG, R16
	POP R16
	RETI



// Tabla para display de 7 segmentos (referencia)
disp7seg:
    .db 0b00111111 // 0
    .db 0b00000110 // 1
    .db 0b01011011 // 2
    .db 0b01001111 // 3
    .db 0b01100110 // 4
    .db 0b01101101 // 5
    .db 0b01111101 // 6
    .db 0b00000111 // 7
    .db 0b01111111 // 8
    .db 0b01100111 // 9
    .db 0b01110111 // A
    .db 0b01111100 // b
    .db 0b00111001 // C
    .db 0b01011110 // d
    .db 0b01111001 // E
    .db 0b01110001 // F