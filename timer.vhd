library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity timer is
	port (
	 clk        : in  std_logic;
    rst        : in  std_logic;
    cs         : in  std_logic;
    addr       : in  std_logic;
    rw         : in  std_logic;
    data_in    : in  std_logic_vector(7 downto 0);
	 data_out   : out std_logic_vector(7 downto 0);
	 irq        : out std_logic
  );
end;

--*  Operation:
--*        Write count to counter register.
--*        Enable counter by setting bit 0 of the control register.
--*        Enable interrupts by setting bit 7 of the control register.
--*        Counter will count down to zero.
--*        When it reaches zero the terminal flag is set.
--*        If the interrupt is enabled an interrupt is generated.
--*        The interrupt may be disabled by writing a 0 to bit 7
--*        of the control register or by loading a new down count
--*        into the counter register.
--*
--* @author John E. Kent
--* @version 2.1 from 2010-06-17

architecture rtl of timer is
signal timer_ctrl  : std_logic_vector(7 downto 0);
signal timer_stat  : std_logic_vector(7 downto 0);
signal timer_count : std_logic_vector(7 downto 0);
signal timer_term  : std_logic; -- Timer terminal count
--
-- control/status register bits
--
constant BIT_ENB   : integer := 0; -- 0=disable, 1=enabled
constant BIT_IRQ   : integer := 7; -- 0=disabled, 1-enabled

begin

  --* write control registers
  timer_control : process( clk, rst, cs, rw, addr, data_in,
                         timer_ctrl, timer_term, timer_count )
  begin
    if clk'event and clk = '0' then
      if rst = '1' then
	     timer_count <= (others=>'0');
		  timer_ctrl  <= (others=>'0');
		  timer_term  <= '0';
      elsif cs = '1' and rw = '0' then
	     if addr='0' then
		    timer_count <= data_in;
		    timer_term  <= '0';
	     else
		    timer_ctrl <= data_in;
		  end if;
	   else
	     if (timer_ctrl(BIT_ENB) = '1') then
		    if (timer_count = "00000000" ) then
		      timer_term <= '1';
          else
            timer_count <= timer_count - 1;
		    end if;
		  end if;
      end if;
    end if;
  end process;

  --* timer status register
  timer_status : process( timer_ctrl, timer_term )
  begin
    timer_stat(6 downto 0) <= timer_ctrl(6 downto 0);
    timer_stat(BIT_IRQ) <= timer_term;
  end process;

  --* timer data output mux
  timer_data_out : process( addr, timer_count, timer_stat )
  begin
    if addr = '0' then
      data_out <= timer_count;
    else
      data_out <= timer_stat;
    end if;
  end process;

  --* read timer strobe to reset interrupts
  timer_interrupt : process( timer_term, timer_ctrl )
  begin
	 irq <= timer_term and timer_ctrl(BIT_IRQ);
  end process;

end rtl;