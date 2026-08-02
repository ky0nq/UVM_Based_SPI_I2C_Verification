class i2c_base_test extends uvm_test;
    `uvm_component_utils(i2c_base_test)

    i2c_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = i2c_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction
endclass

// Directed
class i2c_directed_test extends i2c_base_test;
    `uvm_component_utils(i2c_directed_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_directed_seq seq;
        phase.raise_objection(this);
        seq = i2c_directed_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Boundary
class i2c_boundary_test extends i2c_base_test;
    `uvm_component_utils(i2c_boundary_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_boundary_seq seq;
        phase.raise_objection(this);
        seq = i2c_boundary_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Random (Only Valid Address)
class i2c_random_test extends i2c_base_test;
    `uvm_component_utils(i2c_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_random_seq seq;
        phase.raise_objection(this);
        seq = i2c_random_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_fatal(get_type_name(), "seq randomize failed")
        seq.num = 2000;
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Write Only (Master → Slave, Only Valid Address)
class i2c_write_only_test extends i2c_base_test;
    `uvm_component_utils(i2c_write_only_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_write_only_seq seq;
        phase.raise_objection(this);
        seq = i2c_write_only_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_fatal(get_type_name(), "randomize failed")
        seq.num = 200;
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Read Only (Slave → Master, Only Valid Address)
class i2c_read_only_test extends i2c_base_test;
    `uvm_component_utils(i2c_read_only_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_read_only_seq seq;
        phase.raise_objection(this);
        seq = i2c_read_only_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_fatal(get_type_name(), "randomize failed")
        seq.num = 200;
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Multi-Slave (Only Valid Address)
class i2c_multi_slave_test extends i2c_base_test;
    `uvm_component_utils(i2c_multi_slave_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_multi_slave_seq seq;
        phase.raise_objection(this);
        seq = i2c_multi_slave_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_fatal(get_type_name(), "randomize failed")
        seq.num = 50;
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Loopback (WRITE and READ -> echo)
class i2c_loopback_test extends i2c_base_test;
    `uvm_component_utils(i2c_loopback_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_loopback_seq seq;
        phase.raise_objection(this);
        seq = i2c_loopback_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_fatal(get_type_name(), "randomize failed")
        seq.num = 20;
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Invalid Address (NACK signal)
class i2c_invalid_addr_test extends i2c_base_test;
    `uvm_component_utils(i2c_invalid_addr_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_invalid_addr_seq seq;
        phase.raise_objection(this);
        seq = i2c_invalid_addr_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Mixed Address Random
class i2c_mixed_addr_random_test extends i2c_base_test;
    `uvm_component_utils(i2c_mixed_addr_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_mixed_addr_random_seq seq;
        phase.raise_objection(this);
        seq = i2c_mixed_addr_random_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_fatal(get_type_name(), "randomize failed")
        seq.num = 200;
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Invalid Address Boundary (adjacent to 0x10 / 0x20)
class i2c_invalid_addr_boundary_test extends i2c_base_test;
    `uvm_component_utils(i2c_invalid_addr_boundary_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_invalid_addr_boundary_seq seq;
        phase.raise_objection(this);
        seq = i2c_invalid_addr_boundary_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// Invalid -> Valid Recovery
class i2c_invalid_valid_recovery_test extends i2c_base_test;
    `uvm_component_utils(i2c_invalid_valid_recovery_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_invalid_valid_recovery_seq seq;
        phase.raise_objection(this);
        seq = i2c_invalid_valid_recovery_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_fatal(get_type_name(), "randomize failed")
        seq.num = 10;
        seq.start(env.agt.sqr);
        #1000;
        phase.drop_objection(this);
    endtask
endclass