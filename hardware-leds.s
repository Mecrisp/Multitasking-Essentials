
# Hardware-specific parts for the GD32VF103

# Required for the example to work on the microcontroller, but
# not required to understand the essentials of multitasking.

.equ CYCLES_MS, 8000 # For 8 MHz clock frequency

# -----------------------------------------------------------------------------
#   Labels for a few hardware ports
# -----------------------------------------------------------------------------

  .equ GPIOA_BASE, 0x40010800
  .equ GPIOB_BASE, 0x40010C00
  .equ GPIOC_BASE, 0x40011000
  .equ GPIOD_BASE, 0x40011400
  .equ GPIOE_BASE, 0x40011800

  .equ GPIOA_CRL,  GPIOA_BASE + 0x00
  .equ GPIOA_CRH,  GPIOA_BASE + 0x04
  .equ GPIOA_IDR,  GPIOA_BASE + 0x08
  .equ GPIOA_ODR,  GPIOA_BASE + 0x0C
  .equ GPIOA_BSRR, GPIOA_BASE + 0x10
  .equ GPIOA_BRR,  GPIOA_BASE + 0x14
  .equ GPIOA_LCKR, GPIOA_BASE + 0x18

  .equ GPIOC_CRL,  GPIOC_BASE + 0x00
  .equ GPIOC_CRH,  GPIOC_BASE + 0x04
  .equ GPIOC_IDR,  GPIOC_BASE + 0x08
  .equ GPIOC_ODR,  GPIOC_BASE + 0x0C
  .equ GPIOC_BSRR, GPIOC_BASE + 0x10
  .equ GPIOC_BRR,  GPIOC_BASE + 0x14
  .equ GPIOC_LCKR, GPIOC_BASE + 0x18

  .equ RCU_BASE, 0x40021000
  .equ RCU_APB2EN, RCU_BASE + 0x18
  .equ RCU_APB1EN, RCU_BASE + 0x1C

# -----------------------------------------------------------------------------
init_leds:
# -----------------------------------------------------------------------------

  li x14, RCU_APB2EN
  li x15, -1            # Enable clock to all GPIO ports, among other peripherals
  sw x15, 0(x14)

  li x14, GPIOA_ODR
  li x15, (1<<2)|(1<<1) # Set PA1 and PA2 high (LEDs are active low on this board)
  sw x15, 0(x14)

  li x14, GPIOC_ODR
  li x15, (1<<13)       # Set PC13 high
  sw x15, 0(x14)

  li x14, GPIOA_CRL     # Set PA1 and PA2 as output
  li x15, 0x44444224
  sw x15, 0(x14)

  li x14, GPIOC_CRH     # Set PC13 as output
  li x15, 0x44244444
  sw x15, 0(x14)

  ret

# -----------------------------------------------------------------------------
red_on:
# -----------------------------------------------------------------------------
  li x14, GPIOC_BSRR
  li x15, (1<<13) << 16
  sw x15, 0(x14)
  ret

# -----------------------------------------------------------------------------
red_off:
# -----------------------------------------------------------------------------
  li x14, GPIOC_BSRR
  li x15, (1<<13)
  sw x15, 0(x14)
  ret

# -----------------------------------------------------------------------------
green_on:
# -----------------------------------------------------------------------------
  li x14, GPIOA_BSRR
  li x15, (1<<1) << 16
  sw x15, 0(x14)
  ret

# -----------------------------------------------------------------------------
green_off:
# -----------------------------------------------------------------------------
  li x14, GPIOA_BSRR
  li x15, (1<<1)
  sw x15, 0(x14)
  ret

# -----------------------------------------------------------------------------
blue_on:
# -----------------------------------------------------------------------------
  li x14, GPIOA_BSRR
  li x15, (1<<2) << 16
  sw x15, 0(x14)
  ret

# -----------------------------------------------------------------------------
blue_off:
# -----------------------------------------------------------------------------
  li x14, GPIOA_BSRR
  li x15, (1<<2)
  sw x15, 0(x14)
  ret



