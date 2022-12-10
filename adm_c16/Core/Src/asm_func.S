.syntax unified
.thumb
.text

@ Simbolos exportados
.global asm_svc
.global asm_sum
.global asm_zeros			@ Esta es la nueva función (26/11) que asigna ceros a un vector
.global asm_productoEscalar32
.global asm_productoEscalar16
.global asm_productoEscalar12
.global asm_filtroVentana10
.global asm_pack32to16
.global asm_max
.global asm_downsampleM
.global asm_invertir
.global asm_corr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   void asm_svc (void)
@
.thumb_func
    asm_svc:
        svc 0
        bx lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   uint32_t asmSum (uint32_t firstOperand, uint32_t secondOperand)
@
@ Parametros recibidos:
@   r0: firstOperand
@   r1: secondOperand
@
@ Valor de retorno:
@   r0: resultado de la suma de firstOperand y secondOperand
@
.thumb_func
    asm_sum:
        add r0, r1  @ r0 = r0 + r1
        bx lr       @ vuelve adonde fue llamada (especificamente, si "pc"
                    @ es la direccion, en el codigo del programa, de la
                    @ instruccion "bl asm_sum" usada para saltar a
                    @ esta funcion, entonces "lr" contiene ese "pc" + 4).
                    @ el valor de retorno debe quedar en el registro r0.
                    @ En este caso, r0 es el resultado de r0 + r1.

        @ Otras alternativas para el retorno
        @ mov pc,lr
        @ bx lr
        @ push {lr} ... pop {pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   void asm_zeros (uint32_t * vector, uint32_t longitud)
@
@ Parametros recibidos:
@   r0: dirección de memoria de inicio del vector
@   r1: longitud
.thumb_func               	@ Se avisa al emsablador que esta es una funcion
    asm_zeros:            	@ Etiqueta/nombre de la función.
    	mov r2, 0         	@ r2 = 0
    	asm_zeros_bucle:  	@ Etiqueta de comienzo de bucle.
    		str r2, [r0]	@ Asigna 0 a la palabra en dirección r0.
    		add r0, 4       @ Pasa a la siguiente palabra/elemento en vector.
    		subs r1, 1      @ Resta 1 a la cantidad de elementos y actualiza flags de estado del procesador. En particular, estamos interesados en el flag Z.
    	bne asm_zeros_bucle	@ La instrucción se ejecuta mientras el resultado de r1 - 1 no sea cero (Z == 0).
    	bx LR               @ La instrucción de salto no se ejecutó porque Z == 1, volvemos a quién nos llamó.


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   asm_productoEscalar32(uint32_t * vectorIn, uint32_t * vectorOut, uint32_t longitud, uint32_t escalar);
@
@ Parametros recibidos:
@   r0: dirección de memoria de inicio del vector de entrada
@   r1: dirección de memoria de inicio del vector de salida
@	r2: longitud
@	r3: escalar a multiplicar
.thumb_func               		@ Se avisa al emsablador que esta es una funcion
      asm_productoEscalar32:    @ Etiqueta/nombre de la función.
        push {R4}				@ Guardo el registro en pila para recuperarlo luego
        asm_pe32_loop:
        	ldr	R4, [R0], #4	@ Carga el valor de memoria en [R0] en el registro R4, e incrementa R0 en 4 (porque tiene 4 bytes)
			mul R4, R3			@ Multiplica R3xR4 y lo guarda en R4
			str R4, [R1], #4	@ Ahora guardo el valor
			subs R2, 1			@ Decremento el lardo del vector...
			bne asm_pe32_loop	@ A menos que R2 sea cero, vuelvo a asm_loop
		pop {R4}
		bx LR					@ Retornamos


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   asm_productoEscalar16(uint16_t * vectorIn, uint16_t * vectorOut, uint32_t longitud, uint16_t escalar);
@
@ Parametros recibidos:
@   r0: dirección de memoria de inicio del vector de entrada
@   r1: dirección de memoria de inicio del vector de salida
@	r2: longitud
@	r3: escalar a multiplicar
.thumb_func               		@ Se avisa al emsablador que esta es una funcion
      asm_productoEscalar16:    @ Etiqueta/nombre de la función.
        push {R4}				@ Guardo el registro en pila para recuperarlo luego
        asm_pe16_loop:
        	ldrh R4, [R0], #2	@ Carga el valor de memoria en [R0] en el registro R4, e incrementa R0 en 2 (porque tiene 2 bytes)
        						@ Utilizo la función de leer de 16 bits sin signo
			mul R4, R3			@ Multiplica R3xR4 y lo guarda en R4
			strh R4, [R1], #2	@ Ahora guardo el valor. Sólo 2 bytes.
			subs R2, 1			@ Decremento el lardo del vector...
			bne asm_pe16_loop	@ A menos que R2 sea cero, vuelvo a asm_loop
		pop {R4}
		bx LR					@ Retornamos


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   asm_productoEscalar12(uint16_t * vectorIn, uint16_t * vectorOut, uint32_t longitud, uint16_t escalar);
@
@ Parametros recibidos:
@   r0: dirección de memoria de inicio del vector de entrada
@   r1: dirección de memoria de inicio del vector de salida
@	r2: longitud
@	r3: escalar a multiplicar
.thumb_func               		@ Se avisa al emsablador que esta es una funcion
      asm_productoEscalar12:    @ Etiqueta/nombre de la función.
        push {R4}				@ Guardo el registro en pila para recuperarlo luego
        asm_pe12_loop:
        	ldrh R4, [R0], #2	@ Carga 2 bytes desde dirección de memoria [R0] en el registro R4,
        						@ e incrementa R0 en 2 (porque tiene 2 bytes).
        						@ Utilizo la función de leer de 16 bits sin signo.
			mul R4, R3			@ Multiplica R3xR4 y lo guarda en R4, que tiene 4 bytes
			usat R4, #12, R4	@ Saturamos en 12 bits a R4
			strh R4, [R1], #2	@ Ahora guardo el valor. Sólo 2 bytes.
			subs R2, #1			@ Decremento el lardo del vector...
			bne asm_pe12_loop	@ A menos que R2 sea cero, vuelvo a asm_loop
		pop {R4}
		bx LR					@ Retornamos


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   void asm_filtroVentana10(uint16_t * vectorIn, uint16_t * vectorOut, uint32_t longitudVectorIn);
@
@ Parametros recibidos:
@   R0: dirección de memoria de inicio del vector de entrada (no se modifica)
@   R1: dirección de memoria de inicio del vector de salida  (no se modifica)
@	R2: longitud (se traduce a cantidad de bytes totales del vector, menos 2)
@
@ Registros utilizados
@	R3: desplazamiento (en bytes) para valor central de ventana leída y para escritura de promedio en salida
@	R4: desplazamiento (en bytes) minimo para la ventana (se va aumentando recorriendo la ventana)
@	R5: desplazamiento (en bytes) máximo para la ventana (que fijo para cada ventana)
@	R6: guarda la suma de cada ventana y luego su promedio
@   R7: valor leído desde la memoria del vector de entrada
@   R8: ancho de la ventana (varía al inicio y fin de cada ventana) en indice
@
.thumb_func               		@ Se avisa al emsablador que esta es una funcion.
      asm_filtroVentana10:		@ Etiqueta/nombre de la función.
        push {R4-R8}			@ Guardo el registro en pila para recuperarlo luego.
        mov R3, #0				@ Desplazamiento R3 se inicia en 0 que luego irá subiendo.

        @ Traducción de longitud en bytes
        sub R2, 1				@ Le resto 1 a R2 porque, si hay sólo un elemento,
        						@ no hay desplazamiento: dirección máxima es igual a la mínima.
        lsl R2, R2, 1			@ Multiplica por 2 a longtud porque son dos bytes por índice.

		@ Ciclo que recorre cada valor que se escribe en salida
		@ Este loop está determinado por la longitud R2
        asm_fv10_loop:
        	@ Determinamos desplazamiento mínimo para la ventana
        	sub R4, R3, #10		@ R4 será el indice mínimo, 5 índices menos que R3
        	cmp R3, #10			@ Vamos a comparar nuestro desplazamiento R3 con
        						@ el mínimo que no recorta la ventana
        	it lo
        	movlo R4, #0		@ Si R3<10, hago que el mínimo desplazamiento a promediar sea 0

			@ Determinamos desplazamiento máximo para la ventana
        	add R5, R3, #10		@ R5 será el desplazamiento máximo
        	cmp R5, R2			@ Comparo con el máximo permitido
        	it hs
        	movhs R5, R2		@ Pongo el máximo en R5 si R5>R2

			@ Otros cálculos antes de recorrer la ventana
        	mov R6, #0			@ Inicializo en 0 la cuenta a promediar
        	sub R8, R5, R4		@ Calculo ancho de ventana
        	lsr R8, R8, #1		@ Divido por dos, porque el ancho debe estar en índices, no bytes
        	add R8, R8, #1		@ Le sumo 1 porque así tengo en cuenta todas las sumas

			@ Bucle para sumar los valores de la ventana definida
        	asm_fv10_loop2:			@ Ahora puedo hacer el for...
        		ldrh R7, [R0, R4]	@ Carga 2 bytes desde dirección de memoria [R0+R4] en el registro R7
        		add R6, R6, R7		@ Le sumo este valor cargado a la cuenta a promedias R6
        		cmp R4, R5			@ Comparo si ya son iguales o no (si ya sumé todos los valores de la ventana).
        		add R4, #2			@ Incrementa R4 en 2 (porque cada ínidice tiene 2 bytes).
        							@ Esta suma la hago después de CMP porque
        							@ tiene que ejecutarse una vez cuando son iguales.
				bne asm_fv10_loop2	@ Retomo loop2 mientas no sean iguales aún

			@ Ahora promediamos y evaluamos si ya terminamos
			udiv R6, R6, R8		@ Aquí viene el promedio!!!
			strh R6, [R1, R3]	@ Ahora guardo el valor. Sólo 2 bytes.
			cmp R3, R2			@ Comparo posición actual con el máximo permitido
			add R3, #2			@ Aumento 2 por si tengo que iterar
			bne asm_fv10_loop

		pop {R4-R8}
		bx LR					@ Retornamos

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   void asm_pack32to16 (int32_t * vectorIn, int16_t *vectorOut, uint32_t longitud);
@
@ Parametros recibidos:
@   R0: dirección de memoria de inicio del vector de entrada
@   R1: dirección de memoria de inicio del vector de salida
@	R2: longitud
.thumb_func
      asm_pack32to16:
        @ push {R4}				@ Guardo el registro en pila para recuperarlo luego
        asm_pack_loop:
        	ldr R3, [R0], #4	@ Carga 4 bytes desde dirección de memoria [R0] en el registro R3,
        						@ e incrementa R0 en 4 (porque tiene 4 bytes).
			lsr R3, R3, #16		@ LogigShiftRigth, corro el registro 16 bits para empaquetar
			strh R3, [R1], #2	@ Ahora guardo el valor. Sólo 2 bytes.
			subs R2, 1			@ Decremento el largo del vector...
			bne asm_pack_loop	@ A menos que R2 sea cero, vuelvo al ciclo
		@ pop {R4}
		bx LR					@ Retornamos


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   int32_t asm_max (int32_t * vectorIn, uint32_t longitud);
@
@ Parametros recibidos:
@   R0: dirección de memoria de inicio del vector de entrada
@   R1: longitud
@
@ Comentario:
@	int32_t va desde -2147483648 a +2147483647
@
@ Registros utilizados
@   R2: índice que se está evaluando
@   R3: valor de ese índice
@   R4: índice con el valor máximo
@	R5: valor máximo actual
@
.thumb_func
      asm_max:
        push {R4-R5}			@ Guardo el registro en pila para recuperarlo luego
        mov R2, #0				@ Primer índice evaluado
        mov R4, #0				@ Inicialmente, supongo que el índice máximo es el primero
        mov R5, #0				@ Inicialmente, el valor máximo es #0
        asm_max_loop:
        	ldr R3, [R0], #4	@ Carga 4 bytes desde dirección de memoria [R0] en el registro R3,
        						@ e incrementa R0 en 4 (porque tiene 4 bytes).

        	@ Bloque de comparación...
			cmp R3, R5			@ Comparo lo leído con el máximo almacenado
			ITT GT				@ Bloque IT cuando R3>R4 con signo
			movgt R5, R3		@ Si se cumple, almaceno nuevo valor máximo
			movgt R4, R2		@ Tengo un nuevo índice con valor máximo

			add R2, 1			@ Incremento el índice a evauar
			cmp R2, R1			@ Comparo índice con longitud
			bne asm_max_loop	@ A menos que R2 sea cero, vuelvo al ciclo

		mov R0, R4		@ Almaceno el índice con valor máximo en la salida
		pop {R4-R5}		@ Devuelvo registros
		bx LR			@ Retornamos


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   void asm_downsampleM (int32_t * vectorIn, int32_t * vectorOut, uint32_t longitud, uint32_t N);
@
@ Parametros recibidos:
@   R0: dirección de memoria de inicio del vector de entrada
@   R1: dirección de memoria de inicio del vector de salida
@   R2: longitud
@   R3: se quita una muestra cada N=R3 muestras
@
@ Registros utilizados
@	R4: cuenta para saltear muestra
@	R5: valor leído del vector y luego guardado en el otro vector
.thumb_func
      asm_downsampleM:
        push {R4-R5}			@ Guardo el registro en pila para recuperarlo luego
        mov R4, R3				@ Inicializo cuenta regresiva de cuenta a saltear

        @mov R4, #0				@ Inicialmente, supongo que el índice máximo es el primero
        @mov R5, #0				@ Inicialmente, el valor máximo es #0
        asm_downsampleM_loop:
        	ldr R5, [R0], #4	@ Carga 4 bytes desde dirección de memoria [R0] en R5
        						@ e incrementa R0 en 4 (porque tiene 4 bytes).
        	subs R4, #1			@ Decremento la cuenta regresiva y veo si copio o no
        	ITE NE
        	strne R5, [R1], #4	@ Si R4>0, copio valor y aumento dirección de memoria destino.
        	moveq R4, R3		@ Si R4==0, no copio pero reinicializo contador

			subs R2, #1			@ Decrementa el contador de longitud
			bne asm_downsampleM_loop	@ A menos que R2 sea cero, vuelvo al ciclo

		pop {R4-R5}		@ Devuelvo registros
		bx LR			@ Retornamos


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   void asm_invertir (uint16_t * vector, uint32_t longitud);
@
@ Parametros recibidos:
@   R0: dirección de memoria de inicio del vector de entrada/salida
@		--> iremos incrementando para leer valores y mofificarlos
@   R1: longitud
@		--> lo transformamos en dirección última, que se irá decrementando y acercando a R0
@
@ Registros utilizados
@	R2 y R3: valores leídos
@
.thumb_func
	asm_invertir:
        @ Transformo R1 de longitud a última dirección
        sub R1, #1			@ índices empieza en #0
        lsl R1, R1, #1		@ multiplico por 2 (2 bytes por valor)
        add R1, R1, R0		@ última dirección

        asm_invertir_loop:
        	@ Leemos datos del vector
        	ldrh R2, [R0]			@ Carga 2 bytes desde dirección de memoria [R0] en el registro R2
        	ldrh R3, [R1]			@ Carga desde el final

        	@ Escribimos datos invertidos
			strh R3, [R0], #2		@ Ahora guardo el valor del final en el inicio. Y sumo 2 bytes.
			strh R2, [R1], -2		@ Idem al revés

			cmp R0, R1				@ Comparo ambas direcciones
			blo asm_invertir_loop 	@ Mientras R0<R1, vuelvo al ciclo

		bx LR						@ Retornamos


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   void asm_corr (int16_t * vectorX, int16_t * vectorY, int16_t * vectorCorr, uint32_t N);
@
@ Parametros recibidos:
@   R0: puntero del vector de entrada X
@   R1: puntero del vector de entrada Y
@	R2: puntero del vector correlación
@	R3: N, longitud de los vectores (que luego traduzco a dirección fin de cálculo)
@
@ Registros utilizados:
@	R4: resultado que se va calculando
@   R5: valor de X
@   R6: valor de Y
@   R7: desplazamiento en vector X (direccion de memoria)
@   R8: desplazamiento en vector Y (direccion de memoria)
@
.thumb_func               		@ Se avisa al emsablador que esta es una funcion
      asm_corr: 				@ Etiqueta/nombre de la función.

        push {R4-R8}			@ Guardo registros en pila para recuperarlo luego
 		cmp R3, 0				@ Si por casualidad me dan un vector sin contenido,
		beq asm_corr_fin		@ salto al final directamente.

        lsl R3, R3, #1			@ Multiplico longitud N por 2 para traducirlo de índice a bytes
        add R3, R0, R3			@ Ahora R3 es la dirección final (excluyente) de vector X
		mov R4, #0				@ Valor inicial del resultado

        asm_corr_loop:
		@ Correlación debe leer desde dirección R0 a R3
			mov R7, R0			@ Desplazamiento R7 comienza en dirección R0 (que luego iremos subiendo)
			mov R8, R1			@ Desplazamiento para recorrer vector Y

			asm_corr_loop2:
			@ R7 debe ir hasta dirección final R3

        	ldrh R5, [R7]		@ Carga 2 bytes del vectorX en R5
        	add  R7, R7, #2		@ Incremento desplazamiento R7 en dos bytes
        						@ (luego iré subiendo R0 para ir corriendo la cuenta)
        	ldrh R6, [R8], #2	@ Carga 2 bytes del vectorY en R6 e incremento en 2
        	mla R4, R5, R6, R4	@ Multipliación acumulativa: R4 = R5*R6 + R4

			cmp R7, R3
			blo	asm_corr_loop2	@ Mientras R7 no llegue a ser R3, vuelvo a ejecutar loop2

		@ Ya hice el cálculo de un valor de vectorCorr
		@ Ahora lo almaceno
		strh  R4, [R2], #2		@ Almaceno el cálculo R4 en dirección R2 (y aumento la dirección)
		mov R4, #0				@ Valor inicial del resultado
		add R0, R0, #2			@ Aumento un valor el inicio de vector X (no así con vector Y)
		cmp R0, R3				@ Mientras R0 no llegue a ser R3, vuelvo a ejecutar loop
		blo	asm_corr_loop

		asm_corr_fin:			@ Fin de función
		pop {R4-R8}
		bx LR					@ Retornamos

