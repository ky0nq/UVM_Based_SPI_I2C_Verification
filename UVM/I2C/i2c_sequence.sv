class i2c_base_seq extends uvm_sequence #(i2c_seq_item);
    `uvm_object_utils(i2c_base_seq)

    function new(string name = "i2c_base_seq");
        super.new(name);
    endfunction

    // Master to Slave Write
    task send_write(logic [6:0] addr, logic [7:0] data);
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");
        start_item(item);
        item.operation  = I2C_WRITE;
        item.slave_addr = addr;
        item.tx_data    = data;
        item.s_tx_data  = 8'h00;
        finish_item(item);
    endtask

    // Data Read | Slave to Master
    task send_read(logic [6:0] addr, logic [7:0] slave_data);
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");
        start_item(item);
        item.operation  = I2C_READ;
        item.slave_addr = addr;
        item.tx_data    = 8'h00;
        item.s_tx_data  = slave_data;
        finish_item(item);
    endtask
endclass

// Directed
class i2c_directed_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_directed_seq)

    function new(string name = "i2c_directed_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "=== Phase1: WRITE to slave 0x10 ===", UVM_LOW)
        send_write(7'h10, 8'h1E);
        send_write(7'h10, 8'h32);
        send_write(7'h10, 8'hA5);
        send_write(7'h10, 8'hFF);

        `uvm_info(get_type_name(), "=== Phase2: WRITE to slave 0x20 ===", UVM_LOW)
        send_write(7'h20, 8'h4C);
        send_write(7'h20, 8'h78);
        send_write(7'h20, 8'h5A);
        send_write(7'h20, 8'h00);

        `uvm_info(get_type_name(), "=== Phase3: READ from slave 0x10 ===", UVM_LOW)
        send_read(7'h10, 8'hDE);
        send_read(7'h10, 8'hAD);
        send_read(7'h10, 8'hBE);
        send_read(7'h10, 8'hEF);

        `uvm_info(get_type_name(), "=== Phase4: READ from slave 0x20 ===", UVM_LOW)
        send_read(7'h20, 8'hCA);
        send_read(7'h20, 8'hFE);
        send_read(7'h20, 8'hBA);
        send_read(7'h20, 8'hBE);
    endtask
endclass

// Boundary
class i2c_boundary_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_boundary_seq)

    function new(string name = "i2c_boundary_seq");
        super.new(name);
    endfunction

    task body();
        logic [7:0] bvals[6] = '{8'h00, 8'hFF, 8'h55, 8'hAA, 8'h01, 8'h80};

        `uvm_info(get_type_name(), "=== Boundary Values: WRITE ===", UVM_LOW)
        foreach (bvals[i]) begin
            send_write(7'h10, bvals[i]);
            send_write(7'h20, bvals[i]);
        end

        `uvm_info(get_type_name(), "=== Boundary Values: READ ===", UVM_LOW)
        foreach (bvals[i]) begin
            send_read(7'h10, bvals[i]);
            send_read(7'h20, bvals[i]);
        end
    endtask
endclass


// Random (Only Valid Address)
class i2c_random_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_random_seq)

    rand int num;
    constraint c_num { num inside {[20:50]}; }

    function new(string name = "i2c_random_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        `uvm_info(get_type_name(),
            $sformatf("=== Random Seq start (%0d transactions) ===", num), UVM_LOW)
        repeat (num) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "=== Random Seq done ===", UVM_LOW)
    endtask
endclass

// Write Only (Master → Slave, Only Valid Address)
class i2c_write_only_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_write_only_seq)

    rand int num;
    constraint c_num { num inside {[20:50]}; }

    function new(string name = "i2c_write_only_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        `uvm_info(get_type_name(),
            $sformatf("=== WRITE_ONLY seq start (%0d) ===", num), UVM_LOW)
        repeat (num) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                operation  == I2C_WRITE;
                slave_addr inside {7'h10, 7'h20};
                tx_data    inside {[8'h00:8'hFF]};
            })
                `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "=== WRITE_ONLY seq done ===", UVM_LOW)
    endtask
endclass

// Read Only (Slave → Master, Only Valid Address)
class i2c_read_only_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_read_only_seq)

    rand int num;
    constraint c_num { num inside {[20:50]}; }

    function new(string name = "i2c_read_only_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        `uvm_info(get_type_name(),
            $sformatf("=== READ_ONLY seq start (%0d) ===", num), UVM_LOW)
        repeat (num) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                operation  == I2C_READ;
                slave_addr inside {7'h10, 7'h20};
                s_tx_data  inside {[8'h00:8'hFF]};
            })
                `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "=== READ_ONLY seq done ===", UVM_LOW)
    endtask
endclass

// Multi-Slave (Only Valid Address)
class i2c_multi_slave_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_multi_slave_seq)

    rand int num;
    constraint c_num { num inside {[5:15]}; }

    function new(string name = "i2c_multi_slave_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(),
            $sformatf("=== Multi-Slave seq start (%0d rounds) ===", num), UVM_LOW)
        repeat (num) begin
            send_write(7'h10, $urandom_range(8'h01, 8'hFE));
            send_write(7'h20, $urandom_range(8'h01, 8'hFE));
            send_read (7'h10, $urandom_range(8'h01, 8'hFE));
            send_read (7'h20, $urandom_range(8'h01, 8'hFE));
        end
        `uvm_info(get_type_name(), "=== Multi-Slave seq done ===", UVM_LOW)
    endtask
endclass


// Loopback (WRITE and READ -> echo)
class i2c_loopback_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_loopback_seq)

    rand int num;
    constraint c_num { num inside {[5:15]}; }

    function new(string name = "i2c_loopback_seq");
        super.new(name);
    endfunction

    task body();
        logic [6:0] addrs[2] = '{7'h10, 7'h20};
        logic [7:0] echo;

        `uvm_info(get_type_name(),
            $sformatf("=== Loopback seq start (%0d iterations) ===", num), UVM_LOW)
        repeat (num) begin
            foreach (addrs[i]) begin
                echo = $urandom_range(8'h01, 8'hFE);
                `uvm_info(get_type_name(),
                    $sformatf("[Loopback] WRITE addr=0x%02X data=0x%02X", addrs[i], echo), UVM_LOW)
                send_write(addrs[i], echo);
                `uvm_info(get_type_name(),
                    $sformatf("[Loopback] READ  addr=0x%02X s_tx=0x%02X (echo)", addrs[i], echo), UVM_LOW)
                send_read(addrs[i], echo);
            end
        end
        `uvm_info(get_type_name(), "=== Loopback seq done ===", UVM_LOW)
    endtask
endclass


// Invalid Address (NACK signal)
class i2c_invalid_addr_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_invalid_addr_seq)

    function new(string name = "i2c_invalid_addr_seq");
        super.new(name);
    endfunction

    task body();
        logic [6:0] invalid_addrs[6] = '{7'h00, 7'h01, 7'h30, 7'h50, 7'h7E, 7'h7F};
        i2c_seq_item item;

        `uvm_info(get_type_name(), "=== Invalid Addr WRITE (NACK expected) ===", UVM_LOW)
        foreach (invalid_addrs[i]) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            item.c_addr.constraint_mode(0);
            item.operation  = I2C_WRITE;
            item.slave_addr = invalid_addrs[i];
            item.tx_data    = $urandom_range(8'h01, 8'hFE);
            item.s_tx_data  = 8'h00;
            `uvm_info(get_type_name(),
                $sformatf("[INVALID] WRITE to addr=0x%02X", invalid_addrs[i]), UVM_LOW)
            finish_item(item);
        end

        `uvm_info(get_type_name(), "=== Invalid Addr READ (NACK expected) ===", UVM_LOW)
        foreach (invalid_addrs[i]) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            item.c_addr.constraint_mode(0);
            item.operation  = I2C_READ;
            item.slave_addr = invalid_addrs[i];
            item.tx_data    = 8'h00;
            item.s_tx_data  = $urandom_range(8'h01, 8'hFE);
            `uvm_info(get_type_name(),
                $sformatf("[INVALID] READ from addr=0x%02X", invalid_addrs[i]), UVM_LOW)
            finish_item(item);
        end
    endtask
endclass

// Mixed Address Random 
class i2c_mixed_addr_random_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_mixed_addr_random_seq)

    rand int num;
    constraint c_num { num inside {[50:100]}; }

    function new(string name = "i2c_mixed_addr_random_seq");
        super.new(name);
    endfunction

    task body();
        i2c_seq_item item;
        `uvm_info(get_type_name(),
            $sformatf("=== Mixed Addr Random seq start (%0d) ===", num), UVM_LOW)
        repeat (num) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            item.c_addr.constraint_mode(0);
            if (!item.randomize() with {
                slave_addr inside {
                    7'h10, 7'h10, 7'h10, 7'h10,
                    7'h20, 7'h20, 7'h20, 7'h20,
                    7'h00, 7'h01, 7'h30, 7'h50, 7'h7E, 7'h7F
                };
            })
                `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "=== Mixed Addr Random seq done ===", UVM_LOW)
    endtask
endclass

// Invalid Address Boundary (adjacent to valid addresses 0x10 / 0x20 -> NACK expected)
class i2c_invalid_addr_boundary_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_invalid_addr_boundary_seq)

    function new(string name = "i2c_invalid_addr_boundary_seq");
        super.new(name);
    endfunction

    task body();
        logic [6:0] boundary_addrs[4] = '{7'h0F, 7'h11, 7'h1F, 7'h21};
        i2c_seq_item item;

        `uvm_info(get_type_name(), "=== Invalid Addr Boundary WRITE (NACK expected) ===", UVM_LOW)
        foreach (boundary_addrs[i]) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            item.c_addr.constraint_mode(0);
            item.operation  = I2C_WRITE;
            item.slave_addr = boundary_addrs[i];
            item.tx_data    = $urandom_range(8'h01, 8'hFE);
            item.s_tx_data  = 8'h00;
            `uvm_info(get_type_name(),
                $sformatf("[BOUNDARY] WRITE to addr=0x%02X", boundary_addrs[i]), UVM_LOW)
            finish_item(item);
        end

        `uvm_info(get_type_name(), "=== Invalid Addr Boundary READ (NACK expected) ===", UVM_LOW)
        foreach (boundary_addrs[i]) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            item.c_addr.constraint_mode(0);
            item.operation  = I2C_READ;
            item.slave_addr = boundary_addrs[i];
            item.tx_data    = 8'h00;
            item.s_tx_data  = $urandom_range(8'h01, 8'hFE);
            `uvm_info(get_type_name(),
                $sformatf("[BOUNDARY] READ from addr=0x%02X", boundary_addrs[i]), UVM_LOW)
            finish_item(item);
        end
    endtask
endclass

// Invalid -> Valid Recovery
class i2c_invalid_valid_recovery_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_invalid_valid_recovery_seq)

    rand int num;
    constraint c_num { num inside {[5:15]}; }

    function new(string name = "i2c_invalid_valid_recovery_seq");
        super.new(name);
    endfunction

    task body();
        logic [6:0] invalid_addrs[6] = '{7'h00, 7'h01, 7'h30, 7'h50, 7'h7E, 7'h7F};
        logic [6:0] inv_addr;
        i2c_seq_item item;

        `uvm_info(get_type_name(),
            $sformatf("=== Invalid->Valid Recovery seq start (%0d rounds) ===", num), UVM_LOW)
        repeat (num) begin
            inv_addr = invalid_addrs[$urandom_range(0, 5)];

            // Invalid address WRITE -> NACK (expected)
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            item.c_addr.constraint_mode(0);
            item.operation  = I2C_WRITE;
            item.slave_addr = inv_addr;
            item.tx_data    = $urandom_range(8'h01, 8'hFE);
            item.s_tx_data  = 8'h00;
            `uvm_info(get_type_name(),
                $sformatf("[RECOVERY] INVALID WRITE addr=0x%02X (NACK expected)", inv_addr), UVM_LOW)
            finish_item(item);

            // 0x10 address Write
            send_write(7'h10, $urandom_range(8'h01, 8'hFE));

            // Invalid address READ -> NACK (expected)
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            item.c_addr.constraint_mode(0);
            item.operation  = I2C_READ;
            item.slave_addr = inv_addr;
            item.tx_data    = 8'h00;
            item.s_tx_data  = $urandom_range(8'h01, 8'hFE);
            `uvm_info(get_type_name(),
                $sformatf("[RECOVERY] INVALID READ  addr=0x%02X (NACK expected)", inv_addr), UVM_LOW)
            finish_item(item);

            // 0x20 address Read
            send_read(7'h20, $urandom_range(8'h01, 8'hFE));
        end
        `uvm_info(get_type_name(), "=== Invalid->Valid Recovery seq done ===", UVM_LOW)
    endtask
endclass