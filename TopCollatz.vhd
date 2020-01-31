Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
library work;
use work.sets.all;
--use IEEE.std_logic_arith.all;
-- Designed by Yoshinao Kobayashi 20161225

entity TopCollatz is
end TopCollatz;
architecture SIM of TopCollatz is
signal SysClk :std_logic :='0';
signal Reset :std_logic :='0';
signal Go :std_logic :='0';
signal Din :std_logic_vector(9 downto 0) :=(others=>'0');
signal StartPoint :std_logic_vector(9 downto 0) :=(others =>'0');
signal monA :std_logic_vector(17 downto 0) :=(others=>'0');
signal max  :std_logic_vector(17 downto 0) :=(others =>'0'); --peak
signal Dout :std_logic_vector(7 downto 0) :=(others=>'0');
signal monC :std_logic_vector(2 downto 0) :=(others=>'0');
signal adrs :std_logic_vector(17 downto 0) := (others => '0');
signal qdata :std_logic_vector(26 downto 0) := (others => '0');
signal peakOfq :std_logic_vector(17 downto 0) := "000000000000000001";
signal Ans :sets := (others => ((others => '0'), (others => '0'), (others => '0')));
signal done :std_logic :='0';
signal allEnd :std_logic :='0';

component Collatz
port(
	SysClk :in std_logic :='0';
	reset :in std_logic :='0';
	GO :in std_logic :='0';
	Din :in std_logic_vector(9 downto 0) :=(others =>'0');
	StartPoint:out std_logic_vector(9 downto 0) :=(others =>'0');
	monA :out std_logic_vector(17 downto 0) :=(others =>'0');
	max  :out std_logic_vector(17 downto 0) :=(others =>'0'); --peak
	Dout :out std_logic_vector(7 downto 0) :=(others =>'0');
	monC :out std_logic_vector(2 downto 0) :="000";
	adrs :out std_logic_vector(17 downto 0) := (others => '0');
	qdata :out std_logic_vector(26 downto 0) := (others => '0');
	peakOfq :out std_logic_vector(17 downto 0) := "000000000000000001";
	Ans : out sets := (others => ((others => '0'), (others => '0'), (others => '0')));
	done :out std_logic :='0';
	allEnd :out std_logic :='0'
	);
end component;

begin

CL:Collatz port map(
	SysClk => SysClk,
	Reset => Reset,
	Go => Go,
	Din => Din,
	StartPoint => StartPoint,
	monA => monA,
	max => max,
	Dout => Dout,
	monC => monC,
	adrs => adrs,
	qdata => qdata,
	peakOfq => peakOfq,
	Ans => Ans,
	done => done,
	allEnd => allEnd);

process begin
SysClk<='1';
wait for 10 ns;
SysClk<='0';
wait for 10 ns;
end process;

process begin
wait for 5 ns;
Reset<='1';
Din<="0000000001";
wait for 40 ns;
Reset<='0';
Go<='1';
wait for 40 ns;
Go<='0';
wait for 10000000 ns;
end process;

end;