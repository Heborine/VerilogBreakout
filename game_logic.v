module Game_Logic(
    input clk, // 100 MHz clock
    
    // Buttons
    input rst,
    input btnL,
    input btnR,

    output reg [49:0] activeBricks,
    output wire [9:0] brickWidth,
    output wire [9:0] brickHeight,
    output wire [9:0] brickPadding,
    output wire [9:0] numRows,
    output wire [9:0] numCols,
    output wire [9:0] brickXoffset,
    output wire [9:0] brickYoffset,

    // Coordinates
    output reg [9:0] ballXcoord,
    output reg [9:0] ballYcoord,
    output wire [9:0] ballSz,
    output reg [9:0] playerXcoord,
    output wire [9:0] playerYcoord, 
    
    output wire [9:0] paddleWidth,  
    output wire [9:0] paddleHeight, 
    output reg gameOver,

    // 7-Segment Display
    output reg [6:0] seg,
    output reg [3:0] an
    );
    
    localparam SCREEN_WIDTH = 640;
    localparam SCREEN_HEIGHT = 480;
    
    localparam BALL_SIZE = 8;
    localparam BALL_SPEED = 2;
    localparam PADDLE_WIDTH = SCREEN_WIDTH / 10;
    localparam PADDLE_HEIGHT = SCREEN_HEIGHT / 48;
    localparam PADDLE_Y_COORD = SCREEN_HEIGHT - 20;
    localparam PADDLE_SPEED = 4;

    localparam ROWS = 5;
    localparam COLUMNS = 10;
    localparam BRICK_WIDTH = 52;
    localparam BRICK_HEIGHT = 12;
    localparam BRICK_PADDING = 2;
    localparam BRICK_X_OFFSET = 60;
    localparam BRICK_Y_OFFSET = 40;
    localparam MAX_TICKS = 416667;

    assign playerYcoord = PADDLE_Y_COORD;
    assign paddleWidth = PADDLE_WIDTH;
    assign paddleHeight = PADDLE_HEIGHT;
    assign brickWidth = BRICK_WIDTH;
    assign brickHeight = BRICK_HEIGHT;
    assign brickPadding = BRICK_PADDING;
    assign numCols = COLUMNS;
    assign numRows = ROWS;
    assign brickXoffset = BRICK_X_OFFSET;
    assign brickYoffset = BRICK_Y_OFFSET;
    assign ballSz = BALL_SIZE;

    reg [13:0] score;
    reg reset_sync1;
    reg reset_sync2;
    reg reset_debounce;
    reg reset_prev;
    reg [16:0] debounce_count_reset;
    reg [19:0] refresh_counter;

    reg btnL_sync1;
    reg btnL_sync2;
    reg btnL_debounce;
    reg [16:0] debounce_count_btnL;

    reg btnR_sync1;
    reg btnR_sync2;
    reg btnR_debounce;
    reg [16:0] debounce_count_btnR;

    reg [3:0] LED_DISP;

    reg signed [9:0] ballDirX;
    reg signed [9:0] ballDirY;

    initial begin
        refresh_counter = 0;
        score = 0;
        activeBricks = 50'h3FFFFFFFFFFFF; // Reset all bricks to alive (2^50-1)
        ballXcoord = SCREEN_WIDTH / 2;
        ballYcoord = SCREEN_HEIGHT / 2;
        ballDirX = BALL_SPEED;
        ballDirY = BALL_SPEED;
        gameOver = 0;
        playerXcoord = (SCREEN_WIDTH / 2) - (PADDLE_WIDTH / 2);
    end

    wire [1:0] LED_activating_counter;

    reg [20:0] ticks_count;
    reg tick;

    always @(posedge clk) begin
        if(rst) begin
            ticks_count <= 0;
            tick <= 0;
        end else if(ticks_count >= MAX_TICKS - 1) begin
            ticks_count <= 0;
            tick <= 1;
        end else begin
            ticks_count <= ticks_count + 1;
            tick <= 0;
        end
    end

    task automatic increment_score;
        inout [13:0] score;
        input [13:0] point_inc;
        begin
            score = score + point_inc;
        end
    endtask

    always @(posedge clk) begin
        reset_sync1 <= rst;
        reset_sync2 <= reset_sync1;

        btnL_sync1 <= btnL;
        btnL_sync2 <= btnL_sync1;

        btnR_sync1 <= btnR;
        btnR_sync2 <= btnR_sync1;

        if(reset_debounce != reset_sync2) begin
            debounce_count_reset <= debounce_count_reset + 1;
            //1ms = 0.001s 
            //0.001 * 100000000 = 100000 cycles
            if(debounce_count_reset >= 17'd100000) begin
                debounce_count_reset <= 0;
                reset_debounce <= reset_sync2;
            end
        end else begin
            debounce_count_reset <= 0;
        end

        reset_prev <= reset_debounce;

        if(btnL_debounce != btnL_sync2) begin
            debounce_count_btnL <= debounce_count_btnL + 1;
            //1ms = 0.001s 
            //0.001 * 100000000 = 100000 cycles
            if(debounce_count_btnL >= 17'd100000) begin
                debounce_count_btnL <= 0;
                btnL_debounce <= btnL_sync2;
            end
        end else begin
            debounce_count_btnL <= 0;
        end

        if(btnR_debounce != btnR_sync2) begin
            debounce_count_btnR <= debounce_count_btnR + 1;
            //1ms = 0.001s 
            //0.001 * 100000000 = 100000 cycles
            if(debounce_count_btnR >= 17'd100000) begin
                debounce_count_btnR <= 0;
                btnR_debounce <= btnR_sync2;
            end
        end else begin
            debounce_count_btnR <= 0;
        end

        if (reset_debounce && !reset_prev) begin
            refresh_counter <= 0;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end

    assign LED_activating_counter = refresh_counter[16:15];

    always @(*) begin
        case(LED_activating_counter)
            2'b00: begin
                an <= 4'b0111;
                LED_DISP <= (score / 1000) % 10;
            end
            2'b01: begin
                an <= 4'b1011;
                LED_DISP <= (score / 100) % 10;
            end
            2'b10: begin
                an <= 4'b1101;
                LED_DISP <= (score / 10) % 10;
            end
            2'b11: begin
                an <= 4'b1110;
                LED_DISP <= (score) % 10;
            end
            default: begin
                LED_DISP <= 0;
            end
        endcase
    end

    always @(*) begin
        case(LED_DISP)
            4'b0000: seg <= 7'b1000000; // "0"    
            4'b0001: seg <= 7'b1111001; // "1"
            4'b0010: seg <= 7'b0100100; // "2"
            4'b0011: seg <= 7'b0110000; // "3"
            4'b0100: seg <= 7'b0011001; // "4"
            4'b0101: seg <= 7'b0010010; // "5"
            4'b0110: seg <= 7'b0000010; // "6"
            4'b0111: seg <= 7'b1111000; // "7"
            4'b1000: seg <= 7'b0000000; // "8"    
            4'b1001: seg <= 7'b0010000; // "9"
            4'b1111: seg <= 7'b1111111; // "" (blink/blank)
            default: seg <= 7'b1000000; // "0"
        endcase
    end

    always @(posedge clk) begin 
        if (rst) begin
            playerXcoord <= (SCREEN_WIDTH / 2) - (PADDLE_WIDTH / 2);
        end else if (tick) begin // only counts at refresh rate
            if(btnL_debounce && playerXcoord > 0) begin
                playerXcoord <= playerXcoord - PADDLE_SPEED;
            end
            if(btnR_debounce && playerXcoord < SCREEN_WIDTH - PADDLE_WIDTH) begin
                playerXcoord <= playerXcoord + PADDLE_SPEED;
            end
        end
    end

    reg [10:0] nextX, nextY;
    reg signed nextVelocityX, nextVelocityY;
    integer row, col;

    always @(posedge clk) begin
        if(rst) begin
            score <= 0;
            activeBricks <= 50'h3FFFFFFFFFFFF;
            ballXcoord <= SCREEN_WIDTH / 2;
            ballYcoord <= SCREEN_HEIGHT / 2;
            ballDirX <= BALL_SPEED;
            ballDirY <= BALL_SPEED;
            gameOver <= 0;
        end else if(tick && !gameOver) begin
            nextX = ballXcoord + ballDirX;
            nextY = ballYcoord + ballDirY;
            nextVelocityX = ballDirX;
            nextVelocityY = ballDirY;

            //wall bounce
            if(nextX < 0) begin
                nextX = 0;
                nextVelocityX = BALL_SPEED;
            end else if(nextX + BALL_SIZE > SCREEN_WIDTH) begin
                nextX = SCREEN_WIDTH - BALL_SIZE;
                nextVelocityX = -1 * BALL_SPEED;
            end
            if(nextY < 0) begin
                nextY = 0;
                nextVelocityY = BALL_SPEED;
            end else if(nextY > SCREEN_HEIGHT || activeBricks == 50'b0) begin
                gameOver <= 1;
            end

            //paddle bounce
            if((nextX + BALL_SIZE > playerXcoord && nextX < playerXcoord + PADDLE_WIDTH) && 
                (nextY + BALL_SIZE >= PADDLE_Y_COORD && nextY + BALL_SIZE <= PADDLE_Y_COORD + PADDLE_HEIGHT + BALL_SPEED)) begin
                    nextY = PADDLE_Y_COORD - BALL_SIZE;
                    nextVelocityY = -1 * BALL_SPEED;
            end

            // brick collisions

            for (row = 0; row < ROWS; row = row + 1) begin
                for (col = 0; col < COLUMNS; col = col + 1) begin
                    if(activeBricks[row * COLUMNS + col]) begin
                        if((nextX + BALL_SIZE > (col * (BRICK_WIDTH + BRICK_PADDING) + BRICK_X_OFFSET)) &&
                            (nextX < (col * (BRICK_WIDTH + BRICK_PADDING) + BRICK_X_OFFSET + BRICK_WIDTH)) &&
                            (nextY + BALL_SIZE > (row * (BRICK_HEIGHT + BRICK_PADDING) + BRICK_Y_OFFSET)) &&
                            (nextY < (row * (BRICK_HEIGHT + BRICK_PADDING) + BRICK_Y_OFFSET + BRICK_HEIGHT))
                        ) begin
                            activeBricks[row * COLUMNS + col] <= 0;
                            score <= score + 10;
                            nextVelocityY = -1 * nextVelocityY;
                        end
                    end
                    
                end
            end
            ballXcoord <= nextX;
            ballYcoord <= nextY;
            ballDirX <= nextVelocityX;
            ballDirY <= nextVelocityY;
        end
    end

endmodule