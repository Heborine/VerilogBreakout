module Game_Logic(
        input clk, // 100 MHz clock
        input rst,

input btnL,
    input btnR,

    //coordinates
    output reg [9:0] ballXcoord,
    output reg [9:0] ballYcoord,
    output reg [9:0] playerXcoord,
    output [9:0] playerYcoord, // NEW: paddle Y coord
    output [9:0] paddleWidth,  // NEW: constants for renderer
    output [9:0] paddleHeight, // NEW: constants for renderer

        // 7-segment display
        output reg [6:0] seg,
        output reg [3:0] an
    );
    
    localparam SCREEN_WIDTH = 640;
    localparam SCREEN_HEIGHT = 480;
    
    localparam BALL_SIZE = 5;
    localparam BALL_SPEED = 1;
    localparam PADDLE_WIDTH = SCREEN_WIDTH / 10;
    localparam PADDLE_HEIGHT = SCREEN_HEIGHT / 48;
    localparam PADDLE_Y_COORD = SCREEN_HEIGHT - 20;
    localparam PADDLE_SPEED = 1;

    localparam ROWS = 5;
    localparam COLUMNS = 10;
    localparam BRICK_WIDTH = 52;
    localparam BRICK_HEIGHT = 12;

    assign playerYcoord = PADDLE_Y_COORD;
    assign paddleWidth = PADDLE_WIDTH;
    assign paddleHeight = PADDLE_HEIGHT;

    reg [13:0] score;
    reg reset_sync1;
    reg reset_sync2;
    reg reset_debounce;
    reg reset_prev;
    reg [16:0] debounce_count_reset;
    reg [19:0] refresh_counter;
    reg [3:0] LED_DISP;

    task automatic increment_score;
        inout [13:0] score;
        input [13:0] point_inc;
        begin
            score = score + point_inc;
        end
    endtask

    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        reset_sync1 <= rst;
        reset_sync2 <= reset_sync1;

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

        if (reset_debounce && !reset_prev) begin
            refresh_counter <= 0;
            score <= 0;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end

    assign LED_activating_counter = refresh_counter[19:18];

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

    always @(posedge clk) begin //input and movement clock
        if (rst) begin
            playerXcoord <= (SCREEN_WIDTH / 2) - (PADDLE_WIDTH / 2);
        end else if (refresh_counter[16]) begin // Basic timer tick (~60Hz on 100MHz clock)
            if(btnL && playerXcoord > 0)begin
                playerXcoord <= playerXcoord - PADDLE_SPEED;
            end
            if(btnR && playerXcoord < SCREEN_WIDTH - PADDLE_WIDTH) begin
                playerXcoord <= playerXcoord + PADDLE_SPEED;
            end
        end
    end

    always@(posedge clk) begin //graphics display

    end


endmodule