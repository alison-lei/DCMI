`timescale 1ns/1ns

module dcmi_tx(
    input logic clk,
    input logic reset,
    output logic [13:0] data,
    output logic VSYNC, HSYNC, PIXCLK

);
    // clock divider
    // DE1-SoC 50 MHz onboard crystal oscillator
    // want 5 MHz
    localparam int NUM_CYC_FULL = 50000000 / 5000000; // 10
    localparam int NUM_CYC_HALF = NUM_CYC_FULL / 2; // 5

    logic [3:0] clk_counter;
    logic tick;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            clk_counter <= 0;
            PIXCLK <= 1'b0;
            tick <= 1'b0;
        end
        else if (clk_counter == NUM_CYC_HALF - 1) begin
            PIXCLK <= ~PIXCLK; // toggles value
            tick <= PIXCLK; // this ensures it pulses high on falling edge of PIXCLK
            clk_counter <= 0;
        end
        else begin
            clk_counter <= clk_counter + 1; // latch before PIXCLK value
            tick <= 1'b0;
        end
    end


    // SENDING DATA
    // FSM:
    // VBLANK: vertical blanking, two PIXCLK cycles, indicates start and end of frame
    // DATA: send one pixel (14 bits)
    // HBLANK: horizontal blanking, one PIXCLK cycle, indicates end of line (256 pixels in a horizontal line, 320 lines, so 320x256)

    localparam int TOTAL_LINE_COUNT = 320; // number of lines in one frame
    localparam int LINE_LENGTH = 256; // number of pixels in one line

    int PIXEL_COUNTER = 0;
    int LINE_COUNTER = 0;
    int VBLANK_COUNTER = 0; // count when a frame sent

    typedef enum logic [1:0] {
        VBLANK = 2'b0,
        DATA = 2'b1,
        HBLANK = 2'b10
    } statetype;

    statetype dcmi_state = VBLANK;

    logic [13:0] frame_mem [0:TOTAL_LINE_COUNT*LINE_LENGTH - 1]; // 14 bits of data for each pixel, total 320*256 pixels
    initial $readmemh("images/image.mem", frame_mem); // loads the pixel data into array

    logic [16:0] addr;
    logic [13:0] data_q;

    always_ff @(posedge clk)
        data_q <= frame_mem[addr];

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            dcmi_state <= VBLANK;
            PIXEL_COUNTER <= 1'b0;
            LINE_COUNTER <= 1'b0;
            VBLANK_COUNTER <= 1'b0;
            addr <= 0;
            VSYNC <= 1'b0;
            HSYNC <= 1'b0;
            data <= 0;

        end
        else begin
            if (tick) begin // tick is a pulse that goes high on falling edge of PIXCLK
                case (dcmi_state)
                    VBLANK: begin
                        VSYNC <= 1'b0;
                        HSYNC <= 1'b0;
                        if (VBLANK_COUNTER == 1) begin
                            VBLANK_COUNTER <= 0;
                            dcmi_state <= DATA;
                        end
                        else
                            VBLANK_COUNTER <= VBLANK_COUNTER + 1;
                    end

                    DATA: begin
                        VSYNC <= 1'b1;
                        HSYNC <= 1'b1;

                        data <= data_q;
                        addr <= addr + 1;

                        if (PIXEL_COUNTER == LINE_LENGTH - 1) begin
                            PIXEL_COUNTER <= 0;
                            if (LINE_COUNTER == TOTAL_LINE_COUNT - 1) begin
                                LINE_COUNTER <= 0;
                                addr <= 0;
                                dcmi_state <= VBLANK;
                            end
                            else 
                                dcmi_state <= HBLANK;
                        end
                        else
                            PIXEL_COUNTER <= PIXEL_COUNTER + 1;
                    end
                    
                    HBLANK: begin
                        HSYNC <= 1'b0;
                        dcmi_state <= DATA;
                        LINE_COUNTER <= LINE_COUNTER + 1;
                    end
                endcase
            end 
        end
    end
endmodule
