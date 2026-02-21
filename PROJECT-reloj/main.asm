
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

    
    // Salidas LEDs (PD4-PD7) (apagados)
    SBI DDRD, DDD4    // PD4 salida
    CBI PORTD, PORTD4 
    SBI DDRD, DDD5    // PD5 salida
    CBI PORTD, PORTD5
    SBI DDRD, DDD6    // PD6 salida
    CBI PORTD, PORTD6
    SBI DDRD, DDD7    // PD7 salida
    CBI PORTD, PORTD7
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
	SBI DDRD, DDD3    //  salida  (PC6 se quemo y no funciona)
    CBI PORTD, PORTD3 
	// Salidas LEDs (PB0-PB5) y (PC7) (apagados) (7 segmentos 2)
	SBI DDRB, DDB0    // PB0 como salida 
	CBI PORTB, PORTB0 // A
	SBI DDRB, DDB1    // PB1 como salida 
	CBI PORTB, PORTB1
	SBI DDRB, DDB2    // PB2 como salida 
	CBI PORTB, PORTB2
	SBI DDRB, DDB3    // PB3 como salida 
	CBI PORTB, PORTB3
	SBI DDRB, DDB4    // PB4 como salida 
	CBI PORTB, PORTB4
	SBI DDRB, DDB5    // PB5 como salida 
	CBI PORTB, PORTB5
	SBI DDRD, DDD2    // PD2 como salida 
	CBI PORTD, PORTD2

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
    CLR R17		// Contador de ciclos timer (para 1 segundo)
    CLR R18		// Contador para LEDs (0-15)
    CLR R21		// para actualizar los leds
	CLR R19		// para los leds del 7 segmentos
	CLR R20		// ayuda para leds del 7 segmentos
	CLR R26		// cuenta del segundo segmento
    SEI        // Habilitar interrupciones globales

//-------------------------------------------------------------------------------------

MAIN_LOOP:
    CALL LEDS
    CALL TIEMPO
	CALL DISPLAY //(segundos)
    RJMP MAIN_LOOP

DISPLAY:
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

		//XGFEDCBA  en el portd quiero FEDCBA00y en el portB quiero sacar G
	MOV R25, R19
    
	OUT PORTC, R25

	SBRC R25, 6
    SBI PORTD, PORTD3
    SBRS R25, 6
    CBI PORTD, PORTD3

//2do display
	PUSH ZH
    PUSH ZL

    LDI ZH, HIGH(disp7seg << 1)
    LDI ZL, LOW(disp7seg << 1)

	// busca los valores para el 7 segmentos
	MOV R19, R26
	lsl r19		//mueve los bits a la iz (multiplica por 2)
	ADD ZL, R19
	LDI R20, 0
	ADC ZH, R20
	LPM R19, Z
	POP ZL
    POP ZH

	MOV R25, R19

	OUT PORTB, R25

	SBRC R25, 6
    SBI PORTD, PORTD2
    SBRS R25, 6
    CBI PORTD, PORTD2

	RET

TIEMPO:
    CPI R17, 100
    BRLO TIMER_RET
    CLR R17
    INC R18
    CPI R18, 10
    BRLO TIMER_RET
	CLR R18
	INC R26
	CPI R26, 7
	BRLO TIMER_RET
    CLR R26
TIMER_RET:
    RET

LEDS:
    MOV R21, R18        // Copiar contador a registro temporal
    
    // PD7 (bit 0)
    SBRC R21, 0
    SBI PORTD, PORTD7
    SBRS R21, 0
    CBI PORTD, PORTD7
    
    // PD6 (bit 1)
    SBRC R21, 1
    SBI PORTD, PORTD6
    SBRS R21, 1
    CBI PORTD, PORTD6
    
    // PD5 (bit 2)
    SBRC R21, 2
    SBI PORTD, PORTD5
    SBRS R21, 2
    CBI PORTD, PORTD5
    
    // PD4 (bit 3)
    SBRC R21, 3
    SBI PORTD, PORTD4
    SBRS R21, 3
    CBI PORTD, PORTD4
    
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