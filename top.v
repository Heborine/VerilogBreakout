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
    wire [49:0] activeBricks;
    wire [9:0] bWidth, bHeight;
    Game_Logic game (
        .clk(clk),
        .rst(rst),
        .btnL(btnL),
        .btnR(btnR),
        .activeBricks(activeBricks),
        .brickWidth(bWidth),
        .brickHeight(bHeight),
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

    integer i;
    wire [49:0] brick_hits;
    genvar row, col;
    generate
        for (row = 0; row < 5; row = row + 1) begin : row_loop
            for (col = 0; col < 10; col = col + 1) begin : col_loop
                display_shape brick_inst (
                    .enabled(active_video && activeBricks[row*10 + col]),
                    .pixelX(pixelX),
                    .pixelY(pixelY),
                    .lowerX(10'd60 + col * (bWidth + 2)),
                    .lowerY(10'd40 + row * (bHeight + 2)),
                    .upperX(10'd60 + col * (bWidth + 2) + bWidth),
                    .upperY(10'd40 + row * (bHeight + 2) + bHeight),
                    .redVal(3'b111),   // Red bricks
                    .greenVal(3'b000),
                    .blueVal(2'b00),
                    .inShape(brick_hits[row*10 + col])
                );
            end
        end
    endgenerate

    wire any_brick_on = |brick_hits;

    // Final VGA assignment
    assign vgaRed   = paddle_on ? 3'b111 : (any_brick_on ? 3'b111 : 3'b000);
    assign vgaGreen = paddle_on ? 3'b111 : 3'b000;
    assign vgaBlue  = paddle_on ? 2'b11  : 2'b00;

endmodule