# CombinationLock
A classic spinning combination lock represented within a Vivado project using VHDL and a Nexys A7 FPGA.

- - -

The password is currently hardcoded to be `420` 

Once your Nexys A7 is programmed:

<img width="317" alt="Screenshot 2025-05-07 at 8 03 58 PM" src="https://github.com/user-attachments/assets/4502603a-8acd-4da5-b78b-218b85461fdf" />

Use `BTNL` and `BTNR` to scroll between digits in a cyclical fashion like you would with a mechanical combo lock:

<img width="226" alt="Screenshot 2025-05-07 at 8 05 50 PM" src="https://github.com/user-attachments/assets/5c08e718-55e0-4ce7-88c2-b183021f3407" />

There are a few key differences between how a real life combo lock and this VHDL implementation work. These are best explained by first explaining how you unlock a real one.

### How to unlock a real one:
>1. Spin the wheel at least 3 full rotations to the right to "clear" it
>2. Spin the wheel to the right to your first digit, in our case: `4`
>3. Spin the wheel to the left PAST your second digit, and all the way back around to it by continuing to go left: `2`
>4. Spin the wheel to the right directly to your third digit, be careful not to go past it: `0`
>5. You've entered `420` and can now pull the lock open

### Notable differences:
>1. Our VHDL lock only has digits 0-9
>2. You press `BTNC` to clear and reset the VHDL lock instead of cycling all the way to the right 3 times (Who wants to press a button 30 times to reset)
>3. `BTNC` can only be used to clear the input once a full sequence has been attempted and the board displays that you have failed to unlock it. You don't know if a real life lock is unlocked until you fully enter the code and then try to pull and open it

### How to unlock the VHDL lock:
>1. The board should display a 0 on the 7-segment display furthest to the right upon programming/reset
>2. Press `BTNR` to go right until you reach the first digit. To enter the digit into your attempted password sequence, press `BTNC`. In our case, we want to enter `4`
>3. Press `BTNL` to go left until you go PAST your second digit, and all the way back around to it by continuing to go left. Again, use `BTNC` to enter: `2`
>4. Press `BTNR` to go right directly to your third digit, be careful not to go past it. Enter with `BTNC`: `0`
>5. You've entered `420`. When three digits have been submitted via `BTNC`, the program will automatically attempt to unlock it.

- - -

  If the board displays this symbol:

<img width="127" alt="Screenshot 2025-05-07 at 8 18 54 PM" src="https://github.com/user-attachments/assets/3d41215b-6bb3-4677-859c-df173e0cd3fc" />

  then you have failed miserably. This is the `ERROR` symbol. Press `BTNU` to reset.

  If the board displays this symbol:
  
<img width="128" alt="Screenshot 2025-05-07 at 8 19 59 PM" src="https://github.com/user-attachments/assets/fe23af28-c088-4bad-9c31-59a5c417de41" />

  then your family is cursed for five generations. This is the `UNLOCKED` symbol.

<img width="536" alt="Screenshot 2025-05-07 at 8 21 40 PM" src="https://github.com/user-attachments/assets/4f71e015-aba8-47c5-8802-dce4cf6fe611" />

