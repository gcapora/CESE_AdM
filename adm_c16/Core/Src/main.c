/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Módulo principal del proyecto AdM
  ******************************************************************************
  * @attention
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "asm_func.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */
#define N_MUESTRAS		1024

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart3;

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART3_UART_Init(void);
/* USER CODE BEGIN PFP */
static void PrivilegiosSVC (void);

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */
  // **************************************************************************
  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/
  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();
  /* USER CODE BEGIN Init */
  /* USER CODE END Init */
  /* Configure the system clock */
  SystemClock_Config();
  /* USER CODE BEGIN SysInit */

  // Activa contador de ciclos (iniciar una sola vez)
  DWT->CTRL |= 1 << DWT_CTRL_CYCCNTENA_Pos;

  /* USER CODE END SysInit */
  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART3_UART_Init();

  /* USER CODE BEGIN 2 */
  // **************************************************************************
  // Variables locales a Main: (guardadas en la pila)
  volatile uint32_t Ciclos;
  uint32_t i;
  uint32_t senial1[N_MUESTRAS];
  uint32_t senial2[N_MUESTRAS];
  uint16_t senial16[N_MUESTRAS];
  uint16_t senial16b[N_MUESTRAS];

  senial1[N_MUESTRAS-1] = 99;
  senial16[0] = 1;
  for (i=0; i<N_MUESTRAS; i++) {
  	  senial16[i] = i;
  }

  // **************************************************************************
  // Mensaje con el modo de compilación
  EnviaTexto ( (uint8_t *) "---------------------------------------------------------");
  #ifdef DEBUG
  EnviaTexto ( (uint8_t *) "Compilado en modo DEBUG.");
  #else
  EnviaTexto ( (uint8_t *) "Compilado en modo RELEASE.");
  #endif

  // **************************************************************************
  // 0) Prueba de modos de privilegio
  PrivilegiosSVC ();
  const uint32_t suma = asm_sum (5, 3);

  // **************************************************************************
  // 1) Fn zeros
  // Inicio prueba de productos escalares
  // Asignación de valores...
  asm_zeros (senial1, N_MUESTRAS);   					// Función en Assembler
  ones(senial1, N_MUESTRAS);
  asm_productoEscalar32(senial1, senial2, N_MUESTRAS, 1);	// Esto equivale a copiar un vector en otro

  // **************************************************************************
  // 4) Multiplicación de vector por escalar con saturación de 12 bits
  // ¡¡¡Contando ciclos!!!

  // Antes de la función a medir: contador de ciclos a cero
  DWT->CYCCNT = 0;

  // Vamos a multiplicar el contenido de senial16 por un valor algunas veces
  for (i=0; i<4; i++) {
  	  productoEscalar12(senial16, senial16, N_MUESTRAS, 3);
  }

  // Mido la cantidad de ciclos
  Ciclos = DWT->CYCCNT;
  EnviaTextoNumero ( (uint8_t *) "4) Ciclos de fn multiplicacion con saturacion en C = ", (uint32_t) Ciclos);

  // Ahora en Assembler...
  // Primero asigno el mismo valor:
  for (i=0; i<N_MUESTRAS; i++) {
  	  senial16[i] = i;
  }

  // Contador de ciclos a cero
  DWT->CYCCNT = 0;

  // Vamos a multiplicar el contenido de senial16 por un valor algunas veces
  for (i=0; i<4; i++) {							// Ahora vamos a multiplicar su contenido por Resultado una cantidad de veces
	  asm_productoEscalar12(senial16, senial16, N_MUESTRAS, suma-1);
  }

  // Mido la cantidad de ciclos
  Ciclos = DWT->CYCCNT;
  EnviaTextoNumero ( (uint8_t *) "4) Ciclos de fn multiplicacion con saturacion en Assembler = ", (uint32_t) Ciclos);

  // **************************************************************************
  // 5) Promedio ventana
  zeros16(senial16, N_MUESTRAS);
  for (i=5; i<N_MUESTRAS-1; i+=14) {
	  senial16[i]=50;
	  senial16[i+1]=50;
  }
  asm_filtroVentana10(senial16, senial16b, N_MUESTRAS);	  // Probamos filtro ventana
  asm_invertir (senial16b, N_MUESTRAS);

  // **************************************************************************
  // 7) Prueba máximo de indice
  int32_t evaluame[10] = {1, 2, 3, 4, 3, 2, 1, 0, -1, -2};
  uint32_t indice;
  indice = asm_max(evaluame, 10);
  EnviaTextoNumero ( (uint8_t *) "7) Indice maximo es ", (uint32_t) indice);

  // **************************************************************************
  // 8) Prueba de submuestreo
  int32_t submuestreado[10];
  asm_downsampleM (evaluame, submuestreado, 10, 3);

  // **************************************************************************
  // Problema 11) Prueba de correlación
  int16_t vectorX[N_MUESTRAS], vectorY[N_MUESTRAS], corr1[N_MUESTRAS], corr2[N_MUESTRAS];

  for ( i=0; i<N_MUESTRAS; i++) {
	  vectorX[i] = 0;
	  vectorY[i] = 0;
	  if (i == 0) {
		  vectorY[i] = 1;
	  } else if (i < 5) {
		  vectorY[i] = vectorY[i-1] * (-3);
	  } else {
		  vectorY[i] = vectorY[i-1] / (-2);
	  }
	  if (i>=512) {
		  vectorX[i] = vectorY[i-512];
	  }
  }

  // Pruebo en Assembler sin SIMD
  DWT->CYCCNT = 0; 									// Contador de ciclos a cero
  corr (vectorX, vectorY, corr2, N_MUESTRAS);		// Ejecuto...
  Ciclos = DWT->CYCCNT;								// Mido la cantidad de ciclos
  EnviaTextoNumero ( (uint8_t *) "11) Ciclos de fn correlacion en C = ", (uint32_t) Ciclos);

  // Pruebo en Assembler sin SIMD
  DWT->CYCCNT = 0; 									// Contador de ciclos a cero
  asm_corr (vectorX, vectorY, corr1, N_MUESTRAS);	// Ejecuto...
  Ciclos = DWT->CYCCNT;								// Mido la cantidad de ciclos
  EnviaTextoNumero ( (uint8_t *) "11) Ciclos de fn correlacion en Assembler sin SIMD = ", (uint32_t) Ciclos);

  // Pruebo en Assembler sin SIMD
  DWT->CYCCNT = 0; 									// Contador de ciclos a cero
  asm_corr_SIMD (vectorX, vectorY, corr2, N_MUESTRAS);	// Ejecuto...
  Ciclos = DWT->CYCCNT;								// Mido la cantidad de ciclos
  EnviaTextoNumero ( (uint8_t *) "11) Ciclos de fn correlacion en Assembler con SIMD = ", (uint32_t) Ciclos);

  // **************************************************************************

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_BYPASS;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 4;
  RCC_OscInitStruct.PLL.PLLN = 168;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 7;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief USART3 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART3_UART_Init(void)
{

  /* USER CODE BEGIN USART3_Init 0 */

  /* USER CODE END USART3_Init 0 */

  /* USER CODE BEGIN USART3_Init 1 */

  /* USER CODE END USART3_Init 1 */
  huart3.Instance = USART3;
  huart3.Init.BaudRate = 115200;
  huart3.Init.WordLength = UART_WORDLENGTH_8B;
  huart3.Init.StopBits = UART_STOPBITS_1;
  huart3.Init.Parity = UART_PARITY_NONE;
  huart3.Init.Mode = UART_MODE_TX_RX;
  huart3.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart3.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart3) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART3_Init 2 */

  /* USER CODE END USART3_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOG_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOB, LD1_Pin|LD3_Pin|LD2_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(USB_PowerSwitchOn_GPIO_Port, USB_PowerSwitchOn_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : USER_Btn_Pin */
  GPIO_InitStruct.Pin = USER_Btn_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_RISING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(USER_Btn_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pins : RMII_MDC_Pin RMII_RXD0_Pin RMII_RXD1_Pin */
  GPIO_InitStruct.Pin = RMII_MDC_Pin|RMII_RXD0_Pin|RMII_RXD1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
  GPIO_InitStruct.Alternate = GPIO_AF11_ETH;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pins : RMII_REF_CLK_Pin RMII_MDIO_Pin RMII_CRS_DV_Pin */
  GPIO_InitStruct.Pin = RMII_REF_CLK_Pin|RMII_MDIO_Pin|RMII_CRS_DV_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
  GPIO_InitStruct.Alternate = GPIO_AF11_ETH;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pins : LD1_Pin LD3_Pin LD2_Pin */
  GPIO_InitStruct.Pin = LD1_Pin|LD3_Pin|LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  /*Configure GPIO pin : RMII_TXD1_Pin */
  GPIO_InitStruct.Pin = RMII_TXD1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
  GPIO_InitStruct.Alternate = GPIO_AF11_ETH;
  HAL_GPIO_Init(RMII_TXD1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : USB_PowerSwitchOn_Pin */
  GPIO_InitStruct.Pin = USB_PowerSwitchOn_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(USB_PowerSwitchOn_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : USB_OverCurrent_Pin */
  GPIO_InitStruct.Pin = USB_OverCurrent_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(USB_OverCurrent_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pins : USB_SOF_Pin USB_ID_Pin USB_DM_Pin USB_DP_Pin */
  GPIO_InitStruct.Pin = USB_SOF_Pin|USB_ID_Pin|USB_DM_Pin|USB_DP_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
  GPIO_InitStruct.Alternate = GPIO_AF10_OTG_FS;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pin : USB_VBUS_Pin */
  GPIO_InitStruct.Pin = USB_VBUS_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(USB_VBUS_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pins : RMII_TX_EN_Pin RMII_TXD0_Pin */
  GPIO_InitStruct.Pin = RMII_TX_EN_Pin|RMII_TXD0_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
  GPIO_InitStruct.Alternate = GPIO_AF11_ETH;
  HAL_GPIO_Init(GPIOG, &GPIO_InitStruct);

}

/* USER CODE BEGIN 4 */

/**
  * @Obtiene valor del registro de 32 bits del procesador llamado "control".
  * @param
  * @retval None
  */
static void PrivilegiosSVC (void)
{
    // Obtiene valor del registro de 32 bits del procesador llamado "control".
    // El registro guarda los siguientes estados:
    // bit 2: Uso de FPU en el contexto actual. Usado=1, no usado=0.
    // bit 1: Mapeo del stack pointer(sp). MSP=0, PSP=1.
    // bit 0: Modo de ejecucion en Thread. Privilegiado=0, No privilegiado=1.
    //        Recordar que este valor solo se usa en modo Thread. Las
    //        interrupciones siempre se ejecutan en modo Handler con total
    //        privilegio.
    uint32_t x = __get_CONTROL ();

    // Actividad de debug: Ver registro "control" y valor de variable "x".
    //__BKPT (0);

    x |= 1;
    // bit 0 a modo No privilegiado.
    __set_CONTROL (x);

    // En este punto se estaria ejecutando en modo No privilegiado.
    // Lectura del registro "control" para confirmar.
    x = __get_CONTROL ();

    // Actividad de debug: Ver registro "control" y valor de variable "x".
    //__BKPT (0);

    x &= ~1u;
    // Se intenta volver a modo Privilegiado (bit 0, valor 0).
    __set_CONTROL (x);

    // Confirma que esta operacion es ignorada por estar ejecutandose en modo
    // Thread no privilegiado.
    x = __get_CONTROL ();

    // Actividad de debug: Ver registro "control" y valor de variable "x".
    //__BKPT (0);

    // En este punto, ejecutando en modo Thread no privilegiado, la unica forma
    // de volver a modo privilegiado o de realizar cualquier cambio que requiera
    // modo privilegiado, es pidiendo ese servicio a un hipotetico sistema
    // opertivo de tiempo real.
    // Para esto se invoca por software a la interrupcion SVC (Supervisor Call)
    // utilizando la instruccion "svc".
    // No hay intrinsics para realizar esta tarea. Para utilizar la instruccion
    // es necesario implementar una funcion en assembler. Ver el archivo
    // asm_func.S.
    asm_svc ();

    // El sistema operativo (el handler de SVC) deberia haber devuelto el modo
    // de ejecucion de Thread a privilegiado (bit 0 en valor 0).
    x = __get_CONTROL ();

    // Fin del ejemplo de SVC
}

/**
  * @brief Inicializa un vector con zeros
  * @param
  * @retval None
  */
void zeros(uint32_t * vector, uint32_t longitud)
{
	if (vector == NULL) Error_Handler();
	for (uint32_t i=0; i<longitud; i++) {
		vector[i] = 0;
	}
}

/**
  * @brief Inicializa un vector con zeros
  * @param
  * @retval None
  */
void zeros16(uint16_t * vector, uint32_t longitud)
{
	if (vector == NULL) Error_Handler();
	for (uint32_t i=0; i<longitud; i++) {
		vector[i] = 0;
	}
}

/**
  * @brief Inicializa un vector con unos
  * @param
  * @retval None
  */
void ones(uint32_t * vector, uint32_t longitud)
{
	if (vector == NULL) Error_Handler();
	for (uint32_t i=0; i<longitud; i++) {
		vector[i] = 1;
	}
}

/**
  * @brief   Multiplica los elements de un vector
  * @param
  * @retval  None
  * @comment No analiza caso de desborde.
  */
void productoEscalar32(uint32_t * vectorIn, uint32_t * vectorOut, uint32_t longitud, uint32_t escalar)
{
	if (vectorIn == NULL || vectorOut == NULL) Error_Handler();
	for (uint32_t i=0; i<longitud; i++) {
		vectorOut[i] = vectorIn[i] * escalar;
	}
}

/**
  * @brief   Multiplica los elementos de un vector de uint16_t
  * @param
  * @retval  None
  * @comment No analiza caso de desborde.
  *
  */
void productoEscalar16(uint16_t * vectorIn, uint16_t * vectorOut, uint32_t longitud, uint16_t escalar)
{
	if (vectorIn == NULL || vectorOut == NULL) Error_Handler();
	for (uint32_t i=0; i<longitud; i++) {
		vectorOut[i] = vectorIn[i] * escalar;
	}
}

/**
  * @brief   Multiplica los elementos de un vector de uint16_t saturando en 12 bits.
  * @param
  * @retval  None
  * @comment Satura los valores.
  */
void productoEscalar12(uint16_t * vectorIn, uint16_t * vectorOut, uint32_t longitud, uint16_t escalar)
{
	uint32_t Out;
	if (vectorIn == NULL || vectorOut == NULL) Error_Handler();
	for (uint32_t i=0; i<longitud; i++) {
		Out = (uint32_t) vectorIn[i] * (uint32_t) escalar;
		vectorOut[i] = Out > 0xFFF ? 0xFFF : (uint16_t) Out;
	}
}

/**
  * @brief   Filtro ventana 11
  * @param
  * @retval  None
  * @comment
  */
void filtroVentana10(uint16_t * vectorIn, uint16_t * vectorOut, uint32_t longitud)
{
	const int16_t Lateral = 10/2;	// Para una ventana de 10, tomo 5 de cada lado
	if (vectorIn == NULL || vectorOut == NULL) Error_Handler();	// Algo alguna verificación...
	if (longitud < Lateral) Error_Handler();
	uint32_t i, j, min, max, ventana, prom;

	for (i=0; i<longitud; i++) {
		// min y max son los indices desde donde debe promediar, incluidos
		min = Lateral>i ? 0 : i-Lateral;
		max = (i+1+Lateral)>longitud ? (longitud-1) : i+Lateral;
		ventana = max-min+1;
		prom = 0;

		for (j = min ; j <= max; j++) {
			prom += vectorIn[j];
		}
		vectorOut[i] = prom / ventana;
	}
}

/**
  * @brief   Empaquetado
  * @param
  * @retval  None
  * @comment
  */
void pack32to16 (int32_t * vectorIn, int16_t *vectorOut, uint32_t longitud)
{
	if (vectorIn == NULL || vectorOut == NULL) Error_Handler();
	for (uint32_t i=0; i<longitud; i++) {
		vectorOut[i] = vectorIn[i]>>16;
	}
}

void corr (int16_t * vectorX, int16_t * vectorY, int16_t * vectorCorr, uint32_t longitud)
{
	uint32_t Suma = 0;
	for (uint32_t i=0; i<longitud; i++) {
		for (uint32_t j=i; j<longitud; j++) {
			Suma += vectorY[j-i]*vectorX[i];
		}
		vectorCorr[i] = Suma;
		Suma = 0;
	}
}



void EnviaTextoNumero ( uint8_t * Texto, uint32_t Numero)
{
	uint8_t NumeroEnTexto[20];
	itoa ((int) Numero, (char *) NumeroEnTexto, (int) 10);
	uint32_t Largo = strlen( (char *) Texto);

	// Primero transmito el texto:
	HAL_UART_Transmit(&huart3, (uint8_t *) Texto, Largo, 0x04FF);

	// Luego el número:
	Largo = strlen( (char * ) NumeroEnTexto);
	HAL_UART_Transmit(&huart3, (uint8_t *) NumeroEnTexto, Largo, 0x04FF);

	// Hago return + line feed
	HAL_UART_Transmit(&huart3, (uint8_t *) "\n\r", 2, 0x04FF);

}

void EnviaTexto ( uint8_t * Texto)
{
	uint32_t Largo = strlen( (char *) Texto);

	// Primero transmito el texto:
	HAL_UART_Transmit(&huart3, (uint8_t *) Texto, Largo, 0x04FF);

	// Hago return + line feed
	HAL_UART_Transmit(&huart3, (uint8_t *) "\n\r", 2, 0x04FF);

}

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}




#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
