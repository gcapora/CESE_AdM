# Preguntas y respuestas de AdM

Guillermo F. Caporaletti <gfcaporaletti@undav.edu.ar>, Arquitectura de Microprocesadores, CESE-FIUBA, 18Co.

## Preguntas orientadoras

### 1. Describa brevemente los diferentes perfiles de familias de microprocesadores/microcontroladores de ARM. Explique alguna de sus diferencias características.

Son tres familias:
- ARM Cortex A: Utilizados por los celulares. Orientado a aplicaciones. Requiere un Tick de 10 ms aprox. para satisfacer las necesidades multimedia y de las aplicaciones. Tiene caché para acelerar funcionamiento. Tiene MMU (Unidad de Gestión de Memoria) para evitar que una aplicación (proceso) lea o pise la memoria de otra. Usa Android usualmente. 
- ARM Cortex M: Microcontroladores de propósito general; para sistemas embebidos compactos. No tiene caché, porque esto haría que su funcionamiento sea menos determinista. No tiene MMU (Unidad de Gestión de Memoria), porque le quitaría recursos: la responsabilidad de utilizar correctamente la memoria recae en el programador. Tiene MPU (Unidad de Protección de Memoria), que limita o protege algunas áreas de memoria. Utiliza usualmente Bare-metal o RTOS. 
- ARM Cortex R: Especializado en Sistemas de Tiempo Real (RTS). Tampoco tiene caché (por el mismo motivo). Necesita ser más determinista. Baja latencia y alta capacidad de procesamiento. Tick de 1 ms aprox.

## Cortex M

### 1. Describa brevemente las diferencias entre las familias de procesadores Cortex M0, M3 y M4.

- M0: Con arquitectura de memoria Von Neuman. Memoria RAM (datos) y Flash (código) comparten un mismo bus. SysTick opcional. No posee MPU. Tiene un conjunto (set) de instrucciones acotado. Esto deriva en que necesita más instrucciones que un M3 para hacer lo mismo. Como ventaja: es más económico.  
- M3: Con arquitectura Hardvard de memoria. Memoria RAM y Flash tiene busses diferentes. Esto le permite mayor velocidad. Posee SysTick. MPU opcional. Bit-banding como opcional. Incorpora todas las omstrucciones Thumb-1 y Thumb-2. 
- M4: Es básicamente un M3 aunque: Incorpora el FPU (punto flotante) opcional. Incorpora funciones DSP.

### 2. ¿Por qué se dice que el set de instrucciones Thumb permite mayor densidad de código? Explique

Las instrucciones Thumb (o Pulgar) permiten intercalar instruciones de 32 bits y de 16 bits. Cuando queremos manejar datos de 16 bits, hay desperdicio de recursos (en los 16 bits que sobran de aquellos 32). Entonces, permitiendo el modo Thumb, puede hacer lo mismo con instrucciones de la mitad de tamaño. 
Existen dos versiones de modo Thumb: El primero era switchear entre modo 32 y modo 16. El modo Thumb-2 permite intercalar las funciones de 16 y 32 bits.

### 3. ¿Qué entiende por arquitectura load-store? ¿Qué tipo de instrucciones no posee este tipo de arquitectura?

Es una arquitectura en la que casi todas (menos 2) sus instrucciones sólo actúan sobre los registros del micro. Porque así no hay que esperar la lectura a través del bus. Las dos instrucciones que no cumplen con esta estructura son precisamente LOAD y STORE, queleen y escriben en memoria lo que se pidió para la instrucción o su resultado.

### 4. ¿Cómo es el mapa de memoria de la familia?

La memoria del Cortex dispone 4 Gb: asignados con 32 bits. En estos 4 Gb se puede leer y escribir memoria SRAM (ultra rápida, cercana al micro), RAM (datos), Flash (programa), puertos externos y otro tipo de mapeos como el el bit-banding. Cada función o tipo de acceso tiene un rango de memoria exclusivo y determinado por ARM.

5. ¿Qué ventajas presenta el uso de los “shadowed pointers” del PSP y el MSP?

### 6. Describa los diferentes modos de privilegio y operación del Cortex M, sus relaciones y como se conmuta de uno al otro. Describa un ejemplo en el que se pasa del modo privilegiado a no priviligiado y nuevamente a privilegiado.

El Cortex M tiene dos modos de privilegio: privilegiado y no privilegiado. Inicia en modo privilegiado, el cual permite acceder a todas las direccioens de memoria y recursos del micro. A partir de la modificación de un flag, mediante software, se puede pasar a modo no-privilegiado. En este modo, se pone en funciones el MPU (unidad de protección de memoria), que impide que se modifiquen ciertas áreas de la memoria. Esto sirve para que un proceso no acceda a regiones indebidas. Desde el modo no-privilegiado no es posible volver a modificar el flag para volver al modo privilegiado.

Junto con esto coexisten los modos de operación, pensados para el manejo de procesos en paralelo (multitasking): modo Thread (hilo, tarea o proceso) y modo Handler (manejador). Se inicia en modo Thread privilegiado. Se puede pasar a modo Thread no-privilegiado mediante el flag descripto antes. ¿Cómo se puede acceder a todos los recursos del sistema? Pasando al modo Handler mediante un evento o interrupción. El modo Handler siempre trabaja en modo privilegiado. Esto sirve, por ejemplo, a que el modo Handler acceda a todos los recursos y los "maneje" (o administre) para pasarle los datos requeridos a cada tarea o proceso. 

En este modo Handler podría volver a setearse el flag en modo privilegiado nuevamente.

### 7. ¿Qué se entiende por modelo de registros ortogonal? Dé un ejemplo

Que cualquier registro puede ser utilizado para cualquier operación por una instrucción. No hay registros especiales para cada instrucción. Los registros son de propósito general.

8. ¿Qué ventajas presenta el uso de intrucciones de ejecución condicional (IT)? Dé un ejemplo
9. Describa brevemente las excepciones más prioritarias (reset, NMI, Hardfault).

### 10. Describa las funciones principales de la pila. ¿Cómo resuelve la arquitectura el llamado a funciones y su retorno?

Su principal función es pasar parámetros a una función, almacenar sus valores durante su operación y devolverlos. Aunque, en ARM, los primeros parámetros son pasados y devueltos a través de los registros r0 a r3. 

11. Describa la secuencia de reset del microprocesador.
12. ¿Qué entiende por “core peripherals”? ¿Qué diferencia existe entre estos y el resto de los periféricos?
13. ¿Cómo se implementan las prioridades de las interrupciones? Dé un ejemplo.
14. ¿Qué es el CMSIS? ¿Qué función cumple? ¿Quién lo provee? ¿Qué ventajas aporta?
15. Cuando ocurre una interrupción, asumiendo que está habilitada ¿Cómo opera el microprocesador para atender a la subrutina correspondiente? Explique con un ejemplo.
17. ¿Cómo cambia la operación de stacking al utilizar la unidad de punto flotante?
16. Explique las características avanzadas de atención a interrupciones: tail chaining y late arrival.

### 17. ¿Qué es el systick? ¿Por qué puede afirmarse que su implementación favorece la portabilidad de los sistemas operativos embebidos?

Es un conjunto de funciones que opera una base de tiempo. El hecho que diversos sistemas utilicen el mismo conjunto de funciones para la base de tiempo (que regula el multitasking, por ejemplo) hace que a la hora de programar no nos preocupemos cómo o con qué recursos de hardware se logra esta base de tiempo. Entonces facilita la portabilidad más allá del micro utilizado.

### 18. ¿Qué funciones cumple la unidad de protección de memoria (MPU)?

Bloquea la posibilidad de escribir determinadas partes de memoria cuando se trabaja em modo no-privilegiado. Esto es una protección para que un proceso determinado no modifique áreas de memoria críticas que no debe modificar.

20. ¿Cuántas regiones pueden configurarse como máximo? ¿Qué ocurre en caso de haber solapamientos de las regiones? ¿Qué ocurre con las zonas de memoria no cubiertas por las regiones definidas?
20. ¿Para qué se suele utilizar la excepción PendSV? ¿Cómo se relaciona su uso con el resto de las excepciones? Dé un ejemplo.
21. ¿Para qué se suele utilizar la excepción SVC? Expliquelo dentro de un marco de un sistema operativo embebido.

## ISA

1. ¿Qué son los sufijos y para qué se los utiliza? Dé un ejemplo.
2. ¿Para qué se utiliza el sufijo ‘s’? Dé un ejemplo.
3. ¿Qué utilidad tiene la implementación de instrucciones de aritmética saturada? Dé un ejemplo con operaciones con datos de 8 bits.
4. Describa brevemente la interfaz entre assembler y C ¿Cómo se reciben los argumentos de las funciones? ¿Cómo se devuelve el resultado? ¿Qué registros deben guardarse en la
pila antes de ser modificados?
5. ¿Qué es una instrucción SIMD? ¿En qué se aplican y que ventajas reporta su uso? Dé un ejemplo.
