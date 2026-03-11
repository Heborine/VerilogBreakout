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
    output wire [1:0] vgaBlue,
    // 7-Segment Score Display
    output wire [6:0] seg,
    output wire [3:0] an
);

    wire dclk; // 25MHz clock
    clock_divider clk_div_instantiate (
        .clk (clk),
        .rst (rst),
        .dclk (dclk)
    );

    wire [9:0] pixelX;
    wire [9:0] pixelY;
    wire active_video;
    wire hbp;
    wire vbp;

    vga640x480 vga_instantiate (
        .dclk(dclk),
        .clr(rst),
        .hsync(hsync),
        .vsync(vsync),
        .red (), //unused
        .green (), //unused
        .blue (), //unused
        .pixelX(pixelX),
        .pixelY(pixelY),
        .valid_drawing_region(active_video),
        .hbp(hbp),
        .vbp(vbp)
    );

    wire [49:0] activeBricks;
    wire [9:0] playerX, playerY, playerWidth, playerHeight, ballX, ballY, ballSz, brickWidth, brickHeight, brickPadding, brickXoffset, brickYoffset, numRows, numCols;    wire gameOver;
    Game_Logic game (
        .clk(clk),
        .rst(rst),
        .btnL(btnL),
        .btnR(btnR),
        .activeBricks(activeBricks),
        .brickWidth(brickWidth),
        .brickHeight(brickHeight),
        .brickPadding(brickPadding),
        .numRows(numRows),
        .numCols(numCols),
        .brickXoffset(brickXoffset),
        .brickYoffset(brickYoffset),
        .ballXcoord(ballX),
        .ballYcoord(ballY),
        .ballSz(ballSz),
        .playerXcoord(playerX),
        .playerYcoord(playerY),
        .paddleWidth(playerWidth),
        .paddleHeight(playerHeight),
        .gameOver(gameOver),
        .seg(seg),
        .an(an)
    );

    wire paddle_on;
    wire [2:0] playerRed, playerGreen;
    wire [1:0] playerBlue;

    display_shape paddle_render (
        .enabled(active_video),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .lowerX(playerX),
        .lowerY(playerY),
        .upperX(playerX + playerWidth),
        .upperY(playerY + playerHeight),
        .redVal(3'b111), // White paddle
        .greenVal(3'b111),
        .blueVal(2'b11),
        .inShape(paddle_on),
        .redOut(playerRed),
        .greenOut(playerGreen),
        .blueOut(playerBlue)
    );

    wire [2:0] ballRed, ballGreen;
    wire [1:0] ballBlue;

    display_shape ball(
        .enabled(1'b1),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .lowerX(ballX),
        .lowerY(ballY),
        .upperX(ballX + ballSz),
        .upperY(ballY + ballSz),
        .redVal(3'b111), // White paddle
        .greenVal(3'b111),
        .blueVal(2'b11),
        .inShape(1'b1),
        .redOut(ballRed),
        .greenOut(ballGreen),
        .blueOut(ballBlue)
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
                    .lowerX(10'd60 + col * (brickWidth + brickPadding)),
                    .lowerY(10'd40 + row * (brickHeight + brickPadding)),
                    .upperX(10'd60 + col * (brickWidth + brickPadding) + brickWidth),
                    .upperY(10'd40 + row * (brickHeight + brickPadding) + brickHeight),
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