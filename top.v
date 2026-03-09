module top (
    input wire clk, // 100 MHz (Basys3)
    // buttons
    input wire rst, // active-high reset - center
    input wire btnL, // left
    input wire btnR, // right
    // VGA
    output wire hsync,
    output wire vsync,
    output wire [2:0] vgaRed,
    output wire [2:0] vgaGreen,
    output wire [1:0] vgaBlue
    // 7-Segment Score Display
    output wire [6:0] seg,
    output wire [3:0] an
);

    wire dclk; // 25MHz clock
    clock_divider clk_div_instantiate (
        .clk (clk),
        .rst (rst),
        .dclk (clk)
    );

    wire [9:0] pixelX;
    wire [9:0] pixelY;
    wire active_video;

    vga640x480 vga_instantiate (
        .dclk(dclk),
        .clr(rst),
        .hsync(hsync),
        .vsync(vsync),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .valid_drawing_region(active_video)
    );

    wire [9:0] playerX, playerY, pWidth, pHeight;
    Game_Logic game (
        .clk(clk),
        .rst(rst),
        .btnL(btnL),
        .btnR(btnR),
        .playerXcoord(playerX),
        .playerYcoord(playerY),
        .paddleWidth(pWidth),
        .paddleHeight(pHeight),
        .seg(seg),
        .an(an)
    );

    wire paddle_on;
    wire [2:0] pRed, pGreen;
    wire [1:0] pBlue;

    display_shape paddle_render (
        .enabled(active_video),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .lowerX(playerX),
        .lowerY(playerY),
        .upperX(playerX + pWidth),
        .upperY(playerY + pHeight),
        .redVal(3'b111), // White paddle
        .greenVal(3'b111),
        .blueVal(2'b11),
        .inShape(paddle_on),
        .redOut(pRed),
        .greenOut(pGreen),
        .blueOut(pBlue)
    );

    // Final VGA assignment
    assign vgaRed   = paddle_on ? pRed   : 3'b000;
    assign vgaGreen = paddle_on ? pGreen : 3'b000;
    assign vgaBlue  = paddle_on ? pBlue  : 2'b00;

endmodule