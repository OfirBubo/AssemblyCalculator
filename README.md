# Calculator with PIC16F877 Microcontroller 🧮

## Description

This project is a basic program written in Assembly for the PIC16F877 microcontroller. The program is designed to perform various arithmetic operations (addition, subtraction, multiplication, division, power, and bit manipulation) based on inputs received from a keyboard. The results of the operations are displayed on an LCD screen. The program demonstrates fundamental concepts of embedded systems programming, including I/O configuration, interrupt handling, and arithmetic operations.

---

## Hardware Requirements

- **PIC16F877 Microcontroller**

- **16x2 LCD Display**

- **Keypad** (for user inputs)

- **Pull-up Resistors** for PORT

- **Power Supply** (5V regulated)

---

## Program Features

1. **Arithmetic Operations**:
   - Subtraction (A - B)
   - Multiplication (A \* B)
   - Division (A / B)
   - Exponentiation (A^B)
2. **Bitwise Operations**:
   - Count of 1s in Operand A
   - Count of 0s in Operand B
   - Count of pairs of 1s in Operand B
3. **User Input**:
   - Operands (A and B) and commands are entered via a keypad.
4. **Output Display**:
   - Operands (A, B, Command), and Result are displayed on an LCD screen.
5. **Error Handling**:
   - Display error messages for invalid operations (e.g., division by zero).

---

## Memory Layout

The program uses specific memory locations for storing variables:

- `OpA`: Stores Operand A (Address: 0x30)
- `OpB`: Stores Operand B (Address: 0x40)
- `CMD`: Stores the command/operation to be performed (Address: 0x50)
- `RESULT`: Stores the result of the operation (Address: 0x60)
- `Variable`: General-purpose temporary variable (Address: 0x70)

---

## How It Works

1. **Initialization**:
   - Configure ports for input and output.
   - Enable pull-up resistors on PORT for keypad input.
   - Clear all variables and registers.
2. **User Input**:
   - The program waits for the user to input Operand A, Operand B, and the desired command via the keypad.
   - Operands and commands are stored in their respective memory locations.
3. **Execution**:
   - Based on the command, the corresponding subroutine is executed.
   - Results are stored in the `RESULT` register.
4. **Display**:
   - The LCD displays the values of Operands A and B, the Command, and the Result.
5. **Error Handling**:
   - If an invalid operation (e.g., division by zero) is attempted, an error message is displayed on the LCD.
6. **Repeat**:
   - The program loops back to wait for new inputs.

---

## Subroutines

### Arithmetic Operations

- **SubAfromB**: Subtracts Operand A from Operand B.
- **AmultB**: Multiplies Operand A with Operand B.
- **AdivideB**: Divides Operand A by Operand B (handles division by zero).
- **ApowerB**: Raises Operand A to the power of Operand B.

### Bitwise Operations

- **OnesCounter**: Counts the number of 1s in Operand A.
- **firstBitB**: Counts the number of 0s in Operand B.
- **PirsOfOnes**: Counts pairs of 1s in Operand B.

### User Input

- **input\_letter**: Handles letter inputs (A, B, or C) to identify which operand or command is being entered.
- **input\_digit**: Handles digit inputs from the keypad.
- **input\_iterals**: Inputs four digits and stores them in the FSR-pointed register.

### Display

- **display\_variabls**: Updates the LCD with the current values of Operands, Command, and Result.

---

## Configuration Bits

- **Oscillator**: High-Speed Crystal (HS)
- **Watchdog Timer**: Disabled
- **Power-Up Timer**: Disabled
- **Low-Voltage Programming**: Disabled
- **Code Protection**: Off

---

## Keypad Commands

Commands are entered as binary representations:

- `000`: Reset to input stage
- `0010`: Subtract A - B
- `0100`: Multiply A \* B
- `0110`: Divide A / B
- `1000`: Raise A to the power of B
- `1010`: Count 1 bits in A
- `1100`: Count 0 bits in B
- `1011`: Count pairs of 1s in B

---

## Notes

- Ensure the LCD is connected correctly to the microcontroller with appropriate data and control lines.
- Keypad connections should align with PORT configurations.
- Pull-up resistors on PORT are required for proper keypad functionality.
- Handle invalid inputs gracefully by displaying error messages on the LCD.

---

## License

This project is free to use and modify for educational purposes. For commercial use, please contact the author.

---

## Author

OfirD.

---

## Future Enhancements

1. Add support for floating-point arithmetic operations.
2. Implement memory save and recall functionality for operands and results.
3. Expand the program to support hexadecimal inputs and outputs.
4. Introduce a menu-based system for easier navigation through operations.
5. Add real-time clock (RTC) integration for time-stamping operations.

