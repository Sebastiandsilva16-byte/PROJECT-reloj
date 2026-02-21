
// Creado: 16/02/2026
// Autor : Sebastian Da Silva
// Descripci?n: Test del display de tiempo

.include "M328PDEF.inc"

.dseg
.org    SRAM_START

.cseg
.org 0x0000
    RJMP SETUP
.org 0x0020          // Vector de interrupci?n para TIMER0_COMPA (modo CTC)
    RJMP TIMER0_COMPA


.org 0x0034

SETUP:
    // Configuraci?n de la pila
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16

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

    // Configuraci?n Timer0 para 10ms en modo CTC
    LDI R16, (1 << WGM01)    ; Modo CTC (Clear Timer on Compare Match)
    OUT TCCR0A, R16
    
    // Configurar valor de comparaci?n para 10ms con prescaler 1024
    // Frecuencia = 16MHz / 1024 = 15625 Hz
    // Para 10ms: 15625 * 0.01 = 156.25 ciclos ? 156
    LDI R16, 155              // Valor de comparaci?n (OCR0A)
    OUT OCR0A, R16
    
    LDI R16, (1 << CS02) | (1 << CS00) // Prescaler 1024
    OUT TCCR0B, R16

    // Configurar interrupci?n del TIMER0 por COMPARE MATCH A
    LDI R16, (1 << OCIE0A)    // Habilita interrupci?n por comparaci?n
    STS TIMSK0, R16

    // Inicializar registros
    CLR R16		// Multifuncional
    CLR R17		// Contador de ciclos timer 10ms
    CLR R18		// Cuenta (S unidades)
	CLR R19		// (se usa para buscar los valores R18) busca los valores para el display
	CLR R20		// Se usa Zhigh eb DIPLAY
    CLR R21		// Seleciona Display
	CLR R22		// Cuenta Decenas

	CLR R25		// Agarra los valores de R19 Para Actualizar el display
	CLR R26		// Cuenta para las decenas de segundos (S)
    SEI        // Habilitar interrupciones globales

//-------------------------------------------------------------------------------------

MAIN_LOOP:
    CALL TIEMPO
	INC R21 //Va haciendo na cuenta para actulizar los contadores individualmente
    CPI R21, 2     
    BRLO DISPSEL     // Si R21 < 4, está bien
    CLR R21          // Si R21 >= 4, resetea a 0
DISPSEL:
	CALL DISPLAYSEL
    RJMP MAIN_LOOP

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
	CALL DISPLAY0

    RJMP FINDISP

DISP1:
    CBI PORTD, 3    // Apaga PD3
    CBI PORTD, 5    // Apaga PD5
    CBI PORTD, 6    // Apaga PD6
    SBI PORTD, 4    // Enciende PD4 (DISP1)
	CALL DISPLAY1
    RJMP FINDISP

DISP2:
    CBI PORTD, 3    // Apaga PD3
    CBI PORTD, 4    // Apaga PD4
    CBI PORTD, 6    // Apaga PD6
    SBI PORTD, 5    // Enciende PD5 (DISP2)
    RJMP FINDISP

DISP3:
    CBI PORTD, 3    // Apaga PD3
    CBI PORTD, 4    // Apaga PD4
    CBI PORTD, 5    // Apaga PD5
    SBI PORTD, 6    // Enciende PD6 (DISP3)
    RJMP FINDISP

FINDISP:
    RET

DISPLAY0:
	PUSH ZH
    PUSH ZL

    LDI ZH, HIGH(disp7seg << 1)
    LDI ZL, LOW(disp7seg << 1)

	// busca los valores para el 7 segmentos
	MOV R19, R18
	lsl r19		//mueve los bits a la iz (multiplica por 2)
	ADD ZL, R19
	LDI R20, 0
	ADC ZH, R20
	LPM R19, Z
	POP ZL
    POP ZH

	//Actualiza todo el portC (6 segmentos)
	MOV R25, R19
	OUT PORTC, R25  
	//Actualiza el ultimo segmento
	SBRC R25, 6
    SBI PORTD, PORTD2
    SBRS R25, 6
    CBI PORTD, PORTD2

	//limpia para que no afecte los otros diplays-----------------------------
	CLR R25
	OUT PORTC, R25  
	//Actualiza el ultimo segmento
	SBRC R25, 6
    SBI PORTD, PORTD2
    SBRS R25, 6
    CBI PORTD, PORTD2 //----------------------

RET

DISPLAY1:
	PUSH ZH
    PUSH ZL

    LDI ZH, HIGH(disp7seg << 1)
    LDI ZL, LOW(disp7seg << 1)

	// busca los valores para el 7 segmentos
	MOV R19, R22
	lsl r19		//mueve los bits a la iz (multiplica por 2)
	ADD ZL, R19
	LDI R20, 0
	ADC ZH, R20
	LPM R19, Z
	POP ZL
    POP ZH

	//Actualiza todo el portC (6 segmentos)
	MOV R25, R19
	OUT PORTC, R25  
	//Actualiza el ultimo segmento
	SBRC R25, 6
    SBI PORTD, PORTD2
    SBRS R25, 6
    CBI PORTD, PORTD2

	//limpia para que no afecte los otros diplays //----------------------
	CLR R25
	OUT PORTC, R25  
	//Actualiza el ultimo segmento 
	SBRC R25, 6
    SBI PORTD, PORTD2
    SBRS R25, 6
    CBI PORTD, PORTD2 //----------------------


RET

TIEMPO:

    CPI R17, 100
    BRLO TIMER_RET //Cuenta los 10ms
    CLR R17

    INC R18			//Unidades de Segundos
    CPI R18, 10
    BRLO TIMER_RET
	CLR R18

	INC R22			//Decenas de segundos
	CPI R22, 6
	BRLO TIMER_RET
	CLR R22

TIMER_RET:
    RET

// Rutina de interrupci?n del Timer0 - Modo COMPARE MATCH
TIMER0_COMPA:
    PUSH R16
    IN R16, SREG
    PUSH R16
    
    INC R17                 // Incrementar contador de ciclos
    
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