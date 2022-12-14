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

### 5. ¿Qué ventajas presenta el uso de los “shadowed pointers” del PSP y el MSP?

Son "registros en las sombras" porque no se pueden acceder directamente. Por ejemplo, se puede seleccionar en el bit 2 del registro LR de retorno. Process Stack Pointer indica la dirección de un proceso o tarea. Main Stack Pointer se utiliza para el scheduler (planificador) del sistema operativo.

### 6. Describa los diferentes modos de privilegio y operación del Cortex M, sus relaciones y como se conmuta de uno al otro. Describa un ejemplo en el que se pasa del modo privilegiado a no priviligiado y nuevamente a privilegiado.

El Cortex M tiene dos modos de privilegio: privilegiado y no privilegiado. Inicia en modo privilegiado, el cual permite acceder a todas las direccioens de memoria y recursos del micro. A partir de la modificación de un flag, mediante software, se puede pasar a modo no-privilegiado. En este modo, se pone en funciones el MPU (unidad de protección de memoria), que impide que se modifiquen ciertas áreas de la memoria. Esto sirve para que un proceso no acceda a regiones indebidas. Desde el modo no-privilegiado no es posible volver a modificar el flag para volver al modo privilegiado.

Junto con esto coexisten los modos de operación, pensados para el manejo de procesos en paralelo (multitasking): modo Thread (hilo, tarea o proceso) y modo Handler (manejador). Se inicia en modo Thread privilegiado. Se puede pasar a modo Thread no-privilegiado mediante el flag descripto antes. ¿Cómo se puede acceder a todos los recursos del sistema? Pasando al modo Handler mediante un evento o interrupción. El modo Handler siempre trabaja en modo privilegiado. Esto sirve, por ejemplo, a que el modo Handler acceda a todos los recursos y los "maneje" (o administre) para pasarle los datos requeridos a cada tarea o proceso. 

En este modo Handler podría volver a setearse el flag en modo privilegiado nuevamente.

### 7. ¿Qué se entiende por modelo de registros ortogonal? Dé un ejemplo

Que cualquier registro puede ser utilizado para cualquier operación por una instrucción. No hay registros especiales para cada instrucción. Los registros son de propósito general.

### 8. ¿Qué ventajas presenta el uso de intrucciones de ejecución condicional (IT)? Dé un ejemplo

Básicamente que no debe cambiar la dirección de ejecución del código, cuestión que implica algún retraso para volver a leer código, datos y cargar registros. Para condicionales con pocas instrucciones, se puede utilizar la ejecución condicional y así se logra que la ejecución de código no se vea interrumpida. 

Ejemplo en C (en verdad debería codificarse en Assembler): a = r>29 ? 29 : r; En ese ejemplo, se pierde demasiado tiempo si el procesamiento de código de be cambiar de dirección para hacer esta comparación tan simple.

### 9. Describa brevemente las excepciones más prioritarias (reset, NMI, Hardfault).

Reset: Reinicia todo, con máxima prioridad, sin que nada pueda evitarlo.
Hardfault: Cuando hay alguna falla de hardware (cuando hay baja tensión, por ejemplo).
NMI: Interrupción importante que no se puede desactivar.

### 10. Describa las funciones principales de la pila. ¿Cómo resuelve la arquitectura el llamado a funciones y su retorno?

Su principal función es pasar parámetros a una función, almacenar sus valores durante su operación y devolverlos. Aunque, en ARM, los primeros parámetros son pasados y devueltos a través de los registros r0 a r3. 

### 11. Describa la secuencia de reset del microprocesador.

El evento Reset ocurre apenas se energiza el micro. Lee dirección 0 y se lo asigna a MSP. Lee el vector de Reset y empieza la ejecución de instrucciones. Entonces, en las funciones programdas por ST, pone en cero determinadas variables y asigna valores a las variables static. Ejecuta SystemInit, que inicializa memoria externa, por ejemplo. 

### 12. ¿Qué entiende por “core peripherals”? ¿Qué diferencia existe entre estos y el resto de los periféricos?

"Core peripherals" son módulos integrados al core para agilizar su funcionamiento: NVIC (Nested Vectored Interrupt Controller), System Control Block, System timer, Memory Protection Unit. El resto de los periféricos necesariamente utilizan el bus de datos (ram) y de programa (flash).

### 13. ¿Cómo se implementan las prioridades de las interrupciones? Dé un ejemplo.

Están definidas en el vector de interrupciones. Se ejecuta primero la más prioritaria y se van resolviendo luego las menos. Si una menos prioritaria se llama dos veces mientras una más prioritaria se está ejecutando, se pierde el doble llamado. Sólo se ejecuta una vez cuando le toque. Algunas prioridades están definidas por ARM, otras por el fabricante, y otras por el programador.

### 14. ¿Qué es el CMSIS? ¿Qué función cumple? ¿Quién lo provee? ¿Qué ventajas aporta?

Es un estandart de hardware y funciones para la arquitectura Cortex. Estandariza funciones que deben ser implementada en los Cortex para acceder a periféricos y recursos de hardware del micro. De este modo, se utilizan en C y no es necesario utilizar Assembler. Es un estandart establecido por ARM. Lo debe implementar cada fabricante de micro con arquitectura Cortex. La ventaja es que ayuda a migrar de un micro Cortex a otro. 

### 15. Cuando ocurre una interrupción, asumiendo que está habilitada ¿Cómo opera el microprocesador para atender a la subrutina correspondiente? Explique con un ejemplo.

Entra en un estado de exceptción y guarda los registros en la pila (stack) con push, para conservar el contexto actual que se estaba ejecutando. Antes de terminar de hacer pop, ya va leyendo el vector de interrupciones para ver que ISR debe ejecutar. Va llenanndo el pipeline para ejecutar la función de atención de la interrupción (ISR, interrupt service rutine) inmediatamente luego de terminar de hacer pop. Ejecuta. Devuelve el contexto con pop. Y vuelve adonde estaba.

### 17. ¿Cómo cambia la operación de stacking al utilizar la unidad de punto flotante?

Se fija si estamos usando punto flotante en el registro FPCA. Si es así, guardo registros extras de uso de punto flotante. Son dos o tres veces más registros. Por eso, no conviene utilizar FPU en un manejador de interrupción.

### 16. Explique las características avanzadas de atención a interrupciones: tail chaining y late arrival.

Tail chaining: Si debe atender otra interrupción luego de haber ejecutado una, no devuelve el contexto sino que sigue con a ejecución de la otra interrupción (de igual o menor prioridad). Y devolver el contexto cuando hayan terminado las interrupciones. 
Late arrival: Empezó una interrupción de baja prioridad. Si entra una de más prioridad cuando aún estamos en apilado de contexto, el llamado va a atender la de mayor prioridad.

### 17. ¿Qué es el systick? ¿Por qué puede afirmarse que su implementación favorece la portabilidad de los sistemas operativos embebidos?

Es un conjunto de funciones que opera una base de tiempo. El hecho que diversos sistemas utilicen el mismo conjunto de funciones para la base de tiempo (que regula el multitasking, por ejemplo) hace que a la hora de programar no nos preocupemos cómo o con qué recursos de hardware se logra esta base de tiempo. Entonces facilita la portabilidad más allá del micro utilizado.

### 18. ¿Qué funciones cumple la unidad de protección de memoria (MPU)?

Bloquea la posibilidad de escribir determinadas partes de memoria cuando se trabaja em modo no-privilegiado. Esto es una protección para que un proceso determinado no modifique áreas de memoria críticas que no debe modificar.

### 19. ¿Cuántas regiones pueden configurarse como máximo? ¿Qué ocurre en caso de haber solapamientos de las regiones? ¿Qué ocurre con las zonas de memoria no cubiertas por las regiones definidas?

En la MPU se pueden definir hasta 8 regiones de memoria, con diferente tamaño, direcciones de inicio y configuraciones especificas. Si el micro trabaja en modo no privilegiado y el MPU esta activado, todo acceso a memoria que no se encuentre en una es estas posibles regiones va a generar un fallo. Toda región que no esté dentro de estas 8 regiones sólo podría accederse en modo privilegiado.

### 20. ¿Para qué se suele utilizar la excepción PendSV? ¿Cómo se relaciona su uso con el resto de las excepciones? Dé un ejemplo.

PendSV (Pendable SerVice) es una interrupción que es usada por el sistema operativo (OS) para forzar un cambio de contexto, si no hay otra interrupción activa. 

### 21. ¿Para qué se suele utilizar la excepción SVC? Expliquelo dentro de un marco de un sistema operativo embebido.

SVCall (SuperVisor Call) es llamada por la instrucción SVC. Es usada, por ejemplo, por FreeRTOS para iniciar el planificador (scheduler).

## ISA (Instruction Set Architecture)

### 1. ¿Qué son los sufijos y para qué se los utiliza? Dé un ejemplo.

Sirven para ampliar la funcionalidad de una función de Assembler. Por ejemplo: actualizar las banderas (flags). O especificar si es un dato de 8 bits o 16 bits, con o sin signo. 

### 2. ¿Para qué se utiliza el sufijo ‘s’? Dé un ejemplo.

La instrucción "add" suma; y la instrucción "adds", además de sumar, actualiza las banderas a partir del resultado de esa suma. Esto se complementa con las instrucciones condicionales.

### 3. ¿Qué utilidad tiene la implementación de instrucciones de aritmética saturada? Dé un ejemplo con operaciones con datos de 8 bits.

Permite manejar el overflow. Puede ocurrir que no sepa si hubo overflow o no. Y un valor un poco más grande que el máximo retorna o uno negativo o uno muy chico (según el dato sea con o sin signo). Para tratamiento de señales, es mejor una saturación que un cambio tan grande en la salida de a operación. Si esta función ya está implementada en la ISA, me ahorro los condicionales previos.

### 4. Describa brevemente la interfaz entre assembler y C ¿Cómo se reciben los argumentos de las funciones? ¿Cómo se devuelve el resultado? ¿Qué registros deben guardarse en la pila antes de ser modificados?

Los primeros 4 argumentos de una función, se reciben por los registros. Se cargan allí y la función opera con los registros. Más parámetros, deben pasarse por la pila (stack). Si dentro de la función debo utilizar más registros, debo almacenarlos en la pila y luego recuperarlos antes de retornar la función (utilizando push {r4-r6} y pop {r4-r6} por ejemplo). 

Para los valores que devuelve utiliza los registros r0 y r1. También puede actuar sobre memoria directamente, utilizando punteros.

### 5. ¿Qué es una instrucción SIMD? ¿En qué se aplican y que ventajas reporta su uso? Dé un ejemplo.

Permiten operar varios datos a la vez. El micro lee y opera en 32 bits. Por lo tanto, si proceso un vector de datos de 8 bits, puedo operar de a 4. Esto lo hace entonces 4 veces más rápido que haciendo la operaciń con cada elemento por separado. 
