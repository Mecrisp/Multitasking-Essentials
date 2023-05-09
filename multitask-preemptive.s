
# ------------------------------------------------------------------------------
#   Preemptive multitasking essentials
#   Matthias Koch, 2023
# ------------------------------------------------------------------------------

.option rvc

# ------------------------------------------------------------------------------
#   A few useful macro definitions
# ------------------------------------------------------------------------------

.macro push register
  addi x2, x2, -4
  sw \register, 0(x2)
.endm

.macro pop register
  lw \register, 0(x2)
  addi x2, x2, 4
.endm

# ------------------------------------------------------------------------------
.text # Flash memory, execution begins here
# ------------------------------------------------------------------------------
  j Reset

# Include a few hardware specific parts.
# Have a look if you like, but these are not necessary to understand the
# essentials of multitasking.

.include "hardware-leds.s"
.include "hardware-timer.s"

# ------------------------------------------------------------------------------
delay_cycles: # Waits at least the number of cycles specified in x10.
# ------------------------------------------------------------------------------
  push x1
  rdcycle x15                  # Get start time

1:rdcycle x14                  # Get current time
  sub x14, x14, x15            # Elapsed time, handles overflow gracefully
  bltu x14, x10, 1b

  pop x1
  ret

# ------------------------------------------------------------------------------
#   Definition of the task area memory
# ------------------------------------------------------------------------------

/*
  Internal stucture of task memory:
    0: Pointer to next task
    4: Task currently active
    8: Saved stack pointer
   12: Entry/return address for execution

    ... Add more task specific variables as desired ...

    Growing from the end: Stack
*/

.equ taskareasize, 512

.equ offset_nexttask,   0
.equ offset_taskactive, 4
.equ offset_savedstack, 8
.equ offset_returnaddr, 12

# ------------------------------------------------------------------------------
.p2align 2 # Interrupt handler needs to be on a 4-even address
pause: # Switch tasks here.
# ------------------------------------------------------------------------------

  # Push all registers less the stack pointer to the stack

  addi x2, x2, -30*4
  sw  x1, 29*4(x2)
  sw  x3, 28*4(x2)
  sw  x4, 27*4(x2)
  sw  x5, 26*4(x2)
  sw  x6, 25*4(x2)
  sw  x7, 24*4(x2)
  sw  x8, 23*4(x2)
  sw  x9, 22*4(x2)
  sw x10, 21*4(x2)
  sw x11, 20*4(x2)
  sw x12, 19*4(x2)
  sw x13, 18*4(x2)
  sw x14, 17*4(x2)
  sw x15, 16*4(x2)
  sw x16, 15*4(x2)
  sw x17, 14*4(x2)
  sw x18, 13*4(x2)
  sw x19, 12*4(x2)
  sw x20, 11*4(x2)
  sw x21, 10*4(x2)
  sw x22,  9*4(x2)
  sw x23,  8*4(x2)
  sw x24,  7*4(x2)
  sw x25,  6*4(x2)
  sw x26,  5*4(x2)
  sw x27,  4*4(x2)
  sw x28,  3*4(x2)
  sw x29,  2*4(x2)
  sw x30,  1*4(x2)
  sw x31,  0*4(x2)

  # All registers are saved now, so we can use the registers freely.

  # Prepare the next interrupt.
  # With a periodic timer interrupt, this could be omitted.
  call next_interrupt_1khz

  la x13, current_task           # Variable pointing to the currently active task
  lw x14, 0(x13)                 # Get pointer to the currently active task
  sw x2, offset_savedstack(x14)  # Save stack pointer into task structure

  csrrs x15, mepc, zero          # Save the return address into
  sw x15, offset_returnaddr(x14) # the task structure

  # All context saved. Now time for selecting another task to run.
  # This is a very simple round-robin scheduler:

next_task:
  lw x14, offset_nexttask(x14)     # Get pointer to next task
  lw x15, offset_taskactive(x14)   # Check if task is active
  beq x15, zero, next_task         # If none of the tasks is active, this becomes an endless loop.

  # Found next task to execute.
  sw x14, 0(x13)                 # Take a note of the soon-active new task.

  # Restore context to activate the new task

  lw x15, offset_returnaddr(x14) # Get return address from the task structure
  csrrw x0, mepc, x15

  lw x2, offset_savedstack(x14)  # Get stack pointer from the task structure

  # Pop all registers less the stack pointer from the stack

  lw x31,  0*4(x2)
  lw x30,  1*4(x2)
  lw x29,  2*4(x2)
  lw x28,  3*4(x2)
  lw x27,  4*4(x2)
  lw x26,  5*4(x2)
  lw x25,  6*4(x2)
  lw x24,  7*4(x2)
  lw x23,  8*4(x2)
  lw x22,  9*4(x2)
  lw x21, 10*4(x2)
  lw x20, 11*4(x2)
  lw x19, 12*4(x2)
  lw x18, 13*4(x2)
  lw x17, 14*4(x2)
  lw x16, 15*4(x2)
  lw x15, 16*4(x2)
  lw x14, 17*4(x2)
  lw x13, 18*4(x2)
  lw x12, 19*4(x2)
  lw x11, 20*4(x2)
  lw x10, 21*4(x2)
  lw  x9, 22*4(x2)
  lw  x8, 23*4(x2)
  lw  x7, 24*4(x2)
  lw  x6, 25*4(x2)
  lw  x5, 26*4(x2)
  lw  x4, 27*4(x2)
  lw  x3, 28*4(x2)
  lw  x1, 29*4(x2)
  addi x2, x2, 30*4

  mret # Interrupt handlers require a special return instruction that uses MEPC instead of x1.

# ------------------------------------------------------------------------------
preparetask: # x10: Task area  x11: Entry address x12: Active flag
# ------------------------------------------------------------------------------
  # In order to prepare the task area, we need to do a "context switch"
  # in reverse, so that the next task switch will launch the routine given.

  # One could politely clear the task area first here,
  # but it is not strictly necessary, and could be used for passing parameters.

  # Prepare stack pointer to hold x1 and x3 to x31.

  add x14, x10, taskareasize - 30*4
  sw x14, offset_savedstack(x10)

  # The initial stack for the next task will be empty after
  # "restoring" its registers.

  # Write the entry address into the field in the task structure which
  # will be put into MEPC before returning at the upcoming context switch.

  sw x11, offset_returnaddr(x10)

  # Set the task flag to either "active" or "inactive".
  # One could insert a task as "inactive", and activate it by a trigger,
  # for example in an interrupt handler later.

  sw x12, offset_taskactive(x10)

  # Insert the task into the ring of tasks.

  la x14, current_task
  lw x14, 0(x14)

  lw x15, offset_nexttask(x14) # Get the old next task of the currently active task
  sw x15, offset_nexttask(x10) # Save that one as the next task of the freshly prepared one
  sw x10, offset_nexttask(x14) # Insert the freshly prepared one into the ring to be executed next

  # The insertion in the ring structure isn't atomic,
  # so do not try to insert (or remove) a task in an interrupt handler.

  # Done. The new one will be run on the next context switch.
  ret

# ------------------------------------------------------------------------------
wake: # x10: Task area  Idle a specific task. IRQ safe.
# ------------------------------------------------------------------------------
  li x15, -1
  sw x15, offset_taskactive(x10)
  ret

# ------------------------------------------------------------------------------
idle: # x10: Task area  Wake a specific task. IRQ safe.
# ------------------------------------------------------------------------------
  sw zero, offset_taskactive(x10)
  ret

# ------------------------------------------------------------------------------
Reset: # First routine to run
# ------------------------------------------------------------------------------

  # Prepare stack pointer.
  # It can be everywhere, but for keeping the example tidy,
  # use a proper task area format for what will become the "boot task" also.

  la x2, boot_taskarea + taskareasize

  # Before one can enter multitasking, we need to create a task area entry
  # for the "boot task". This one is already running, so we cannot use preparetask
  # but we need to initialise the ring structure of the tasks:

  la x14, boot_taskarea          # The area of the boot task
  sw x14, offset_nexttask(x14)   # With only one task, close the ring by pointing back to itself.

  la x15, current_task
  sw x14, 0(x15)

# ------------------------------------------------------------------------------

  # Lets initialise the hardware and define
  # a few tasks to do something interesting:

  call init_leds

  la x10, blink_red_taskarea
  la x11, blink_red
  li x12, -1                     # Active
  call preparetask

  la x10, blink_green_taskarea
  la x11, blink_green
  li x12, -1                     # Active
  call preparetask

  la x10, blink_blue_taskarea
  la x11, blink_blue
  li x12, 0                      # Inactive
  call preparetask

  # Done! We have four tasks now, including the boot task.

# -----------------------------------------------------------------------------

  # Configure the timer to use "pause" as interrupt handler
  # to finally start multitasking.

  call init_timer_1khz

# -----------------------------------------------------------------------------

  # Let start blinking now. After 10 seconds, the blue LED joins.

  li x10, 10000 * CYCLES_MS
  call delay_cycles

  la x10, blink_blue_taskarea
  call wake

mainloop:

  # For this example, the boot task finished its work,
  # so it just waits for interrupts to happen.

  wfi
  j mainloop

# ------------------------------------------------------------------------------
blink_red: # No parameters, will be executed as separate task.
# ------------------------------------------------------------------------------

  li x10, 100 * CYCLES_MS
  call delay_cycles
  call red_on

  li x10, 220 * CYCLES_MS
  call delay_cycles
  call red_off

  j blink_red # Tasks must not return.

# ------------------------------------------------------------------------------
blink_green: # No parameters, will be executed as separate task.
# ------------------------------------------------------------------------------

  li x10, 200 * CYCLES_MS
  call delay_cycles
  call green_on

  li x10, 320 * CYCLES_MS
  call delay_cycles
  call green_off

  j blink_green # Tasks must not return.

# ------------------------------------------------------------------------------
blink_blue: # No parameters, will be executed as separate task.
# ------------------------------------------------------------------------------

  li x10, 300 * CYCLES_MS
  call delay_cycles
  call blue_on

  li x10, 540 * CYCLES_MS
  call delay_cycles
  call blue_off

  j blink_blue # Tasks must not return.

# ------------------------------------------------------------------------------
.bss #  RAM memory layout
# ------------------------------------------------------------------------------

boot_taskarea:
  .rept taskareasize
  .byte 0x00
  .endr

blink_red_taskarea:
  .rept taskareasize
  .byte 0x00
  .endr

blink_green_taskarea:
  .rept taskareasize
  .byte 0x00
  .endr

blink_blue_taskarea:
  .rept taskareasize
  .byte 0x00
  .endr

current_task:
  .word 0x00000000
