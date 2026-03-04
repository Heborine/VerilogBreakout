module top (
    input  wire clk,      // 100 MHz (Basys3)
    input  wire rst,      // active-high reset
    output wire hsync,
    output wire vsync,
    output wire [2:0] vgaRed,
    output wire [2:0] vgaGreen,
    output wire [1:0] vgaBlue
);

    // 100 MHz -> 25 MHz pixel clock
    reg [1:0] clk_div;
    always @(posedge clk or posedge rst) begin
        if (rst) clk_div <= 2'b00;
        else     clk_div <= clk_div + 2'b01;
    end
    wire dclk = clk_div[1];

    wire [9:0] pixelX;
    wire [9:0] pixelY;
    wire       active_video;

    // VGA timing generator
    vga640x480 vga0 (
        .dclk(dclk),
        .clr(rst),
        .hsync(hsync),
        .vsync(vsync),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .valid_drawing_region(active_video)
    );

    // Rectangle: x=[200,300), y=[150,220)
    wire rect_on;
    assign rect_on = active_video &&
                     (pixelX >= 10'd200) && (pixelX < 10'd300) &&
                     (pixelY >= 10'd150) && (pixelY < 10'd220);

    // White rectangle on black background
    assign vgaRed   = rect_on ? 3'b111 : 3'b000;
    assign vgaGreen = rect_on ? 3'b111 : 3'b000;
    assign vgaBlue  = rect_on ? 2'b11  : 2'b00;

endmodule