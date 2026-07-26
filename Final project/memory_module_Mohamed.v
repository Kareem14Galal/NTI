module memory_module #(
    parameter MEM_ADDR_WIDTH = 4,   // 16 antenna locations (2^4)
    parameter MEM_DATA_WIDTH = 12,  // 12-bit ADC data sample width
    parameter NUM_ANTENNAS   = 16
)(
    input  wire                      clk,
    input  wire                      write_en,
    input  wire [MEM_ADDR_WIDTH-1:0] address,     // antenna index
    input  wire [MEM_DATA_WIDTH-1:0] data_in,
    output reg  [MEM_DATA_WIDTH-1:0] data_out
);

    // Memory array storage (16 x 12-bit)
    reg [MEM_DATA_WIDTH-1:0] ram [0:NUM_ANTENNAS-1];

    // Synchronous Read / Write logic
    always @(posedge clk) begin
        if (write_en) begin
            ram[address] <= data_in;
        end
        // Synchronous read output
        data_out <= ram[address];
    end

endmodule