I first completed the Nand2Tetris course in.. 2012? 2014? A long time ago. I'm revisiting it again in 2022, because why not? I never get this close to hardware in my cloud engineering jobs. It's good to get back to basics. :)

Course site: https://www.nand2tetris.org/
Mac installation notes: https://drive.google.com/file/d/1QDYIvriWBS_ARntfmZ5E856OEPpE4j1F/view

project 01

- I cheated on the first mux. Had no idea how to do this after an hour thinking about it. Learned that there's two ways to do it - with a NOT and three NANDS, or a NOT, two ANDs, and an OR. I wonder if there's an electrical engineering reason to do one vs the other.

- I made the DMux4Way and DMux8Way with AND gates rather than just chaining together DMux gates. Dunno why that didn't occur to me. I actually made an And3Way to facilitate this lol.

project 02

- Man the full adder took me way longer than it should have lol.

- I built the Inc16 with a Not-Or (to get an alwasy 1 value) and a bunch of half adders. Then I learned about `true`. Oof.

- Wow the ALU was fun! I misunderstood how the HDL worked again, though. I built an Or16Way and a Sig (return the signing bit) gate because I didn't know how to subscript the output of intermediate gates. After finishing my work, I found [this person's](https://github.com/xctom/Nand2Tetris/blob/master/projects/02/ALU.hdl) solution which does the subscripting I tried to do in an incorrect way. TIL!

project 03

- This was a straightforward chapter. Had to think a bit about how the counter worked and which control bits had precedence, but other than that they were all obvious implementations. :)

project 04
- Okay, on reflection, I wonder if I never made it this far the first time I tried this course. That was _hard_.
