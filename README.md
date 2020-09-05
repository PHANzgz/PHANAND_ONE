# PHANAND_ONE
Documentation and details of the "ultimate" homemade CPU and 8bit computer with discrete logic.

![Demo GIF](./demo.gif)

## FAQ

### What is this?
It's a homemade 8bit computer and CPU, built for educational purposes.

### Why did you build this?
Since I was a child I've always wanted to understand how "machines" worked. Up until recently, how computers and microprocessors worked was a great mystery for me so when I came across  a [series of videos](https://www.youtube.com/watch?v=9PPrrSyubG0&ab_channel=BenEater) on youtube where they explain how one can do a simple 8bit computer with breadboards and starting from almost zero knowledge, I just needed to do it, so I followed the whole tutorial series. It wasn't enough; Although I made some changes to that version, I was still missing some kind of keyboard and a screen, so I decided to start my own 8bit homemade computer design from scratch, and what you see is what I came up with!

### What can it do?
I tried to design the computer so it would be capable of doing some neat things, considered its limitations. With keyboard and a screen you can virtually do anything, so I made a console-like program with a few instructions, like `print` something to screen or `peek` memory locations. This was quite a challenge, since I had to take care of "drawing" every single pixel to the screen. It has a bit of hardware to help it do that, but I can definitely be improved. It also has a SPI Bus, with some minor modifications so it's able to efficently communicate with a PlayStation 2 controller, or even two! So although I haven't made any games for this yet, it is definitely capable of running one.

### Why haven't you made any games?
For me, it was the reward of fully understanding a whole computer from the lowest level that motivated me. After months and countless hours spent designing, testing, building and finally programming it I realised I had already reached my goal: A console-like interface, where the user can enter some commands and the computer return an output based on the query. That's just mind blowing for me. If you add the fact that debugging this computer is ~~kind of~~~ a nightmare, I realised I was better off taking on new projects and learning new things. And that's what I'm doing.

### What are the specs/features?
- 2MHz clockrate
- 32kB RAM + 32kB ROM
- Built-in VGA controller: 64 colors (6bit RGB) 160x120@60Hz 
- PS/2 keyboard interface
- SPI interface, with some changes to work with PS2 controllers
- More than 200 LEDs to see program flow and debugging when running on stepped mode or low clockrates.

### But how did you do it?
I tried to read books and articles about computer architecture, but [almost](https://www.amazon.com/Digital-computer-electronics-Albert-Malvino/dp/0070398615) none of them really explained how to a CPU worked at logic-gate level. Maybe I wasn't looking for the right keywords but I finally decided to get my hands dirty: I first tried to lay an architecture overview of how I wanted things to work and communicate, separating everything into modules. After I knew _what_ I wanted, I started with a simple version of each module on breadboard, iterating over it to get the exact functionality I wanted, trying new things and integrated circuits. Once I had finally come up with the functionality or proof of concept I wanted, I would drew the schematics of the full-sized module(e.g. making all of the address registers, since all were similar). After that, it was just a matter of carefully revising every connection over and over(I messed up anyway of course, but that's learning 101) until I knew I had it right.

### Do you think it is a good design?
Yes and no. I started with zero knowledge on computer architecture and average one of electronics, so I did what I could, in terms of design. I didn't really understand some of the core concepts of the topic at hand, so although I took into considerations several guidelines and caveats, I did it my way. And honestly, I'm really proud of that, I succesfully reached my goal with my own not so professional design. I think thanks to that I learned so much along the way. In that way, it is a  _darn_ good design. Of course, now that I've developed a solid understanding of the topic, I wish I had done some things differently either to improve performance or add functionality.

### ... (TODO)
