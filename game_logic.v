module Game_Logic(
        input clk, // 100 MHz clock
        input rst,
        output reg [6:0] seg,
        output reg [3:0] an
    );
    reg [6:0] score;
    reg reset_sync1;
    reg reset_sync2;
    reg reset_debounce;
    reg reset_prev;
    reg [16:0] debounce_count_reset;
    reg [19:0] refresh_counter;

    function automatic void [6:0] increment_score (input [6:0] score, input [6:0] point_inc);
        score = score + point_inc;
    endfunction

    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        reset_sync1 <= rst;
        reset_sync2 <= reset_sync1;
    end

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
    end

    assign LED_activating_counter = refresh_counter[19:18];

    always @(*) begin
        case(LED_activating_counter)
            2'b00: begin
                an <= 4'b0111;
                LED_DISP <= mins/10;
            end
            2'b01: begin
                LED_DISP <= mins%10;
            end
            2'b10: begin
                an <= 4'b1101;
                LED_DISP <= secs/10;
            end
            2'b11: begin
                an <= 4'b1110;
                LED_DISP <= secs%10;
            end
            default: begin
                LED_DISP <= mins/10;
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


endmodule