
// Creado: 16/02/2026
// Autor : Sebastian Da Silva
// Descripcion:Reloj proyecto

.include "M328PDEF.inc"

.dseg
.org  SRAM_START
.dseg
	.org 0x0100           
	unidadesMIN:			.byte 1
	decenasMIN:				.byte 1
	unidadesHOR:			.byte 1
	decenasHOR:				.byte 1
	unidadesDIA:			.byte 1
	decenasDIA:				.byte 1
	unidadesMES:			.byte 1
	decenasMES:				.byte 1
	Botonespressint:		.byte 1
	Botonespresspasado:     .byte 1
	Botonespresspasado2:    .byte 1
	Selectordisp:			.byte 1
	Configmas:				.byte 1
	Configmen:				.byte 1
	TMPactual:				.byte 1
	TMPalarma:				.byte 1
	loops:					.byte 1
	
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
	//LEDS ":"
	SBI DDRB, DDB5    // PB5 salida
    CBI PORTB, PORTB5
	// LED MODO
	SBI DDRD, DDD7    // PD7 salida
    CBI PORTD, PORTD7
	// Configuración Timer1 para 1 minuto en modo CTC ----------------------------------------------------------------------------------


	// Configurar modo CTC (WGM12=1) y prescaler 1024 (CS12=1, CS10=1) 
	LDI R16, (1 << WGM12) | (1 << CS12) | (0 << CS11) | (1 << CS10)
	STS TCCR1B, R16

	// Cargar OCR1A (para 16 MHz) 1E83 (medio sec)  (00FF) (pruebas)
	
	LDI R16, 0x00
	STS OCR1AH, R16
	LDI R16, 0x01
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


	// INICIALIZAR VARIABLES EN SRAM
    LDI R16, 0

    LDI R16, 1              // Día y mes empieza en 1
    STS unidadesDIA, R16
    STS unidadesMES, R16
    LDI R16, 0
    STS Botonespressint, R16
    STS Botonespresspasado, R16
	STS unidadesMIN, R16
    STS decenasMIN, R16
    STS unidadesHOR, R16
    STS decenasHOR, R16
	STS decenasMES, R16
	STS decenasDIA, R16


    // Inicializar registros
    CLR R16		// HORAMIN (0) / (MESDIA(1) 
    CLR R17		// Contador de segundos
    CLR R18		// Cuenta unidades Minutos	 // y de DIAS
	CLR R19		// Estado real de los botones
	CLR R20		// Modo
    CLR R21		// Seleciona Display
	CLR R22		// Cuenta Decenas Minutos	 // y de DIAS
	CLR R23		// Valor a buscar en el .db
	CLR R24		// Cuenta HORAS			     // y MES
	CLR R25		// Agarra los valores de R23 Para Actualizar el display
	CLR R26		// Decenas de HORAS		     // y MES
	CLR R27		// Carry
	CLR R28		// VARX (solo la llamo para comparaciones no guarda nada)
	CLR R29		// VARX 2
	CLR R30		// Para Z low
	CLR R31		// Para Z high

    SEI        // Habilitar interrupciones globales

//------------------------------------------------------------------------------------- ACABA CONFIG----------------------------------------------------------------------------------------

MAIN_LOOP:
	CALL MODO 
	CALL DISPF
	RJMP MAIN_LOOP

MODO:   //-------------------------------------------------------------------------------------------MODO SEL
    CPI R20, 0  // horas y minutos
    BREQ MODO0
    
    CPI R20, 1 // dias y meses
    BREQ MODO1
    
    CPI R20, 2  // config de 0
    BREQ MODO2
    
    CPI R20, 3 // config de 2
    BREQ MODO3
    
    CPI R20, 4 // config alarma
    BREQ MODO4
    
    CPI R20, 5 // set/reset alarma
    BREQ MODO5

	CLR R20  //(reinicia la cuenta de modos) y sigue al modo0


// PORTD7 Apagado  = Hora Min / Encendido = Mes / Dia
// PORTB5 (puntos) = Parpadeando = tiempo corre / encendido = config

// --------------------------------------------------------------------------------------------MODOS 
MODO0: //HORAS / MINUTOS
// llama la funcion que cuenta el tiempo
// y asigna r16 para que se muestre HH : MM
// des activa el led naranja para indicar HH:MM
	CLR R16
	CBI PORTD, PORTD7
    CALL TIEMPO
    RJMP FIN_COMPARAR

MODO1: //DIA / MES
// asigna r16 para que se muestre DD : MES
// activa el led naranja para indicar DD:MES
	LDI R16, 1
	SBI PORTD, PORTD7
    CALL TIEMPO
    RJMP FIN_COMPARAR

MODO2: // CONFIG HM
//	asigna r16 para que se muestre HH : MM
// des activa el led naranja para indicar HH:MM
// Enciende los : para indicar modo config
	CLR R16
	CBI PORTD, PORTD7
	SBI PORTB, PORTB5
    RJMP FIN_COMPARAR
	CALL CONFIGRELOJ

MODO3: // CONGIG MD
// asigna r16 para que se muestre DD : MES
// activa el led naranja para indicar DD:MES
// Enciende los : para indicar modo config
	LDI R16, 1
	SBI PORTB, PORTB5
	SBI PORTD, PORTD7
	CALL CONFIGRELOJ
    RJMP FIN_COMPARAR

MODO4: // CONFIG ALARMA
//	asigna r16 para que se muestre HH : MM
	CLR R16
    RJMP FIN_COMPARAR

MODO5: // APAGAR ALARMA
 //	asigna r16 para que se muestre HH : MM
	CLR R16
    RJMP FIN_COMPARAR

FIN_COMPARAR:
    RET

//--------------------------------------------------------------------------LOAD y SAVE 
// para reducir espacio en el codigo
LOADHM:
	LDS R18, unidadesMIN    // Cargar Unidades de Minuto
    LDS R22, decenasMIN     // Cargar Decenas de Minuto
    LDS R24, unidadesHOR    // Cargar Unidades de Hora
    LDS R26, decenasHOR     // Cargar Decenas de Hora
	RET
LOADDM:
	LDS R18, unidadesDIA    // Cargar Unidades de DIA
    LDS R22, decenasDIA     // Cargar Decenas de DIA
    LDS R24, unidadesMES    // Cargar Unidades de MES
    LDS R26, decenasMES     // Cargar Decenas de MES
	RET
//invertido para el display	
LOADDMINV:
	LDS R24, unidadesDIA    // Cargar Unidades de DIA
    LDS R26, decenasDIA     // Cargar Decenas de DIA
    LDS R18, unidadesMES    // Cargar Unidades de MES
    LDS R22, decenasMES     // Cargar Decenas de MES
	RET
SAVEHM:
	STS unidadesMIN, R18    // Guardar Unidades de Minuto
    STS decenasMIN, R22     // Guardar Decenas de Minuto
    STS unidadesHOR, R24    // Guardar Unidades de Hora
    STS decenasHOR, R26     // Guardar Decenas de Hora
	RET
SAVEDM:
	STS unidadesDIA, R18    // Guardar Unidades de DIA
    STS decenasDIA, R22     // Guardar Decenas de DIA
    STS unidadesMES, R24    // Guardar Unidades de MES
    STS decenasMES, R26     // Guardar Decenas de MES
	RET

//--------------------------------------------------------------------------------------CONFIGRELOJ
//Toda la logia para la suma y resta manual del reloj

CONFIGRELOJ:
//R16 (0) MM:HH (1) DD:MM 

	CPI R16, 1
    BREQ CONFIGMESDIA
    
    CPI R16, 0
    BREQ CONFIGHORAMIN
//Configmen (0) nada (1) restar 
//Configmas (0) nada (1) sumar	

CONFIGMESDIA:
	CALL LOADDM	
	//mira si hay que sumar
	LDS R28, Configmas  
	CPI R28, 1
	BREQ SUMARDM
	//mira si hay que restar
	LDS R28, Configmen
	CPI R28, 1
	BREQ RESTADM
	//si no pasa nada regresa
	RJMP CONFIGRELOJFIN

SUMARDM:  //los modos de suma se pueden aprovechar de la funcion Tiempo asi que solo hago una suma y hago una calls
	LDS R28, Selectordisp

	CPI R28, 0 // Compara con 0
    BREQ SuniDmes
    CPI R28, 1 // Compara con 1
    BREQ SdecDmes
    CPI R28, 2 // Compara con 2
    BREQ SuniDdia 
    CPI R28, 3 // Compara con 3
    BREQ SdecDdia

SuniDmes:
	RJMP RESTADM
SdecDmes:
	RJMP RESTADM
SuniDdia:
	RJMP RESTADM
SdecDdia:

RESTADM:
	LDS R28, Selectordisp

	CPI R28, 0 // Compara con 0
    BREQ RuniDmes
    CPI R28, 1 // Compara con 1
    BREQ RdecDmes
    CPI R28, 2 // Compara con 2
    BREQ RuniDdia
    CPI R28, 3 // Compara con 3
    BREQ RdecDdia

RuniDmes:
RdecDmes:
RuniDdia:
RdecDdia:
	


	CALL SAVEDM
	RJMP CONFIGRELOJFIN
CONFIGHORAMIN:
	CALL LOADHM	

	//mira si hay que sumar
	LDS R28, Configmas  
	CPI R28, 1
	BREQ SUMARHM
	//mira si hay que restar
	LDS R28, Configmen
	CPI R28, 1
	BREQ RESTAHM
	//si no pasa nada regresa
	RJMP CONFIGRELOJFIN

SUMARHM:
	LDS R28, Selectordisp

	CPI R28, 0 // Compara con 0
    BREQ SuniDmin
    CPI R28, 1 // Compara con 1
    BREQ SdecDmin
    CPI R28, 2 // Compara con 2
    BREQ SuniDhora
    CPI R28, 3 // Compara con 3
    BREQ SdecDhora

SuniDmin:
SdecDmin:
SuniDhora:
SdecDhora:

RESTAHM:
	LDS R28, Selectordisp
	
	CPI R28, 0 // Compara con 0
    BREQ RuniDmin
    CPI R28, 1 // Compara con 1
    BREQ RdecDmin
    CPI R28, 2 // Compara con 2
    BREQ RuniDhora
    CPI R28, 3 // Compara con 3
    BREQ RdecDhora

RuniDmin:
RdecDmin:
RuniDhora:
RdecDhora:

	CALL SAVEHM
	RJMP CONFIGRELOJFIN
CONFIGRELOJFIN:

	RET


//----------------------------------------------------------------------------------------------DISPF
// toda la logica para el funcionamiento de los displays
DISPF:

	CPI R16, 1
    BREQ MESDIA
    
    CPI R16, 0
    BREQ HORAMIN

MESDIA:
	CALL LOADDMINV
	RJMP DISPSELCALC
HORAMIN:
	CALL LOADHM

DISPSELCALC:

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
	LSL R23		//mueve los bits a la iz (multiplica por 2)
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


// -----------------------------------------------------------------------------------------------------TIEMPO
// Toda la logica de la cuenta del tiempo
TIEMPO:
	
	CALL LOADHM
	
	// modos con la cuenta interrumpida
	CPI R20, 2
    BRLO Sicontar
	CLR	R17
	RJMP Nocontar
	Sicontar:

	CPI R17, 1 //segundos (118) (1 para pruebas de dia y mes)
    BRLO TIMER_RET
	CLR R17

	Nocontar:

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
	INC R27

TIMER_RET:
	//Ahora cambio para hacer lo de los dias
	CALL SAVEHM
	CALL LOADDM

	// Verificar carry (ya paso un dia?)
	CPI R27, 0
	BREQ TEMPORAL	  // Si R27 es 0, (no cambio nada en MES/DIA asi que sale)
	INC R18           // Si R27 está activo, sumar 1 a R18
	CLR R27
	// Verificar condiciones para saltar a 30dias
	CPI R24, 4        // ¿R24 es 4 (abril)?
	BREQ TREINTA_DIAS
	CPI R24, 6        // ¿R24 es 6 (junio)?
	BREQ TREINTA_DIAS
	CPI R24, 9        // ¿R24 es 9 (septiembre)?
	BREQ TREINTA_DIAS

	// Verificar si R26=1 y R24=1 (noviembre)
	CPI R26, 1        // ¿R26 es 1?
	BRNE VERIFICAR_28 // Si R26 no es 1, seguir a la siguiente verificación
	CPI R24, 1        // ¿R24 es 1?
	BREQ TREINTA_DIAS // Si ambos son 1, saltar a 30dias

	//Verificar condiciones para saltar a 28dias
	// (Como el reloj no cuenta años no voy a tomaren cuenta los años con 29 dias)
	VERIFICAR_28:
	CPI R24, 2        // ¿R24 es 2 (febrero)?
	BREQ VEINTIOCHO_DIAS
	RJMP TREINTA_Y_UN_DIAS 	//Todos los otros meses tienen 31 dias

TREINTA_DIAS: // Aquí va la lógica para meses de 30 días ----------------------------------------------
	CPI R22, 3
	BREQ TREINTA
	CPI R18, 10          // Comparar R18 (unidades de día) con 10
	BRLO TEMPORAL      
	CLR R18              
	INC R22
	RJMP TREINTAFIN
	TREINTA:
	CPI R18, 1    
	BRLO TIMER_RET2      
	CLR R18                    
	CLR R22              
	INC R24 
	RJMP MESLOG
	TREINTAFIN:              // Incrementar decenas de día en 1
	CPI R22, 4          // Comparar R18 (decenas de día) con 4
	BRLO TIMER_RET2      
	CLR R22              
	INC R24              // Incrementar unidades de mes
	RJMP MESLOG //ahora va a ver la logica de los meses
TEMPORAL:
	RJMP MESLOG
VEINTIOCHO_DIAS:	// Aquí va la lógica para febrero (28 días)----------------------------------------------------
	CPI R22, 2
	BREQ VEINTE
	CPI R18, 10          // Comparar R18 (unidades de día) con 10
	BRLO TIMER_RET2      
	CLR R18              
	INC R22              // Incrementar decenas de día en 1
	RJMP VEINTEFIN
VEINTE:
	CPI R18, 9          // Comparar R18 (unidades de día) con 9
	BRLO TIMER_RET2      
	CLR R18              
	INC R22              // Incrementar decenas de día en 1
VEINTEFIN:
	CPI R22, 3          // Comparar R18 (decenas de día) con 3
	BRLO TIMER_RET2      
	CLR R22              
	INC R24              // Incrementar unidades de mes
	RJMP MESLOG //ahora va a ver la logica de los meses
TREINTA_Y_UN_DIAS: // Aquí va la lógica para meses de 31 días -----------------------------------------------------
	CPI R22, 3
	BREQ TREINTAUNO
	CPI R18, 10          // Comparar R18 (unidades de día) con 10
	BRLO TIMER_RET2      
	CLR R18              
	INC R22              // Incrementar decenas de día en 1
	RJMP TREINTAUNOFIN
TREINTAUNO:
	CPI R18, 2          // Comparar R18 (unidades de día) con 9
	BRLO TIMER_RET2      
	CLR R18              
	CLR R22              
	INC R24 
	RJMP MESLOG
TREINTAUNOFIN:
	CPI R22, 4          // Comparar R18 (decenas de día) con 3
	BRLO TIMER_RET2      
	CLR R22              
	INC R24              // Incrementar unidades de mes
	RJMP MESLOG //ahora va a ver la logica de los meses
	MESLOG:
	CPI R26, 1
	BREQ MES10
	MESNORMAL:
	CPI R24, 10          // si alcanzan las decenas suma 1
	BRLO TIMER_RET2      
	CLR R24            
	INC R26              // Incrementar decenas de mes
	LDI R24, 1            
	CLR R22
	LDI R18, 1 

	RJMP TIMER_RET2

	MES10:

	CPI R24, 3          // si alcanza 3 reinicia
	BRLO TIMER_RET2      
	LDI R24, 1            
	CLR R26   
	CLR R22
	LDI R18, 1          


	TIMER_RET2:
	CALL SAVEDM
    RET
//--------------------------------------------------------------------------------------------------------INTERRUPCIONES

// Rutina de interrupci?n del Timer1 - Modo COMPARE MATCH
// Se encarga de contar los segundos
TIMER1_COMPA:      
    PUSH R16
    IN R16, SREG
    PUSH R16


    INC R17                 // Incrementar contador de ciclos
	SBI PINB, PINB5			// titila cada que pasa un seg

	POP R16      
	OUT SREG, R16 
	POP R16     
	RETI

// Rutina de interrupcion del PORTB
// La logica de los botones
INTBOTONES:
	PUSH R16
	IN R16, SREG
	PUSH R16	
	PUSH R17
	
	IN	R17, PINB			 // Leer estado de los botones
	STS	Botonespressint, R17 // Guardar en variable de interrupción
	//guarda el estado pasado de los botones
	LDS R16, Botonespressint
    STS Botonespresspasado, R16
	
	LDI R16, 104     // 10ms 
DELAY_10MS_LOOP1:
    LDI R17, 255     // Loop interno
DELAY_10MS_LOOP2:
    DEC R17
    BRNE DELAY_10MS_LOOP2
    DEC R16
    BRNE DELAY_10MS_LOOP1
	
	IN	R17, PINB			 // Leer estado de los botones
	STS	Botonespressint, R17 // Guardar en variable de interrupción
	LDS R16, Botonespressint
    STS Botonespresspasado2, R16

	// Comparar con el valor pasado	
	LDS R16, Botonespresspasado
	LDS R17, Botonespresspasado2

    CP R16, R17            // Comparara el estado pasado con el presente
    BRNE FINBOTONES            // Si son diferentes, salir
	
	MOV R19, R16   // se guardan los verdaderos valores del boton
	
	SBRS R19, PB0
	CALL boton_PB0
	SBRS R19, PB1
	CALL boton_PB1
	SBRS R19, PB2
	CALL boton_PB2
	SBRS R19, PB3
	CALL boton_PB3

	FINBOTONES:

	POP R17
	POP R16
	OUT SREG, R16
	POP R16
	RETI

boton_PB0://----------------------------
	
	INC R20       //Cambia de modo
    
	RET

boton_PB1: //----------------------------
	// selecciona el display
	LDS R16, Selectordisp
	INC R16
	CPI R16, 4
	BRLO SDOVER
	CLR R16
SDOVER:
	STS Selectordisp, R16
	RET

boton_PB2: //----------------------------
	
	CPI R20, 2
    BREQ ACTIVOPB2
    
    CPI R20, 3
    BREQ ACTIVOPB2

	RJMP boton_PB2fin
ACTIVOPB2:
	PUSH R20
	LDI R20, 1
	STS Configmas, R20
	POP R20
boton_PB2fin:

	RET

boton_PB3: //----------------------------
	CPI R20, 2
    BREQ ACTIVOPB3
    
    CPI R20, 3
    BREQ ACTIVOPB3

	RJMP boton_PB3fin

ACTIVOPB3:
	PUSH R21
	LDI R21, 1
	STS Configmen, R21
	POP R21

boton_PB3fin:
	RET

// Tabla para display de 7 segmentos (referencia)
disp7seg:
    .db 0b00111111 // 0
    .db 0b00000110 // 1
    .db 0b01011011 // 2
    .db 0b01010111 // 3
    .db 0b01100110 // 4
    .db 0b01110101 // 5
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