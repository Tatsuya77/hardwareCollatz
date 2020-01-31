Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
library work;
use work.sets.all;
-- Designed by Yoshinao Kobayashi 20161225
-- Fmax 327.33 MHz Restricted Fmax 250MHz
-- Ttal combination function 51
-- Dedicated registers 26
-- Plane Algorithm

entity Collatz is
port(
	SysClk :in std_logic :='0';
	reset :in std_logic :='0';
	GO :in std_logic :='0';
	Din :in std_logic_vector(9 downto 0) :="0000000001";
	StartPoint:out std_logic_vector(9 downto 0) :=(others =>'0');
	monA :out std_logic_vector(17 downto 0) :=(others =>'0'); --height
	max  :out std_logic_vector(17 downto 0) :=(others =>'0'); --peak
	Dout :out std_logic_vector(7 downto 0) :=(others =>'0'); --steps
	monC :out std_logic_vector(2 downto 0) :=(others =>'0'); --conditions
	adrs :out std_logic_vector(17 downto 0) := (others => '0');
	qdata :out std_logic_vector(26 downto 0) := (others => '0');
	peakOfq :out std_logic_vector(17 downto 0) := "000000000000000001";
	Ans : out sets := (others => ((others => '0'), (others => '0'), (others => '0')));
	done :out std_logic :='0';
	allEnd :out std_logic :='0'
	);
end Collatz;

architecture RTL of Collatz is
signal AReg :std_logic_vector(17 downto 0) :="00000000"&"0000000001"; --height
signal peak :std_logic_vector(17 downto 0) :=(others =>'0');
signal BReg :std_logic_vector(7 downto 0) :=(others => '0'); --steps
signal Cond :std_logic_vector(2 downto 0) :="000"; --conditions
--2:'1'=changeRoot, 0~1:"00"=init, "01"=start, "11"=calculating, "10"=end
signal setReg :sets := (others => ((others => '0'), (others => '0'), (others => '0')));
signal StartP :std_logic_vector(9 downto 0) :=(others => '0');
signal NoData :std_logic :='0';
signal ToBeEnd :std_logic :='0';
signal Skip :std_logic :='0';
signal skip_delay :std_logic :='0';
signal endSig :std_logic :='0';
signal preBRegSteps :std_logic_vector(1 downto 0) :="00";
signal ppreBRegSteps :std_logic_vector(1 downto 0) :="00";

--ram
signal address:std_logic_vector(17 downto 0) := (others => '0');
signal indata	  :std_logic_vector(26 downto 0) := (others => '0');
--flag(1bit), peak(18bit), steps(8bit)
signal wren   :std_logic := '0';
signal q	     :std_logic_vector(26 downto 0) := (others => '0');
signal qpeak  :std_logic_vector(17 downto 0) := "000000000000000001";
signal qsteps :std_logic_vector(7 downto 0)  := (others => '0');
signal preqpeak :std_logic_vector(17 downto 0) := "000000000000000001";

begin

	ram_port : entity work.ram port map(
		address => address,
		clock => SysClk,
		data => indata,
		wren => wren,
		q => q
	);
	
	qpeak <= q(25 downto 8);
	qsteps <= q(7 downto 0);

	process begin
	wait until rising_edge(SysClk);
		if endSig='0'then
			preBRegSteps<=ppreBRegSteps;
			preqpeak<=qpeak;
			if (BReg>=4 and q(26)='1' and Cond="011")then
				skip_delay<='1';
			else
				skip_delay<='0';
			end if;
			if reset='1'then
				Cond <= "000";
			else
				case Cond(0) is
				when '0'=>
					if Go ='1' or Cond(2)='1'then --start
						Cond(0)<='1';
						Cond(2)<='0';
					end if;
				when '1'=>
					if(Cond(1)='1' and (ToBeEnd ='1' or Skip='1'))then
						Cond(0)<='0';
					end if;
				when others=>
					Cond(0)<='0';
				end case;
				
				Cond(1)<=Cond(0);
			end if;
			if Cond="001"then
				wren <= '0';
				StartP<=AReg(9 downto 0);
				peak<=AReg;
				address<=AReg;
			elsif Cond="011"then
				if ((AReg(0)='0' and AReg(1)='0') or NoData='1')then
					AReg<=("00"&AReg(17 downto 2));
					address<=("00"&AReg(17 downto 2));
				elsif((AReg(0)='0' and AReg(1)='1') or NoData='1')then
					AReg<=('0'&AReg(17 downto 1));
					address<=('0'&AReg(17 downto 1));
				else
					AReg<=('0'&AReg(16 downto 0))
						+ AReg(17 downto 1) + 1;
					address<=('0'&AReg(16 downto 0))
						+ AReg(17 downto 1) + 1;
					if (peak <= (AReg(16 downto 0)&'1' + AReg))then
						peak <= AReg(16 downto 0)&'1' + AReg;
					end if;
				end if;
			end if;
			if Cond="001"then
				BReg<="00000000";
			elsif((Cond="011" and NoData='0') and (AReg(0)='0' and AReg(1)='1'))then
				BReg<=BReg+1;
				ppreBRegSteps<="01";
			elsif((Cond="011" and NoData='0') and (AReg(0)='0' and AReg(1)='0'))then
				BReg<=BReg+2;
				ppreBRegSteps<="10";
			elsif((Cond="011" and NoData='0') and AReg(0)='1')then
				BReg<=BReg+2;
				ppreBRegSteps<="10";
			end if;
			if(BReg>=4 and q(26)='1' and Cond="011")then
				BReg<=qsteps + BReg;
			end if;
			
			
			if Cond="010"then
			
				--write to ram
				if (skip_delay='0')then
					wren <='1';
					address <= "00000000"&StartP;
					indata <= '1'&peak&BReg;
					
					--sort
					if (setReg(3).peak <= peak and setReg(2).peak > peak)then
						if(setReg(3).peak = peak)then
							if (setReg(3).len < BReg)then
								setReg(3).start<=StartP;
								setReg(3).len<=BReg;
							end if;
						else
							setReg(3).peak<=peak;
							setReg(3).start<=StartP;
							setReg(3).len<=BReg;
						end if;
					elsif (setReg(2).peak <= peak and setReg(1).peak > peak)then
						if(setReg(2).peak = peak)then
							if (setReg(2).len < BReg)then
								setReg(2).start<=StartP;
								setReg(2).len<=BReg;
							end if;
						else
							setReg(2).peak<=peak;
							setReg(2).start<=StartP;
							setReg(2).len<=BReg;
							setReg(3)<=setReg(2);
						end if;
					elsif (setReg(1).peak <= peak and setReg(0).peak > peak)then
						if(setReg(1).peak = peak)then
							if (setReg(1).len < BReg)then
								setReg(1).start<=StartP;
								setReg(1).len<=BReg;
							end if;
						else
							setReg(1).peak<=peak;
							setReg(1).start<=StartP;
							setReg(1).len<=BReg;
							setReg(3)<=setReg(2);
							setReg(2)<=setReg(1);
						end if;
					elsif (setReg(0).peak <= peak)then
						if(setReg(0).peak = peak)then
							if (setReg(0).len < BReg)then
								setReg(0).start<=StartP;
								setReg(0).len<=BReg;
							end if;
						else
							setReg(0).peak<=peak;
							setReg(0).start<=StartP;
							setReg(0).len<=BReg;
							setReg(3)<=setReg(2);
							setReg(2)<=setReg(1);
							setReg(1)<=setReg(0);
						end if;
					end if;
				else
					wren <= '1';
					address <= "00000000"&StartP;
					if (preqpeak>peak)then
						indata <= '1'&qpeak&(BReg-preBRegSteps-2);
						--sort
						if (setReg(3).peak <= preqpeak and setReg(2).peak > preqpeak)then
							if(setReg(3).peak = qpeak)then
								if (setReg(3).len <= (BReg-preBRegSteps-2))then
									setReg(3).start<=StartP;
									setReg(3).len<=(BReg-preBRegSteps-2);
								end if;
							else
								setReg(3).peak<=preqpeak;
								setReg(3).start<=StartP;
								setReg(3).len<=(BReg-preBRegSteps-2);
							end if;
						elsif (setReg(2).peak <= preqpeak and setReg(1).peak > preqpeak)then
							if(setReg(2).peak = preqpeak)then
								if (setReg(2).len < (BReg-preBRegSteps-2))then
									setReg(2).start<=StartP;
									setReg(2).len<=(BReg-preBRegSteps-2);
								end if;
							else
								setReg(2).peak<=preqpeak;
								setReg(2).start<=StartP;
								setReg(2).len<=(BReg-preBRegSteps-2);
								setReg(3)<=setReg(2);
							end if;
						elsif (setReg(1).peak <= preqpeak and setReg(0).peak > preqpeak)then
							if(setReg(1).peak = qpeak)then
								if (setReg(1).len < (BReg-preBRegSteps-2))then
									setReg(1).start<=StartP;
									setReg(1).len<=(BReg-preBRegSteps-2);
								end if;
							else
								setReg(1).peak<=preqpeak;
								setReg(1).start<=StartP;
								setReg(1).len<=(BReg-preBRegSteps-2);
								setReg(3)<=setReg(2);
								setReg(2)<=setReg(1);
							end if;
						elsif (setReg(0).peak <= preqpeak)then
							setReg(0).peak<=preqpeak;
							setReg(0).start<=StartP;
							setReg(0).len<=(BReg-preBRegSteps-2);
							if(setReg(0).peak < preqpeak)then
								setReg(3)<=setReg(2);
								setReg(2)<=setReg(1);
								setReg(1)<=setReg(0);
							end if;
						end if;
					else
						indata <= '1'&peak&(BReg-preBRegSteps-2);
						--sort
						if (setReg(3).peak <= peak and setReg(2).peak > peak)then
							if(setReg(3).peak = peak)then
								if (setReg(3).len < (BReg-preBRegSteps-2))then
									setReg(3).start<=StartP;
									setReg(3).len<=(BReg-preBRegSteps-2);
								end if;
							else
								setReg(3).peak<=peak;
								setReg(3).start<=StartP;
								setReg(3).len<=(BReg-preBRegSteps-2);
							end if;
						elsif (setReg(2).peak <= peak and setReg(1).peak > peak)then
							if(setReg(2).peak = peak)then
								if (setReg(2).len < (BReg-preBRegSteps-2))then
									setReg(2).start<=StartP;
									setReg(2).len<=(BReg-preBRegSteps-2);
								end if;
							else
								setReg(2).peak<=peak;
								setReg(2).start<=StartP;
								setReg(2).len<=(BReg-preBRegSteps-2);
								setReg(3)<=setReg(2);
							end if;
						elsif (setReg(1).peak <= peak and setReg(0).peak > peak)then
							if(setReg(1).peak = peak)then
								if (setReg(1).len < (BReg-preBRegSteps-2))then
									setReg(1).start<=StartP;
									setReg(1).len<=(BReg-preBRegSteps-2);
								end if;
							else
								setReg(1).peak<=peak;
								setReg(1).start<=StartP;
								setReg(1).len<=(BReg-preBRegSteps-2);
								setReg(3)<=setReg(2);
								setReg(2)<=setReg(1);
							end if;
						elsif (setReg(0).peak <= peak)then
							if(setReg(0).peak = peak)then
								if (setReg(0).len < (BReg-preBRegSteps-2))then
									setReg(0).start<=StartP;
									setReg(0).len<=(BReg-preBRegSteps-2);
								end if;
							else
								setReg(0).peak<=peak;
								setReg(0).start<=StartP;
								setReg(0).len<=(BReg-preBRegSteps-2);
								setReg(3)<=setReg(2);
								setReg(2)<=setReg(1);
								setReg(1)<=setReg(0);
							end if;
						end if;
					end if;
				end if;
					
					
				
				if StartP="1111111111"then
					endSig <= '1';
				else
					AReg<="00000000"&StartP+2;
					Cond(2)<='1'; --go flag
				end if;
			end if;
			
			
		end if;
	end process;

	StartPoint<=StartP;
	Done<='1'when Cond="010" else '0';
	Ans<=setReg;
	max<=peak;
	Dout<=BReg;
	monA<=AReg;
	monC<=Cond;
	adrs<=address;
	qdata<=q;
	peakOfq<=qpeak;
	Skip<='1'when(BReg>=4 and q(26)='1' and Cond="011")else '0';
	NoData<='1'when(AReg="000000000000000000" or AReg="000000000000000001")else '0';
	ToBeEnd <='1'when(AReg="000000000000000000" or AReg="000000000000000001" or AReg="000000000000000010")else '0';
	allEnd <= endSig;

end RTL;