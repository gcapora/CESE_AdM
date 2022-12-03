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
			usat R4, #11, R4	@ Saturamos en 12 bits a R4
			strh R4, [R1], #2	@ Ahora guardo el valor. Sólo 2 bytes.
			subs R2, 1			@ Decremento el lardo del vector...
			bne asm_pe12_loop	@ A menos que R2 sea cero, vuelvo a asm_loop
		pop {R4}
		bx LR					@ Retornamos


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Prototipo en "C":
@   void asm_filtroVentana10(uint16_t * vectorIn, uint16_t * vectorOut, uint32_t longitudVectorIn);
@
@ Parametros recibidos:
@   r0: dirección de memoria de inicio del vector de entrada
@   r1: dirección de memoria de inicio del vector de salida
@	r2: longitud
.thumb_func               		@ Se avisa al emsablador que esta es una funcion
      asm_filtroVentana10:		@ Etiqueta/nombre de la función.
        push {R4-R8}			@ Guardo el registro en pila para recuperarlo luego
        mov R3, #0				@ Desplazamiento R3 se inicia en 0
        						@ que luego irá subiendo
        sub R2, 1				@ Le resto 1 a R2 porque, si hay sólo un elemento,
        						@ no hay desplazamiento: dirección máxima es igual a a mínima
        lsl R2, R2, 1			@ Multiplica por 2 al largo porque son dos bytes por índice.

        asm_fv10_loop:			@ Este loop está determinado por R2, que se va decrementando
        	sub R4, R3, #10		@ R4 será el indice mínimo, 5 índices menos que R3
        	cmp R3, #10			@ Vamos a comparar nuestro desplazamiento R3
        						@ con el mínimo que no recorta la ventana
        	it lo
        	movlo R4, #0		@ Si R3<10, hago que el mínimo desplazamiento a promediar sea 0

        	add R5, R3, #10		@ R5 será el desplazamiento máximo
        	cmp R5, R2			@ Comparo con el máximo permitido
        	it hs
        	movhs R5, R2		@ Pongo el máximo en R5 si R5>R2

        	mov R6, #0			@ Inicializo en 0 la cuenta a promediar
        	sub R8, R5, R4		@ Calculo ancho de ventana
        	lsr R8, R8, #1		@ Divido por dos
        	add R8, R8, #1		@ Le sumo 1 porque así tengo en cuanta todas las sumas

        	asm_fv10_loop2:			@ Ahora puedo hacer el for...
        		ldrh R7, [R0, R4]	@ Carga 2 bytes desde dirección de memoria [R0+R4] en el registro R7
        		add R6, R6, R7		@ Le sumo este valor cargado a la cuenta a promedias R6
        		cmp R4, R5			@ Comparo si ya son iguales o no.
        		add R4, #2			@ Incrementa R4 en 2 (porque cada ínidice tiene 2 bytes).
        							@ Esta suma la hago desdepués de CMP porque
        							@ tiene que ejecutarse una vez cuando son iguales.
				bne asm_fv10_loop2	@ Salto si ya son iguales (y ya se ejecutó)

			udiv R6, R6, R8		@ Aquí viene el promedio!!!
			strh R6, [R1, R3]	@ Ahora guardo el valor. Sólo 2 bytes.
			cmp R3, R2			@ Comparo posición actual con el máximo permitido
			add R3, #2			@ Aumento 2 por si tengo que iterar
			bne asm_fv10_loop

		pop {R4-R8}
		bx LR					@ Retornamos
