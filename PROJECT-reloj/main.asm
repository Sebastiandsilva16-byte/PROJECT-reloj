
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
	Mes:					.byte 1
	Mess:					.byte 1
	PBceroB:				.byte 1
	PBunoB:					.byte 1
	PBdosB:					.byte 1
	PBtresB:				.byte 1
	alarmaUM:				.byte 1
	alarmaDM:				.byte 1
	alarmaUH:				.byte 1
	alarmaDH:				.byte 1
	
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
	//LED ALARMA
	SBI DDRB, DDB4    // PB4 salida
    CBI PORTB, PORTB4
	// LED MODO
	SBI DDRD, DDD7    // PD7 salida
    CBI PORTD, PORTD7
	// Configuración Timer1 para 1 minuto en modo CTC ----------------------------------------------------------------------------------


	// Configurar modo CTC (WGM12=1) y prescaler 1024 (CS12=1, CS10=1) 
	LDI R16, (1 << WGM12) | (1 << CS12) | (0 << CS11) | (1 << CS10)
	STS TCCR1B, R16

	// Cargar OCR1A (para 16 MHz) 1E83 (medio sec)  (00FF) (pruebas)
	
	LDI R16, 0x1E
	STS OCR1AH, R16
	LDI R16, 0x83
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
	STS alarmaUM, R16			
	STS alarmaDM, R16		
	STS alarmaUH, R16			
	STS alarmaDH, R16				


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
    
    CPI R20, 2  // config de HM
    BREQ MODO2
    
    CPI R20, 3 // config de DM
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
	CBI PORTB, PORTB4 //TEMPORAL................................
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
	CALL CONFIGRELOJ
    RJMP FIN_COMPARAR


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
//	asigna r16 para que se muestre Alarma
	LDI R16, 2
	CBI PORTB, PORTB5	// los : no se encienden (modo alarma)
	SBI PORTD, PORTD7	// no se puede activar alarma
	CALL ALARMACONFIG
    RJMP FIN_COMPARAR

MODO5: // APAGAR ALARMA
 //	asigna r16 para que se muestre Alarma
	LDI R16, 2
	CBI PORTB, PORTB5	// los : no se encienden (modo alarma)
	SBI PORTD, PORTD7	//	indica que se puede activar alarma
	CALL ALARMACONFIGON
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
LOADAL:
	LDS R18, alarmaUM	
	LDS R22, alarmaDM
	LDS R24, alarmaUH	
	LDS R26, alarmaDH
	RET
SAVEAL:
	STS alarmaUM, R18	
	STS alarmaDM, R22	
	STS alarmaUH, R24		
	STS alarmaDH, R26
	RET


//--------------------------------------------------------------------------------------CONFIGRELOJ
//Toda la logia para la suma y resta manual del reloj

CONFIGRELOJ:
//R16 (0) MM:HH (1) DD:MM 

	CPI R16, 1
    BREQ MESESyDIA
    // si e 0 es horaymin
	CALL LOADHM	
	CALL CONFIGHORAMIN
	RET
MESESyDIA:
	CALL LOADDM	
	CALL CONFIGMESDIA
	RET
	
//------------------------------------------------------------------------------------MESESyDIS config
//Configmen (0) nada (1) restar 
//Configmas (0) nada (1) sumar
CONFIGMESDIA:
	//mira si hay que sumar
	LDS R28, Configmas  
	CPI R28, 1
	BREQ SUMARDM1
	//mira si hay que restar
	LDS R28, Configmen
	CPI R28, 1
	BREQ RESTADM1
	//si no pasa nada regresa
	RET


SUMARDM1:
	CALL LOADDM
	CALL SUMARDM
		PUSH R28
		CLR R28
		STS Configmas, R28
		POP R28
	RET
RESTADM1:
	CALL LOADDM
	CALL RESTADM
		PUSH R28
		CLR R28
		STS Configmas, R28
		POP R28
	RET
//--------------------------------SUMA DIAMES
SUMARDM:
	LDS R28, Selectordisp

	CPI R28, 0 // Compara con 0
    BREQ SuniDmes0
    CPI R28, 1 // Compara con 1
    BREQ SdecDmes0
    CPI R28, 2 // Compara con 2
    BREQ SuniDdia0 
    CPI R28, 3 // Compara con 3
    BREQ SdecDdia0

SuniDmes0:
	CALL SuniDmes
	RET
SdecDmes0:
	CALL SdecDmes
	RET
SuniDdia0:
	CALL SuniDdia
	RET
SdecDdia0:
	CALL SdecDdia
	RET

// Mess (0) 0-9 (1) 10-12
// Mes-->  (0) 31 dias (1) 30 dias (2) 28 dias
SuniDmes:
		CALL MESLOG
		INC R24
	   
		LDS R28, Mess
		CPI R28, 0  
		BREQ MESNORMAL9
    
		CPI R28, 1
		BREQ MES109
		
		MESNORMAL9:
		CPI R24, 10          // si alcanzan las decenas suma 1
		BRLO TIMER_RET29      
		CLR R24            
		INC R26              // Incrementar decenas de mes      
		CLR R22
		LDI R18, 1 
		RJMP TIMER_RET29

		MES109:
		CPI R24, 3          // si alcanza 3 reinicia
		BRLO TIMER_RET29      
		LDI R24, 1            
		CLR R26   
		CLR R22
		LDI R18, 1    	 
	TIMER_RET29:
		CALL cerocero      // arreglotemp
		CALL SAVEDM
		RET
SdecDmes:
		INC R26
		CPI R26, 1
		BREQ TIMER_RET210
		CLR R26
		CALL SAVEDM
		RET
		TIMER_RET210:
		CPI R24, 0
		BREQ TTIMER_RET21
		CPI R24, 1
		BREQ TTIMER_RET21
		CPI R24, 2
		BREQ TTIMER_RET21
		CLR R26
		LDI R24, 1
		TTIMER_RET21:
		CALL SAVEDM
		RET


		CALL SAVEDM
		RET
SuniDdia:
		INC R18           
		CALL LOGDIAS			//para ver como se debe efectuar la suma de dias

		LDS R28, Mes
		CPI R28, 0  
		BREQ TREINTA_Y_UN_DIAS7
    
		CPI R28, 1
		BREQ TREINTA_DIAS7
    
		CPI R28, 2  
		BREQ VEINTIOCHO_DIAS7


	TREINTA_DIAS7: // Aquí va la lógica para meses de 30 días ----------------------------------------------
		CPI R22, 3
		BREQ TREINTA7
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TEMPORAL7     
		CLR R18              
		INC R22
		RJMP TREINTAFIN7
		TREINTA7:
		CPI R18, 1    
		BRLO TEMPORAL7
		CLR R18                    
		CLR R22              
		INC R24 
		RJMP MESLOG7
		TREINTAFIN7:              // Incrementar decenas de día en 1
		CPI R22, 5          // Comparar R18 (decenas de día) con 4
		BRLO TIMER_RET27  
		CLR R22  
		LDI R18, 1                 
		INC R24              // Incrementar unidades de mes
		 //ahora va a ver la logica de los meses
	TEMPORAL7:
		RJMP MESLOG7
	VEINTIOCHO_DIAS7:	// Aquí va la lógica para febrero (28 días)----------------------------------------------------
		CPI R22, 2
		BREQ VEINTE7
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET27      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP VEINTEFIN7
	VEINTE7:
		CPI R18, 9          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET27      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
	VEINTEFIN7:
		CPI R22, 3          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET27 
		LDI R18, 1      
		CLR R22              
		INC R24              // Incrementar unidades de mes
		RJMP MESLOG7 //ahora va a ver la logica de los meses
	TREINTA_Y_UN_DIAS7: // Aquí va la lógica para meses de 31 días -----------------------------------------------------
		CPI R22, 3
		BREQ TREINTAUNO7
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET27      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP TREINTAUNOFIN7
	TREINTAUNO7:
		CPI R18, 2          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET27      
		CLR R18              
		CLR R22              
		INC R24 
		RJMP MESLOG7
	TREINTAUNOFIN7:
		CPI R22, 4          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET27     
		CLR R22    
		LDI R18, 1           
		INC R24              // Incrementar unidades de mes 
	MESLOG7: //ahora va a ver la logica de los meses
		CALL MESLOG
	   
		LDS R28, Mess
		CPI R28, 0  
		BREQ MESNORMAL7
    
		CPI R28, 1
		BREQ MES107
		
		MESNORMAL7:
		CPI R24, 10          // si alcanzan las decenas suma 1
		BRLO TIMER_RET27      
		CLR R24            
		INC R26              // Incrementar decenas de mes      
		CLR R22
		LDI R18, 1 
		RJMP TIMER_RET27

		MES107:
		CPI R24, 3          // si alcanza 3 reinicia
		BRLO TIMER_RET27      
		LDI R24, 1            
		CLR R26   
		CLR R22
		LDI R18, 1    	 
	TIMER_RET27:
		CALL cerocero      // arreglotemp
		CALL SAVEDM
		RET

SdecDdia:
		CALL LOGDIAS			//para ver como se debe efectuar la suma de dias

		LDS R28, Mes
		CPI R28, 0  
		BREQ TREINTA_Y_UN_DIAS8
    
		CPI R28, 1
		BREQ TREINTA_DIAS8
    
		CPI R28, 2  
		BREQ VEINTIOCHO_DIAS8


	TREINTA_DIAS8: // Aquí va la lógica para meses de 30 días ----------------------------------------------
		INC R22
		CPI R22, 4
		BREQ TREINTA8
		CPI R22, 3
		BREQ TTREINTA8
		RJMP MESLOG8
		
		TTREINTA8:
		CPI R18, 0
		BREQ MESLOG8
		TREINTA8: 
		INC R24  
		LDI R18, 1              
		CLR R22          
		RJMP MESLOG8

	VEINTIOCHO_DIAS8:	// Aquí va la lógica para febrero (28 días)----------------------------------------------------}
		INC R22
		CPI R22, 3
		BREQ VEINTE8
		RJMP MESLOG8  
	VEINTE8:
		LDI R18, 1    
		CLR R22           
		INC R24           
		RJMP MESLOG8 
		  
	TREINTA_Y_UN_DIAS8: // Aquí va la lógica para meses de 31 días -----------------------------------------------------
		INC R22
		CPI R22, 3
		BREQ TREINTAUNO8
		CPI R22, 4
		BREQ TTTREINTAUNO8
		RJMP MESLOG8
	TREINTAUNO8:   
		CPI R18, 0	
		BREQ MESLOG8
		CPI R18, 1	
		BREQ MESLOG8
	TTTREINTAUNO8:	
		INC R24  
		LDI R18, 1              
		CLR R22          
		RJMP MESLOG8

	MESLOG8: //ahora va a ver la logica de los meses
		CALL MESLOG
	   
		LDS R28, Mess
		CPI R28, 0  
		BREQ MESNORMAL8
    
		CPI R28, 1
		BREQ MES108
		
		MESNORMAL8:
		CPI R24, 10          // si alcanzan las decenas suma 1
		BRLO TIMER_RET28      
		CLR R24            
		INC R26              // Incrementar decenas de mes      
		CLR R22
		LDI R18, 1 
		RJMP TIMER_RET28

		MES108:
		CPI R24, 3          // si alcanza 3 reinicia
		BRLO TIMER_RET28      
		LDI R24, 1            
		CLR R26   
		CLR R22
		LDI R18, 1    	 
	TIMER_RET28:
		CALL cerocero      // arreglotemp
		CALL SAVEDM
		RET	
//---------------------------------RESTA DIAMES
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
	RET
RdecDmes:
	RET
RuniDdia:
	RET
RdecDdia:
	RET
	



//------------------------------------------------------------------------------------HORAyDIAS config
//Configmen (0) nada (1) restar 
//Configmas (0) nada (1) sumar
CONFIGHORAMIN:

	//mira si hay que sumar
	LDS R28, Configmas  
	CPI R28, 1
	BREQ SUMARHM1
	//mira si hay que restar
	LDS R28, Configmen
	CPI R28, 1
	BREQ RESTAHM1
	//si no pasa nada regresa
	RET

SUMARHM1:
	CALL SUMARHM
		PUSH R28
		CLR R28
		STS Configmas, R28
		POP R28

	RET
RESTAHM1:
	CALL RESTAHM
		PUSH R28
		CLR R28
		STS Configmen, R28
		POP R28
	RET
//-----------------SUMA HORAMIN
SUMARHM:
	LDS R28, Selectordisp

	CPI R28, 0 // Compara con 0
    BREQ SuniDmin0
    CPI R28, 1 // Compara con 1
    BREQ SdecDmin0
    CPI R28, 2 // Compara con 2
    BREQ SuniDhora0
    CPI R28, 3 // Compara con 3
    BREQ SdecDhora0

SuniDmin0:
	CALL SuniDmin
	RET
SdecDmin0:
	CALL SdecDmin
	RET
SuniDhora0:
	CALL SuniDhora
	RET
SdecDhora0:
	CALL SdecDhora
	RET

SuniDmin:
		INC R18
		CPI R18, 10
		BRLO TIMER_RET3
		CLR R18

		INC R22			//Decenas de Minutos
		CPI R22, 6
		BRLO TIMER_RET3
		CLR R22

		INC R24			//Unidades de Horas
		CPI R26, 2	
		BRNE ZEROoDIEZ3 // revisa que no ha llegado a 20
		CPI R24, 4
		BRLO TIMER_RET3
		CLR R24
		RJMP DECENASdeHORAS3
	ZEROoDIEZ3:
		CPI R24, 10
		BRLO TIMER_RET3
		CLR R24

	DECENASdeHORAS3:
		INC R26			//Decenas de Horas
		CPI R26, 3
		BRLO TIMER_RET3
		CLR R26
		INC R27

	TIMER_RET3:
		//Ahora cambio para hacer lo de los dias
		CALL SAVEHM
		CALL LOADDM
	DIA3:
		// Verificar carry (ya paso un dia?)
		CPI R27, 0
		BREQ TEMPORAL3	  // Si R27 es 0, (no cambio nada en MES/DIA asi que sale)
		INC R18           // Si R27 está activo, sumar 1 a R18
		CLR R27

		CALL LOGDIAS			//para ver como se debe efectuar la suma de dias

		LDS R28, Mes
		CPI R28, 0  
		BREQ TREINTA_Y_UN_DIAS3
    
		CPI R28, 1
		BREQ TREINTA_DIAS3
    
		CPI R28, 2  
		BREQ VEINTIOCHO_DIAS3


	TREINTA_DIAS3: // Aquí va la lógica para meses de 30 días ----------------------------------------------
		CPI R22, 3
		BREQ TREINTA3
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TEMPORAL3     
		CLR R18              
		INC R22
		RJMP TREINTAFIN3
		TREINTA3:
		CPI R18, 1    
		BRLO TEMPORAL3     
		CLR R18                    
		CLR R22              
		INC R24 
		RJMP MESLOG3
		TREINTAFIN3:              // Incrementar decenas de día en 1
		CPI R22, 4          // Comparar R18 (decenas de día) con 4
		BRLO TIMER_RET23   
		LDI R18, 1    
		CLR R22              
		INC R24              // Incrementar unidades de mes
		 //ahora va a ver la logica de los meses
	TEMPORAL3:
		RJMP MESLOG3
	VEINTIOCHO_DIAS3:	// Aquí va la lógica para febrero (28 días)----------------------------------------------------
		CPI R22, 2
		BREQ VEINTE3
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET23      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP VEINTEFIN3
	VEINTE3:
		CPI R18, 9          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET23      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
	VEINTEFIN3:
		CPI R22, 3          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET23      
		LDI R18, 1 
		CLR R22              
		INC R24              // Incrementar unidades de mes
		RJMP MESLOG3 //ahora va a ver la logica de los meses
	TREINTA_Y_UN_DIAS3: // Aquí va la lógica para meses de 31 días -----------------------------------------------------
		CPI R22, 3
		BREQ TREINTAUNO3
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET23      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP TREINTAUNOFIN3
	TREINTAUNO3:
		CPI R18, 2          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET23      
		CLR R18              
		CLR R22              
		INC R24 
		RJMP MESLOG3
	TREINTAUNOFIN3:
		CPI R22, 4          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET23  
		LDI R18, 1     
		CLR R22              
		INC R24              // Incrementar unidades de mes 
	MESLOG3: //ahora va a ver la logica de los meses
		CALL MESLOG
	   
		LDS R28, Mess
		CPI R28, 0  
		BREQ MESNORMAL3
    
		CPI R28, 1
		BREQ MES103
		
		MESNORMAL3:
		CPI R24, 10          // si alcanzan las decenas suma 1
		BRLO TIMER_RET23      
		CLR R24            
		INC R26              // Incrementar decenas de mes      
		CLR R22
		LDI R18, 1 
		RJMP TIMER_RET23

		MES103:
		CPI R24, 3          // si alcanza 3 reinicia
		BRLO TIMER_RET23      
		LDI R24, 1            
		CLR R26   
		CLR R22
		LDI R18, 1    	 
	TIMER_RET23:
		CALL cerocero      // arreglotemp
		CALL SAVEDM
		RET

SdecDmin:
		INC R22			//Decenas de Minutos
		CPI R22, 6
		BRLO TIMER_RET4
		CLR R22

		INC R24			//Unidades de Horas
		CPI R26, 2	
		BRNE ZEROoDIEZ4 // revisa que no ha llegado a 20
		CPI R24, 4
		BRLO TIMER_RET4
		CLR R24
		RJMP DECENASdeHORAS4
	ZEROoDIEZ4:
		CPI R24, 10
		BRLO TIMER_RET4
		CLR R24

	DECENASdeHORAS4:
		INC R26			//Decenas de Horas
		CPI R26, 3
		BRLO TIMER_RET4
		CLR R26
		INC R27

	TIMER_RET4:
		//Ahora cambio para hacer lo de los dias
		CALL SAVEHM
		CALL LOADDM
	DIA4:
		// Verificar carry (ya paso un dia?)
		CPI R27, 0
		BREQ TEMPORAL4	  // Si R27 es 0, (no cambio nada en MES/DIA asi que sale)
		INC R18           // Si R27 está activo, sumar 1 a R18
		CLR R27

		CALL LOGDIAS			//para ver como se debe efectuar la suma de dias

		LDS R28, Mes
		CPI R28, 0  
		BREQ TREINTA_Y_UN_DIAS4
    
		CPI R28, 1
		BREQ TREINTA_DIAS4
    
		CPI R28, 2  
		BREQ VEINTIOCHO_DIAS4


	TREINTA_DIAS4: // Aquí va la lógica para meses de 30 días ----------------------------------------------
		CPI R22, 3
		BREQ TREINTA4
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TEMPORAL4     
		CLR R18              
		INC R22
		RJMP TREINTAFIN4
		TREINTA4:
		CPI R18, 1    
		BRLO TEMPORAL4 
		CLR R18                    
		CLR R22              
		INC R24 
		RJMP MESLOG4
		TREINTAFIN4:              // Incrementar decenas de día en 1
		CPI R22, 4          // Comparar R18 (decenas de día) con 4
		BRLO TIMER_RET24   
		LDI R18, 1    
		CLR R22              
		INC R24              // Incrementar unidades de mes
		 //ahora va a ver la logica de los meses
	TEMPORAL4:
		RJMP MESLOG4
	VEINTIOCHO_DIAS4:	// Aquí va la lógica para febrero (28 días)----------------------------------------------------
		CPI R22, 2
		BREQ VEINTE4
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET24      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP VEINTEFIN4
	VEINTE4:
		CPI R18, 9          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET24      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
	VEINTEFIN4:
		CPI R22, 3          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET24 
		LDI R18, 1      
		CLR R22              
		INC R24              // Incrementar unidades de mes
		RJMP MESLOG4 //ahora va a ver la logica de los meses
	TREINTA_Y_UN_DIAS4: // Aquí va la lógica para meses de 31 días -----------------------------------------------------
		CPI R22, 3
		BREQ TREINTAUNO4
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET24      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP TREINTAUNOFIN4
	TREINTAUNO4:
		CPI R18, 2          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET24      
		CLR R18              
		CLR R22              
		INC R24 
		RJMP MESLOG4
	TREINTAUNOFIN4:
		CPI R22, 4          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET24     
		LDI R18, 1  
		CLR R22              
		INC R24              // Incrementar unidades de mes 
	MESLOG4: //ahora va a ver la logica de los meses
		CALL MESLOG
	   
		LDS R28, Mess
		CPI R28, 0  
		BREQ MESNORMAL4
    
		CPI R28, 1
		BREQ MES104
		
		MESNORMAL4:
		CPI R24, 10          // si alcanzan las decenas suma 1
		BRLO TIMER_RET24      
		CLR R24            
		INC R26              // Incrementar decenas de mes      
		CLR R22
		LDI R18, 1 
		RJMP TIMER_RET24

		MES104:
		CPI R24, 3          // si alcanza 3 reinicia
		BRLO TIMER_RET24      
		LDI R24, 1            
		CLR R26   
		CLR R22
		LDI R18, 1    	 
	TIMER_RET24:
		CALL cerocero
		CALL SAVEDM
		RET	
SuniDhora:
		INC R24			//Unidades de Horas
		CPI R26, 2	
		BRNE ZEROoDIEZ5 // revisa que no ha llegado a 20
		CPI R24, 4
		BRLO TIMER_RET5
		CLR R24
		RJMP DECENASdeHORAS5
	ZEROoDIEZ5:
		CPI R24, 10
		BRLO TIMER_RET5
		CLR R24

	DECENASdeHORAS5:
		INC R26			//Decenas de Horas
		CPI R26, 3
		BRLO TIMER_RET5
		CLR R26
		INC R27

	TIMER_RET5:
		//Ahora cambio para hacer lo de los dias
		CALL SAVEHM
		CALL LOADDM
	DIA5:
		// Verificar carry (ya paso un dia?)
		CPI R27, 0
		BREQ TEMPORAL5	  // Si R27 es 0, (no cambio nada en MES/DIA asi que sale)
		INC R18           // Si R27 está activo, sumar 1 a R18
		CLR R27

		CALL LOGDIAS			//para ver como se debe efectuar la suma de dias

		LDS R28, Mes
		CPI R28, 0  
		BREQ TREINTA_Y_UN_DIAS5
    
		CPI R28, 1
		BREQ TREINTA_DIAS5
    
		CPI R28, 2  
		BREQ VEINTIOCHO_DIAS5


	TREINTA_DIAS5: // Aquí va la lógica para meses de 30 días ----------------------------------------------
		CPI R22, 3
		BREQ TREINTA5
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TEMPORAL5     
		CLR R18              
		INC R22
		RJMP TREINTAFIN5
		TREINTA5:
		CPI R18, 1    
		BRLO TEMPORAL5
		CLR R18                    
		CLR R22              
		INC R24 
		RJMP MESLOG5
		TREINTAFIN5:              // Incrementar decenas de día en 1
		CPI R22, 5          // Comparar R18 (decenas de día) con 4
		BRLO TIMER_RET25
		LDI R18, 1       
		CLR R22              
		INC R24              // Incrementar unidades de mes
		 //ahora va a ver la logica de los meses
	TEMPORAL5:
		RJMP MESLOG5
	VEINTIOCHO_DIAS5:	// Aquí va la lógica para febrero (28 días)----------------------------------------------------
		CPI R22, 2
		BREQ VEINTE5
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET25      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP VEINTEFIN5
	VEINTE5:
		CPI R18, 9          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET25      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
	VEINTEFIN5:
		CPI R22, 3          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET25     
		LDI R18, 1  
		CLR R22              
		INC R24              // Incrementar unidades de mes
		RJMP MESLOG5 //ahora va a ver la logica de los meses
	TREINTA_Y_UN_DIAS5: // Aquí va la lógica para meses de 31 días -----------------------------------------------------
		CPI R22, 3
		BREQ TREINTAUNO5
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET25      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP TREINTAUNOFIN5
	TREINTAUNO5:
		CPI R18, 2          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET25      
		CLR R18              
		CLR R22              
		INC R24 
		RJMP MESLOG5
	TREINTAUNOFIN5:
		CPI R22, 4          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET25 
		LDI R18, 1      
		CLR R22              
		INC R24              // Incrementar unidades de mes 
	MESLOG5: //ahora va a ver la logica de los meses
		CALL MESLOG
	   
		LDS R28, Mess
		CPI R28, 0  
		BREQ MESNORMAL5
    
		CPI R28, 1
		BREQ MES105
		
		MESNORMAL5:
		CPI R24, 10          // si alcanzan las decenas suma 1
		BRLO TIMER_RET25      
		CLR R24            
		INC R26              // Incrementar decenas de mes      
		CLR R22
		LDI R18, 1 
		RJMP TIMER_RET25

		MES105:
		CPI R24, 3          // si alcanza 3 reinicia
		BRLO TIMER_RET25      
		LDI R24, 1            
		CLR R26   
		CLR R22
		LDI R18, 1    	 
	TIMER_RET25:
		CALL cerocero
		CALL SAVEDM
		RET
SdecDhora:
		INC R26			//Decenas de Horas
		CPI R26, 2
		BREQ CHEKOVERFLOWuniH
		CPI R26, 3
		BRLO TIMER_RET6
		CLR R26
		INC R27
		RJMP TIMER_RET6
	CHEKOVERFLOWuniH:
		CPI R24, 4
		BRLO TIMER_RET6
		CLR R24
	TIMER_RET6:
		//Ahora cambio para hacer lo de los dias
		CALL SAVEHM
		CALL LOADDM
	DIA6:
		// Verificar carry (ya paso un dia?)
		CPI R27, 0
		BREQ TEMPORAL6	  // Si R27 es 0, (no cambio nada en MES/DIA asi que sale)
		INC R18           // Si R27 está activo, sumar 1 a R18
		CLR R27

		CALL LOGDIAS			//para ver como se debe efectuar la suma de dias

		LDS R28, Mes
		CPI R28, 0  
		BREQ TREINTA_Y_UN_DIAS6
    
		CPI R28, 1
		BREQ TREINTA_DIAS6
    
		CPI R28, 2  
		BREQ VEINTIOCHO_DIAS6


	TREINTA_DIAS6: // Aquí va la lógica para meses de 30 días ----------------------------------------------
		CPI R22, 3
		BREQ TREINTA6
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TEMPORAL6     
		CLR R18              
		INC R22
		RJMP TREINTAFIN6
		TREINTA6:
		CPI R18, 1    
		BRLO TEMPORAL6
		CLR R18                    
		CLR R22              
		INC R24 
		RJMP MESLOG6
		TREINTAFIN6:              // Incrementar decenas de día en 1
		CPI R22, 5          // Comparar R18 (decenas de día) con 4
		BRLO TIMER_RET26   
		LDI R18, 1    
		CLR R22              
		INC R24              // Incrementar unidades de mes
		 //ahora va a ver la logica de los meses
	TEMPORAL6:
		RJMP MESLOG6
	VEINTIOCHO_DIAS6:	// Aquí va la lógica para febrero (28 días)----------------------------------------------------
		CPI R22, 2
		BREQ VEINTE6
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET26      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP VEINTEFIN6
	VEINTE6:
		CPI R18, 9          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET26      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
	VEINTEFIN6:
		CPI R22, 3          // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET26  
		LDI R18, 1     
		CLR R22              
		INC R24              // Incrementar unidades de mes
		RJMP MESLOG6 //ahora va a ver la logica de los meses
	TREINTA_Y_UN_DIAS6: // Aquí va la lógica para meses de 31 días -----------------------------------------------------
		CPI R22, 3
		BREQ TREINTAUNO6
		CPI R18, 10          // Comparar R18 (unidades de día) con 10
		BRLO TIMER_RET26      
		CLR R18              
		INC R22              // Incrementar decenas de día en 1
		RJMP TREINTAUNOFIN6
	TREINTAUNO6:
		CPI R18, 2          // Comparar R18 (unidades de día) con 9
		BRLO TIMER_RET26      
		CLR R18              
		CLR R22              
		INC R24 
		RJMP MESLOG6
	TREINTAUNOFIN6:
		CPI R22, 4    
		LDI R18, 1       // Comparar R18 (decenas de día) con 3
		BRLO TIMER_RET26      
		CLR R22              
		INC R24              // Incrementar unidades de mes 
	MESLOG6: //ahora va a ver la logica de los meses
		CALL MESLOG
	   
		LDS R28, Mess
		CPI R28, 0  
		BREQ MESNORMAL6
    
		CPI R28, 1
		BREQ MES106
		
		MESNORMAL6:
		CPI R24, 10          // si alcanzan las decenas suma 1
		BRLO TIMER_RET26      
		CLR R24            
		INC R26              // Incrementar decenas de mes      
		CLR R22
		LDI R18, 1 
		RJMP TIMER_RET26

		MES106:
		CPI R24, 3          // si alcanza 3 reinicia
		BRLO TIMER_RET26      
		LDI R24, 1            
		CLR R26   
		CLR R22
		LDI R18, 1    	 
	TIMER_RET26:
		CALL cerocero
		CALL SAVEDM
		RET
//-----------------RESTA HORAMIN
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
	RET
RdecDmin:
	RET
RuniDhora:
	RET
RdecDhora:
	RET

//----------------------------------------------------------------------------------------------DISPF
// toda la logica para el funcionamiento de los displays
DISPF:

	CPI R16, 2
    BREQ ALARMA

	CPI R16, 1
    BREQ MESDIA
    
    CPI R16, 0
    BREQ HORAMIN



ALARMA:
	CALL LOADAL
	RJMP DISPSELCALC
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

	CPI R17, 118 //segundos (118) (1 para pruebas de dia y mes)
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
DIA:
	// Verificar carry (ya paso un dia?)
	CPI R27, 0
	BREQ TEMPORAL	  // Si R27 es 0, (no cambio nada en MES/DIA asi que sale)
	INC R18           // Si R27 está activo, sumar 1 a R18
	CLR R27

	CALL LOGDIAS			//para ver como se debe efectuar la suma de dias

	LDS R28, Mes
	CPI R28, 0  
    BREQ TREINTA_Y_UN_DIAS
    
    CPI R28, 1
    BREQ TREINTA_DIAS
    
    CPI R28, 2  
    BREQ VEINTIOCHO_DIAS


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
	BRLO TEMPORAL     
	CLR R18                    
	CLR R22              
	INC R24 
	RJMP MESLOG
	TREINTAFIN:              // Incrementar decenas de día en 1
	CPI R22, 4          // Comparar R18 (decenas de día) con 4
	BRLO TIMER_RET2     
	LDI R18, 1  
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
	LDI R18, 1     
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
	LDI R18, 1    
	CLR R22              
	INC R24              // Incrementar unidades de mes 
MESLOG: //ahora va a ver la logica de los meses
	CALL MESLOG2
	   
	LDS R28, Mess
	CPI R28, 0  
    BREQ MESNORMAL
    
    CPI R28, 1
    BREQ MES10
		
	MESNORMAL:
	CPI R24, 10          // si alcanzan las decenas suma 1
	BRLO TIMER_RET2      
	CLR R24            
	INC R26              // Incrementar decenas de mes      
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
	CALL cerocero
	CALL SAVEDM
    RET

//--------------------------------------------------------------------------------------------------------LOGICA DE DIAS
// Mes-->  (0) 31 dias (1) 30 dias (2) 28 dias
LOGDIAS:
	// Verificar condiciones para saltar a 30dias
	CPI R24, 4        // ¿R24 es 4 (abril)?
	BREQ MESUNO
	CPI R24, 6        // ¿R24 es 6 (junio)?
	BREQ MESUNO
	CPI R24, 9        // ¿R24 es 9 (septiembre)?
	BREQ MESUNO

	// Verificar si R26=1 y R24=1 (noviembre)
	CPI R26, 1        // ¿R26 es 1?
	BRNE VERIFICAR_28 // Si R26 no es 1, seguir a la siguiente verificación
	CPI R24, 1        // ¿R24 es 1?
	BREQ MESUNO // Si ambos son 1, saltar a 30dias
	CPI R24, 2       // ¿R24 es 1?
	BREQ MESZERO

	//Verificar condiciones para saltar a 28dias
	// (Como el reloj no cuenta años no voy a tomaren cuenta los años con 29 dias)
	VERIFICAR_28:
	CPI R24, 2        // ¿R24 es 2 (febrero)?
	BREQ MESDOS


	MESZERO:
		CLR R28
		STS	Mes, R28
		RJMP LOGMESFIN
	MESUNO:
		LDI R28, 1
		STS	Mes, R28
		RJMP LOGMESFIN
	MESDOS:
		LDI R28, 2
		STS	Mes, R28
	LOGMESFIN:
		RET
//---------------------------------------------------------------otra variable  para la logica de los meses
// Mess (0) 0-9 (1) 10-12
MESLOG2:
	CPI R26, 1
	BRLO MESS0
MESS1:
	LDI R28, 1
	STS	Mess, R28
	RJMP MESSLOG2FIN
MESS0:
	CLR R28
	STS	Mess, R28

MESSLOG2FIN: 
	RET

//------correcion en la cuenta de dias
CEROCERO:
	CPI R22, 0          // Compara R22 con 0
	BRNE no_cero        
	CPI R18, 0       //  R18 con 0   
	BRNE no_cero        
	// Si llegamos aquí, AMBOS son 0
	LDI R18, 1          // Cargar 1 en R18
	no_cero:
	RET

//--------------------------------------------------------------------------------------------------------ALARMA
ALARMACONFIG:
	LDS R28, Configmas  
	CPI R28, 0
	BREQ ALARMACONFIGFIN
	CALL LOADAL

	LDS R28, Selectordisp
	
	CPI R28, 0 // Compara con 0
    BREQ SuniDmin1
    CPI R28, 1 // Compara con 1
    BREQ SdecDmin1
    CPI R28, 2 // Compara con 2
    BREQ SuniDhora1
    CPI R28, 3 // Compara con 3
    BREQ SdecDhora1

		PUSH R28
		CLR R28
		STS Configmas, R28
		POP R28
	RET
ALARMACONFIGFIN:
	RET

SuniDmin1:
	CALL AlarmUM
	RET
SdecDmin1:
	CALL AlarmDM
	RET
SuniDhora1:
	CALL AlarmUH
	RET
SdecDhora1:
	CALL AlarmDH
	RET

AlarmUM:
		INC R18
		CPI R18, 10
		BRLO AlarmUMFIN
		CLR R18
	AlarmUMFIN:
		CALL SAVEAL
		RET
AlarmDM:
		LDI R22, 1
		CALL SAVEAL
		RET
AlarmUH:
		LDI R24, 1
		CALL SAVEAL
		RET
AlarmDH:
		LDI R26, 1
		CALL SAVEAL
		RET	

ALARMACONFIGON:
	RET


//--------------------------------------------------------------------------------------------------------INTERRUPCIONES

// Rutina de interrupci?n del Timer1 - Modo COMPARE MATCH
// Se encarga de contar los segundos
TIMER1_COMPA:      
    PUSH R18
    IN R18, SREG
    PUSH R18

    INC R17                 // Incrementar contador de ciclos
	SBI PINB, PINB5			// titila cada que pasa un seg

	POP R18      
	OUT SREG, R18 
	POP R18     
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
	
// Guardar bit PB0
BST R19, 0          // Store bit from register T flag (PB0)
BLD R28, 0          // Load bit from T flag to R28 bit 0
STS PBceroB, R28    // Store R28 en variable PBceroB

// Guardar bit PB1
BST R19, 1          // Store bit from register T flag (PB1)
BLD R28, 0          // Load bit from T flag to R28 bit 0
STS PBunoB, R28     // Store R28 en variable PBunoB

// Guardar bit PB2
BST R19, 2          // Store bit from register T flag (PB2)
BLD R28, 0          // Load bit from T flag to R28 bit 0
STS PBdosB, R28     // Store R28 en variable PBdosB

// Guardar bit PB3
BST R19, 3          // Store bit from register T flag (PB3)
BLD R28, 0          // Load bit from T flag to R28 bit 0
STS PBtresB, R28    // Store R28 en variable PBtresB

// Cargar las variables en R28 y evaluar con SBRC
LDS R28, PBceroB    // Cargar PBceroB en R28
SBRS R28, 0         // Skip if bit 0 of R28 is clear (si es 0 salta, si es 1 ejecuta)
CALL boton_PB0

LDS R28, PBunoB     // Cargar PBunoB en R28
SBRS R28, 0         // Skip if bit 0 of R28 is clear (si es 0 salta, si es 1 ejecuta)
CALL boton_PB1

LDS R28, PBdosB     // Cargar PBdosB en R28
SBRS R28, 0         // Skip if bit 0 of R28 is clear (si es 0 salta, si es 1 ejecuta)
CALL boton_PB2

LDS R28, PBtresB    // Cargar PBtresB en R28
SBRS R28, 0         // Skip if bit 0 of R28 is clear (si es 0 salta, si es 1 ejecuta)
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

	CPI R20, 4
    BREQ ACTIVOPB2

	RJMP boton_PB2fin
ACTIVOPB2:
	PUSH R28
	LDI R28, 1
	STS Configmas, R28
	POP R28
boton_PB2fin:

	RET

boton_PB3: //----------------------------
	CPI R20, 2
    BREQ ACTIVOPB3
    
    CPI R20, 3
    BREQ ACTIVOPB3

	CPI R20, 4
    BREQ ACTIVOPB3

	RJMP boton_PB3fin

ACTIVOPB3:
	PUSH R28
	LDI R28, 1
	STS Configmen, R28
	POP R28

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