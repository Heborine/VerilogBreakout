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

    // // Rectangle: x=[200,300), y=[150,220)
    // wire rect_on;
    // assign rect_on = active_video &&
    //                  (pixelX >= 10'd200) && (pixelX < 10'd300) &&
    //                  (pixelY >= 10'd150) && (pixelY < 10'd220);

    // // White rectangle on black background
    // assign vgaRed   = rect_on ? 3'b111 : 3'b000;
    // assign vgaGreen = rect_on ? 3'b111 : 3'b000;
    // assign vgaBlue  = rect_on ? 2'b11  : 2'b00;

endmodule