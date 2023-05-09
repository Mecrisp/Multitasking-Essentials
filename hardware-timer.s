
# Hardware-specific parts for the GD32VF103

# Required for the example to work on the microcontroller, but
# not required to understand the essentials of multitasking.

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
init_timer_1khz:
# -----------------------------------------------------------------------------

  # Initialise special registers for interrupt handling

  # Disable interrupts before attemping to change the interrupt mode
  csrrci zero, mstatus, 8    # MSTATUS: Clear Machine Interrupt Enable Bit

  li x15, 3                  #        Set interrupt mode to ECLIC mode.
  csrrw zero, 0x305, x15     # MTVEC: Store address of exception handler (none) and ECLIC mode in CSR mtvec.

  # Non-vectored interrupt setting
  la x15, pause              #         Make sure address is 4-aligned.
  ori x15, x15, 1            #         Set LSB to 1: Indicates that this register (mtvt2)
  csrrw zero, 0x7EC, x15     # MTVT2:  contains the address of non-vectored interrupts.

  # Timer initialisation

  li  x14, 0x7F020100  # Enabled, rising edge, level 127
  lui x15, 0xD2001     # VECTORCONFIG_BASE: Starting address of 87*4 ECLIC configuration registers
  sw  x14, 7*4(x15)    # Vector 7: Timer

  li  x14, 1
  lui x15, 0xD1001     # Timer mstop
  sw  x14, -8 (x15)

  lui x15, 0xD1000     # Clear mtime and mtimecmp
  sw  zero, 0x0 (x15)
  sw  zero, 0x4 (x15)
  sw  zero, 0x8 (x15)
  sw  zero, 0xC (x15)

  lui x15, 0xD1001     # Release Timer mstop
  sw  zero, -8 (x15)

  csrrsi zero, mstatus, 8 # Enable interrupts --> Interrupt will trigger immediately

  ret

# -----------------------------------------------------------------------------
next_interrupt_1khz:
# -----------------------------------------------------------------------------

  # Prepare next interrupt by adjusting 64 bit value mtimecmp

  lui x12, 0xD1000     # Fetch mtimecmp in x13:x11
  lw  x11, 0x8 (x12)
  lw  x13, 0xC (x12)

  li x15, CYCLES_MS/4  # How many cycles? This timer uses a /4 clock --> 1 kHz task switch frequency

  add  x11, x11, x15   # Add to 64 bit value, with carry
  sltu x14, x11, x15
  add  x13, x13, x14

  li  x14, -1          # See Volume II: RISC-V Privileged Architectures V1.10, 3.1.15: Machine Timer Registers
  sw  x14, 0x8(x12)    # Set low  part to maximum to avoid glitching
  sw  x13, 0xC(x12)    # Set high part
  sw  x11, 0x8(x12)    # Set low  part

  lui x12, 0xD2001     # VECTORCONFIG_BASE: Starting address of 87*4 ECLIC configuration registers
  sb  zero, 7*4(x12)   # Clear pending for vector 7: Timer

  ret
