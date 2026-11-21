`timescale 1ns/1ns

// testbench acts like container feeding the ports of module
module dcmi_tx_tb;
    logic clk = 0;
    logic reset = 0; // start in reset
    logic [13:0] data;
    logic VSYNC, HSYNC, PIXCLK;

    localparam int WIDTH = 256;
    localparam int HEIGHT = 320;

    dcmi_tx dut (.clk(clk), .reset(reset), .data(data), .VSYNC(VSYNC), .HSYNC(HSYNC), .PIXCLK(PIXCLK));

    always #5 clk = ~clk; // every 5ns toggle, 10ns period => 100MHz

    initial #100 reset = 1; 

    // load original data
    logic [13:0] orig_mem [0: WIDTH*HEIGHT - 1];
    initial $readmemh("images/image.mem", orig_mem);

    logic [16:0] addr = 0;
    int err_count = 0;
    int err_line_mismatch = 0;
    logic prev_HSYNC = 1'b0;
    logic prev_VSYNC = 1'b0;

    always_ff @(posedge PIXCLK) begin
        if (HSYNC && VSYNC) begin // data is valid
            if (orig_mem[addr] !== data)
                err_count++;
            addr++;
            prev_HSYNC <= 1'b1;
            prev_VSYNC <= 1'b1;
        end
        if (!HSYNC && VSYNC && prev_HSYNC == 1'b1) begin // is just beginning the next line
            if (addr % WIDTH !== 0)
                err_line_mismatch++;
            prev_HSYNC <= 1'b0;
            prev_VSYNC <= 1'b1;
        end
        if (!HSYNC && !VSYNC && prev_VSYNC == 1'b1) begin // starting next frame
            $display("the total pixel mismathes: %0d", err_count);
            $display("the total line mistatches: %0d", err_line_mismatch);
            if (err_count == 0 && err_line_mismatch == 0 && addr == HEIGHT*WIDTH)
                $display("PASS");
            else    
                $display("FAIL");
            prev_HSYNC <= 1'b0;
            prev_VSYNC <= 1'b0;
            addr <= 0;
            err_count <= 0;
            $finish;
        end
    end


endmodule
