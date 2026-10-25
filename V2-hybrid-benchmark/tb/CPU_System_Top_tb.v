`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/06/2026 12:25:10 AM
// Design Name: 
// Module Name: CPU_System_Top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CPU_System_Top_tb(
    );

    //signals
    reg clk;
    reg reset_n;

    // wires 
    wire i_cache_stall ,d_cache_stall;
    wire i_cache_access,i_cache_hit,i_cache_miss;
    wire d_cache_read, d_cache_read_hit, d_cache_read_miss;
    wire d_cache_write, d_cache_write_hit, d_cache_write_miss, d_cache_writeback;
    wire branch, jal, jalr;
    wire mispredict;
    
    wire exception_en, mret;
    
    wire dma_start, dma_done, dma_busy, dma_lw_stall, dma_dir;
    wire [63:0] dma_size;
    
    wire read_transaction, write_transaction, busy;
    
    // Instantiate UUT
    CPU_System_Top CPU_System_UUT (
        .clk(clk),
        .reset_n(reset_n),
        
        // Benchmark
        // I cache
        .i_cache_stall(i_cache_stall),
        .i_cache_access(i_cache_access), 
        .i_cache_hit(i_cache_hit),
        .i_cache_miss(i_cache_miss),
        // D cache
        .d_cache_stall(d_cache_stall),
        .d_cache_read(d_cache_read), 
        .d_cache_read_hit(d_cache_read_hit), 
        .d_cache_read_miss(d_cache_read_miss),
        .d_cache_write(d_cache_write), 
        .d_cache_write_hit(d_cache_write_hit), 
        .d_cache_write_miss(d_cache_write_miss), 
        .d_cache_writeback(d_cache_writeback),
        // Branch
        .branch(branch), 
        .jal(jal), 
        .jalr(jalr), 
        .mispredict(mispredict),
        // Exception
        .exception_en(exception_en),
        .mret(mret),
        // DMA
        .dma_start(dma_start),
        .dma_dir(dma_dir),
        .dma_done(dma_done),
        .dma_busy(dma_busy),
        .dma_lw_stall(dma_lw_stall),
        .dma_size(dma_size),
        // AXI
        .read_transaction(read_transaction),
        .write_transaction(write_transaction),
        .busy(busy)    
    );

    //Clock generation
    localparam T = 10 ;
    initial clk = 0 ;
    always 
    begin
    #(T/2) clk = ~clk ;
    end
    
    
    //Benchmarking counters
    //CPU
    reg [63:0]cycle_count;
    localparam instr_count = 50;   // change it with the correct instruction numbre 
    
    //Stalls
    //reg [63:0]total_stall_cycles;
    reg [63:0]icache_stall_cycles;
    reg [63:0]dcache_stall_cycles;
    //reg [63:0]lw_stall_cycles;  // i think we don't need lwstall any more   + (this comment will help while optimizing the code)
    
    //ICache Performance
    reg [63:0]icache_access;
    reg [63:0]icache_hits;
    reg [63:0]icache_misses;
    
    //DCache Performance
    reg [63:0]dcache_read;
    reg [63:0]dcache_write;
    reg [63:0]dcache_read_hits;
    reg [63:0]dcache_read_misses;   
    reg [63:0]dcache_write_hits;
    reg [63:0]dcache_write_misses;
    reg [63:0]dcache_writeback;
    
    
    //Branch predictor performance
    reg [63:0]branch_total;
    reg [63:0]branch_mispredicts;
    
    reg [63:0]jalr_total;
    reg [63:0]jalr_mispredicts;
    
    // Exception
    reg inside_exception;
    reg [63:0] exception_handler_cycles; //exception enable till mret
    
    // DMA 
    reg [63:0] dma_requests;
    reg [63:0] dma_completed; // to check dma_requests = dma_done to see if the requests are done effeciency
    reg [63:0] dma_cpu_stall_cycles;
    // Effective DMA Throughput = PAYLOAD SIZE / dma_busy_cycles
    reg [63:0] dma_read_bytes;
    reg [63:0] dma_write_bytes;
    reg [63:0] dma_busy_cycles;
    
    // AXI / Bus
    // AXI throughput = no. of transcation / bus busy cycles;
    reg [63:0] bus_read_transactions; // main memory enables
    reg [63:0] bus_write_transactions;

    reg [63:0] bus_busy_cycles; 
    
    always @(posedge clk , negedge reset_n) begin
        if (~reset_n) begin
           // CPU
           cycle_count <= 0;
           
           //total_stall_cycles <= 0;
           icache_stall_cycles <= 0;
           dcache_stall_cycles <= 0;
           
           
           icache_access <= 0;
           icache_hits <= 0;
           icache_misses <= 0;
           
           dcache_read <=0;
           dcache_write <= 0;
           dcache_read_hits <= 0;
           dcache_read_misses <= 0;
           dcache_write_hits <= 0;
           dcache_write_misses <= 0;
           dcache_writeback <= 0;
           
           branch_total <= 0;
           branch_mispredicts <= 0;
           jalr_total <=0;
           jalr_mispredicts <= 0;
           
           // Exception
           inside_exception <= 0;
           exception_handler_cycles <= 0;
           // DMA
           dma_requests <= 0;
           dma_completed <= 0;
           dma_cpu_stall_cycles <= 0;
           dma_read_bytes <= 0;
           dma_write_bytes <= 0;
           dma_busy_cycles <= 0;
           // AXI / Bus
           bus_read_transactions <= 0; // no. of read bursts (requests)
           bus_write_transactions <= 0; // no. of write bursts (requests)
           bus_busy_cycles <= 0;
           
           
        end else begin
             // CPU
            cycle_count <= cycle_count +1;
            if(i_cache_stall) 
                icache_stall_cycles <= icache_stall_cycles +1;
            if(d_cache_stall)
                dcache_stall_cycles <= dcache_stall_cycles +1;
            
            if(i_cache_access) 
                icache_access <= icache_access +1;
            if(i_cache_hit) 
                icache_hits <= icache_hits +1;
            if(i_cache_miss) 
                icache_misses <= icache_misses +1;
            
            if(d_cache_read) 
                dcache_read <= dcache_read +1;
                
            if(d_cache_write) 
                dcache_write <= dcache_write +1;
                
            if(d_cache_read_hit) 
                dcache_read_hits <= dcache_read_hits +1;
                
            if(d_cache_write_hit) 
                dcache_write_hits <= dcache_write_hits +1;
                
            if(d_cache_read_miss) 
                dcache_read_misses <= dcache_read_misses +1;
                
            if(d_cache_write_miss) 
                dcache_write_misses <= dcache_write_misses +1;
                
            if(d_cache_writeback) 
                dcache_writeback <= dcache_writeback +1;
            
            if(branch | jal) 
                branch_total <= branch_total +1;
            if(mispredict && ~jalr) 
                branch_mispredicts <= branch_mispredicts +1;
            if(jalr) 
                jalr_total <= jalr_total +1;
            if(mispredict && jalr) 
                jalr_mispredicts <= jalr_mispredicts +1;
                
            // Exception
            // Enter exception handling
            if (exception_en)
                inside_exception <= 1;
            // Count cycles while inside handler
            if (inside_exception)
                exception_handler_cycles <= exception_handler_cycles + 1;
            // Exit exception handling
            if (mret)
                inside_exception <= 0;
            
            
            // DMA
            if(dma_start) begin
                dma_requests <= dma_requests + 1;
                if (dma_dir) begin
                dma_read_bytes <= dma_read_bytes + dma_size; // make one for read and one for write
                end else begin
                dma_write_bytes <= dma_write_bytes + dma_size;
                end end
            if(dma_done)
                dma_completed <= dma_completed + 1;
            if(dma_lw_stall)
                dma_cpu_stall_cycles <= dma_cpu_stall_cycles + 1;
            if(dma_busy) 
                dma_busy_cycles <= dma_busy_cycles + 1;
                
            // AXI / Bus
            if(read_transaction)
                bus_read_transactions <= bus_read_transactions + 1;
            if(write_transaction)
                bus_write_transactions <= bus_write_transactions + 1;
            if(busy)
                bus_busy_cycles <= bus_busy_cycles + 1;
        end
    end
    
    
    // Simulation
    initial begin
        // Initialize
        reset_n = 0;
        #20;
        reset_n = 1; // Release reset 


        // Let the CPU run for some time
        #1110000;
        print_report();
        $finish;
    end
    
    //display 
    task print_report;
        real cpi, ipc;
        //real stall_percentage;
        real icache_hit_rate, icache_miss_rate;
        real i_cache_stall_percentage;
        real d_cache_stall_percentage;
        real dcache_read_hit_rate, dcache_read_miss_rate;
        real dcache_write_hit_rate, dcache_write_miss_rate,dcache_writeback_rate;
        real dcache_hit_rate, dcache_miss_rate;
        real bp_accuracy, misprediction_flush_cycles, jalr_misprediction_flush_cycles;
        real exception_overhead;
        real dma_payload_bytes, dma_throughput, dma_efficiency, dma_utilization, dma_avg_transfer_size;
        real bus_total_bytes,bus_total_transactions;
        real bus_throughput, bus_utilization, avg_total_transaction_size;
        real bus_bytes_read, bus_bytes_written;
        begin
        
        //calculate
        cpi = (cycle_count *1.0)/(instr_count *1.0);
        ipc = (instr_count *1.0)/(cycle_count *1.0);
        //stall_percentage = (total_stall_cycles * 1.0)/(cycle_count *1.0) *100.0;
        i_cache_stall_percentage = (icache_stall_cycles *1.0) / (cycle_count * 1.0) *100;
        d_cache_stall_percentage = (dcache_stall_cycles *1.0) / (cycle_count * 1.0) *100;
        //icache
        icache_hit_rate = (icache_hits *1.0)/((icache_access *1.0)) * 100.0;
        icache_miss_rate = (icache_misses *1.0)/((icache_access *1.0)) * 100.0;
        
        //dcache read
        dcache_read_hit_rate = (dcache_read_hits *1.0)/(dcache_read *1.0) * 100.0;
        dcache_read_miss_rate = (dcache_read_misses *1.0)/(dcache_read *1.0) * 100.0;
         
        //dcache write
        dcache_write_hit_rate = (dcache_write_hits *1.0)/(dcache_write *1.0) * 100.0;
        dcache_write_miss_rate = (dcache_write_misses *1.0)/(dcache_write *1.0) * 100.0;
        dcache_writeback_rate = (dcache_writeback *1.0)/(dcache_write *1.0) * 100.0;
        
        //total rates
        dcache_hit_rate = ((dcache_read_hits + dcache_write_hits) *1.0)/((dcache_read +dcache_write) *1.0) * 100.0;
        dcache_miss_rate = ((dcache_read_misses + dcache_write_misses) *1.0)/((dcache_read +dcache_write) *1.0) * 100.0;
        
        //branch prediction
        bp_accuracy = ((branch_total - branch_mispredicts) *1.0)/(branch_total *1.0) * 100.0;
        misprediction_flush_cycles = branch_mispredicts * 2; //we flush D and E so 2 cycles penalty
        jalr_misprediction_flush_cycles = jalr_mispredicts *2;
        
        // Exception
        exception_overhead = exception_handler_cycles * 100.0 /cycle_count;
    
        // DMA METRICS
        dma_payload_bytes = dma_read_bytes + dma_write_bytes;
        dma_utilization = dma_busy_cycles * 100.0 / cycle_count;
        dma_throughput = dma_payload_bytes * 1.0 / dma_busy_cycles;
        dma_efficiency = dma_payload_bytes * 1.0 /(bus_bytes_read + bus_bytes_written);
        dma_avg_transfer_size = dma_payload_bytes * 1.0 / dma_completed;
        
        // AXI
        bus_bytes_read = dma_read_bytes + (dcache_read_misses + dcache_write_misses + icache_misses) * (512/8);
        bus_bytes_written = dma_write_bytes + dcache_writeback * (512/8);
        bus_total_bytes = bus_bytes_read + bus_bytes_written;
        bus_total_transactions = bus_read_transactions + bus_write_transactions;
        bus_throughput = bus_total_bytes * 1.0 / bus_busy_cycles;
        bus_utilization = bus_busy_cycles * 100.0 / cycle_count;
        avg_total_transaction_size = bus_total_bytes * 1.0 / bus_total_transactions;
        
        
        //display
        $display("============================================");
        $display("             Performance Report             ");
        $display("============================================");
        
        $display("[CPU]");
        $display("Total Cycles : %0d", cycle_count);
        $display("Instructions Committed: %0d", instr_count);
        $display("CPI : %.4f", cpi);
        $display("IPC : %.4f", ipc);
        
        $display("");  
        $display("[Pipeline Stalls]");
        //$display("Total Stall Cycles : %0d", total_stall_cycles);
        //$display("Stall%% : %.2f%%", stall_percentage);
        $display("I-Cache Stalls : %0d", icache_stall_cycles);
        $display("I-Cache Stalls Percentage : %.2f%%", i_cache_stall_percentage);
        
        $display("D-Cache Stalls : %0d", dcache_stall_cycles);
        $display("D-Cache Stalls Percentage : %.2f%%", d_cache_stall_percentage);
        
        $display("");        
        $display("[I-Cache]");
        $display("Access : %0d", icache_access);
        $display("Hits : %0d", icache_hits);
        $display("Misses : %0d", icache_misses);
        $display("Hit Rate : %.2f%%", icache_hit_rate);
        $display("Miss Rate : %.2f%%", icache_miss_rate);
        
        $display("");       
        $display("[D-Cache / Memory]");
        $display("Reads : %0d", dcache_read);
        $display("Read Hits : %0d", dcache_read_hits);
        $display("Read Misses : %0d", dcache_read_misses);
        $display("Read Hit Rate : %.2f%%", dcache_read_hit_rate);
        $display("Read Miss Rate : %.2f%%", dcache_read_miss_rate);
        $display("Writes : %0d", dcache_write);
        $display("Write Hits : %0d", dcache_write_hits);
        $display("Write Misses : %0d", dcache_write_misses);
        $display("Write Hit Rate : %.2f%%", dcache_write_hit_rate);
        $display("Write Miss Rate : %.2f%%", dcache_write_miss_rate);
        $display("Writebacks : %0d", dcache_writeback);
        $display("Writeback Rate : %.2f%%", dcache_writeback_rate);
        $display("Total Hit Rate : %.2f%%", dcache_hit_rate);
        $display("Total Miss Rate : %.2f%%", dcache_miss_rate);
        
        $display("");      
        $display("[Branch Predictor]");
        $display("Total Branches : %0d", branch_total);
        $display("Mispredictions : %0d", branch_mispredicts);
        $display("Accuracy: %.2f%%", bp_accuracy);
        $display("Misprediction flushed cycles : %0d", misprediction_flush_cycles);
        $display("Total JALRs : %0d", jalr_total);
        $display("JALRs Mispredictions : %0d", jalr_mispredicts);
        $display("JALRs flushed cycles : %0d", jalr_misprediction_flush_cycles);
        
        $display("");
        $display("[Exception]");
        $display("Exception handler cycles : %0d", exception_handler_cycles);
        $display("Exception Overhead : %.2f%%",exception_overhead);
        
        $display("");
        $display("[DMA]");
        $display("Requests : %0d", dma_requests);
        $display("Completed Transfers : %0d", dma_completed);
        $display("Payload Bytes : %0d", dma_payload_bytes);
        $display("Busy Cycles : %0d", dma_busy_cycles);
        $display("CPU Stall Cycles : %0d", dma_cpu_stall_cycles); 
        $display("Throughput: %.2f bytes/cycle", dma_throughput);
        $display("Efficiency: %.2f", dma_efficiency);
        $display("Utilization: %.2f%%", dma_utilization);
        $display("Avg Transfer Size: %.2f bytes", dma_avg_transfer_size);
       
        
        
        $display("");
        $display("[Bus]");
        $display("Bytes Read : %0d",bus_bytes_read);
        $display("Bytes Written : %0d",bus_bytes_written);
        $display("Read Transactions : %0d",bus_read_transactions);
        $display("Write Transactions : %0d",bus_write_transactions);
        $display("Busy Cycles : %0d",bus_busy_cycles);
        $display("Bus Throughput : %.2f bytes/cycle",bus_throughput);
        $display("Bus Utilization : %.2f%%",bus_utilization);
        $display("Avg Transaction : %.2f bytes",avg_total_transaction_size);
                
        $display("============================================");
    end
    endtask
    
endmodule
