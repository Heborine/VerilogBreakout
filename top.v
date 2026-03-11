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
        .valid_drawing_region(active_video)
    );

    localparam HBP = 144;
    localparam VBP = 31;

    wire [9:0] screenX = (pixelX >= HBP) ? (pixelX - HBP) : 10'd0;
    wire [9:0] screenY = (pixelY >= VBP) ? (pixelY - VBP) : 10'd0;


    wire [49:0] activeBricks;
    wire [9:0] playerX, playerY, playerWidth, playerHeight, ballX, ballY, ballSz, brickWidth, brickHeight, brickPadding, brickXoffset, brickYoffset, numRows, numCols;
    wire gameOver;

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
        .pixelX(screenX),
        .pixelY(screenY),
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

    wire ball_on;
    wire [2:0] ballRed, ballGreen;
    wire [1:0] ballBlue;

    display_shape ball(
        .enabled(active_video),
        .pixelX(screenX),
        .pixelY(screenY),
        .lowerX(ballX),
        .lowerY(ballY),
        .upperX(ballX + ballSz),
        .upperY(ballY + ballSz),
        .redVal(3'b111), // White paddle
        .greenVal(3'b111),
        .blueVal(2'b11),
        .inShape(ball_on),
        .redOut(ballRed),
        .greenOut(ballGreen),
        .blueOut(ballBlue)
    );

    wire [49:0] brick_hits;
    wire [2:0] brick_red [0:49];
    wire [2:0] brick_green [0:49];
    wire [1:0] brick_blue [0:49];
    genvar row, col;
    generate
        for (row = 0; row < 5; row = row + 1) begin : row_loop
            for (col = 0; col < 10; col = col + 1) begin : col_loop
                display_shape brick_inst (
                    .enabled(active_video && activeBricks[row * 10 + col]),
                    .pixelX(screenX),
                    .pixelY(screenY),
                    .lowerX(brickXoffset + col * (brickWidth + brickPadding)),
                    .lowerY(brickYoffset + row * (brickHeight + brickPadding)),
                    .upperX(brickXoffset + col * (brickWidth + brickPadding) + brickWidth),
                    .upperY(brickYoffset + row * (brickHeight + brickPadding) + brickHeight),
                    .redVal(3'b111),   // Red bricks
                    .greenVal(3'b000),
                    .blueVal(2'b00),
                    .inShape(brick_hits[row * 10 + col]),
                    .redOut(brick_red[row * 10 + col]),
                    .greenOut(brick_green[row * 10 + col]),
                    .blueOut(brick_blue[row * 10 + col])
                );
            end
        end
    endgenerate

    integer i;
    reg any_brick_on;
    reg [2:0] brick_r, brick_g;
    reg [1:0] brick_b;
    always @(*) begin
        any_brick_on = 0;
        brick_r = 3'b000;
        brick_g = 3'b000;
        brick_b = 2'b00;
        for(i = 0; i < 50; i = i + 1) begin
            if(brick_hits[i]) begin
                any_brick_on = 1;
                brick_r = brick_red[i];
                brick_g = brick_green[i];
                brick_b = brick_blue[i];
            end
        end
    end

    // Final VGA assignment
    assign vgaRed = paddle_on ? playerRed : ball_on ? ballRed : (any_brick_on ? brick_r : 3'b000);
    assign vgaGreen = paddle_on ? playerGreen : ball_on ? ballGreen : (any_brick_on ? brick_g : 3'b000);
    assign vgaBlue = paddle_on ? playerBlue : ball_on ? ballBlue : (any_brick_on ? brick_b : 2'b00);

endmodule