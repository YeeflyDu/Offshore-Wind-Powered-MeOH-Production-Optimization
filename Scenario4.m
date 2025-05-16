clc
clear
%% Parameter & Variable Setup
Typical_Day = 12;
Current_Year = 1;
WACC = 0.07;
%% External Carbon Source (only available until 2040)
% Parameter
C_CO2 = [96.7, 129.1, 159.1, 189.1, 209.9, 230.6]; % External CO2 purchase price, €/tCO2 (Source: The impact of FuelEU Maritime on European shipping)
C_CO2 = C_CO2(1,Current_Year);
% Variable
CO2_GRID = sdpvar(Typical_Day,24); % Externally purchased CO2, t
%% Battery & Interface
% Parameter
P2A_BAT = WACC*(1+WACC)^20/((1+WACC)^20-1); % Battery annualization factor
CAPEX_BAT = [153, 110, 89, 76, 68, 61]; % Battery capacity cost, €/kWh
CAPEX_BAT = CAPEX_BAT(1,Current_Year);
OPEX_BAT = [2.6, 2.2, 2.05, 1.9, 1.77, 1.71] + 0.0002; % Battery O&M cost, €/kWh
OPEX_BAT = OPEX_BAT(1,Current_Year);
CAPEX_BAT_INT = [76, 55, 44, 37, 33, 30]; % Battery interface cost, €/kW
CAPEX_BAT_INT = CAPEX_BAT_INT(1,Current_Year);
OPEX_BAT_INT = [1.29, 1.10, 1.01, 0.93, 0.86, 0.84]; % Battery interface O&M cost, €/kW
OPEX_BAT_INT = OPEX_BAT_INT(1,Current_Year);
BAT_EFF = [0.92, 0.93, 0.94, 0.95, 0.95, 0.95].^0.5; % Battery charge/discharge efficiency
BAT_EFF = BAT_EFF(1,Current_Year);
% Variable
Q_BAT = sdpvar(1,1,'full'); % Energy storage capacity, kWh
Q_BAT_INT = sdpvar(1,1,'full'); % Power storage capacity, kW
P_BAT_CHA = sdpvar(Typical_Day,24); % Battery charging power, kW
P_BAT_DIS = sdpvar(Typical_Day,24); % Battery discharging power, kW
TEMP_BAT_CHA = binvar(Typical_Day,24,'full'); % Battery charging binary variable
TEMP_BAT_DIS = binvar(Typical_Day,24,'full'); % Battery discharging binary variable
%% DAC (Direct Air Capture)
% Parameter
Lifetime_DAC = [25, 25, 30, 30, 30 ,30];
P2A_DAC = WACC*(1+WACC)^Lifetime_DAC(1,Current_Year)/((1+WACC)^Lifetime_DAC(1,Current_Year)-1); % DAC annualization factor
CAPEX_DAC = [20833, 7096, 4914, 3653, 3084, 2759]*1000*730/2378; % DAC capacity cost, €/tCO2h
CAPEX_DAC = CAPEX_DAC(1,Current_Year);
OPEX_DAC = [31, 18.5, 13.7, 10.7, 9.3, 8.5] + 1; % DAC variable O&M cost, €/tCO2
OPEX_DAC = OPEX_DAC(1,Current_Year);
P2CO2 = [700, 309, 275, 250, 237, 229]*250/700; % DAC electricity demand, kWh/tCO2
P2CO2 = P2CO2(1,Current_Year);
T2CO2 = [3000, 1326, 1179, 250, 237, 229]*1750/3000; % DAC thermal demand, kWh/tCO2
T2CO2 = T2CO2(1,Current_Year);
% Variable
Q_DAC = sdpvar(1,1,'full'); % DAC capacity, tCO2/h
P_DAC = sdpvar(Typical_Day,24,'full'); % DAC power, kW
CO2_DAC = sdpvar(Typical_Day,24,'full'); % DAC CO2 output, tCO2/h
%% Electric Water Boiler (EWB)
% Parameter
P2A_EWB = WACC*(1+WACC)^25/((1+WACC)^25-1); % EWB annualization factor
CAPEX_EWB = [65, 60, 60, 60, 60, 60]; % EWB capacity cost, €/kW
CAPEX_EWB = CAPEX_EWB(1,Current_Year);
OPEX_EWB = [0.0005, 0.0005, 0.0005, 0.0004, 0.0004, 0.0004]; % EWB variable O&M cost, €/kWh
OPEX_EWB = OPEX_EWB(1,Current_Year);
% Variable
Q_EWB = sdpvar(1,1,'full'); % EWB capacity, kW
P_EWB = sdpvar(Typical_Day,24,'full'); % EWB power, kW
%% Thermal Storage (TS)
P2A_TS = WACC*(1+WACC)^30/((1+WACC)^30-1); % Thermal storage annualization factor
Q_TS = sdpvar(1,1,'full'); % Thermal storage capacity, kWh
T_TS_IN = sdpvar(Typical_Day,24,'full'); % Thermal storage input heat
T_TS_OUT = sdpvar(Typical_Day,24,'full'); % Thermal storage output heat
%% CO2 Compressor (CC)
P2A_CC = WACC*(1+WACC)^20/((1+WACC)^20-1); % Compressor annualization factor
Q_CC = sdpvar(1,1,'full'); % CO2 compressor capacity
P_CC = sdpvar(Typical_Day,24,'full'); % CO2 compressor power, kW
CO2_CC = sdpvar(Typical_Day,24,'full'); % CO2 compressor output
%% CO2 Storage (CS)
P2A_CS = WACC*(1+WACC)^30/((1+WACC)^30-1); % CO2 storage annualization factor
Q_CS = sdpvar(1,1,'full'); % CO2 storage capacity
CO2_CC = sdpvar(Typical_Day,24,'full'); % CO2 storage input
CO2_CS_OUT = sdpvar(Typical_Day,24,'full'); % CO2 storage output
%% Electrolysis System (ES)
% Parameter
P2A_ES = WACC*(1+WACC)^30/((1+WACC)^30-1); % Electrolyzer annualization factor
CAPEX_ES = [446, 316, 234, 189, 163, 148]; % Electrolyzer capacity cost, €/kW
CAPEX_ES = CAPEX_ES(1,Current_Year);
OPEX_ES = [0.0014, 0.0011, 0.0009, 0.0009, 0.0009, 0.0009] + 0.0002; % Electrolyzer variable O&M cost, €/kWhH2
OPEX_ES = OPEX_ES(1,Current_Year);
P2H_EFF = [0.748, 0.762, 0.777, 0.791, 0.806, 0.821];
P2H_EFF = P2H_EFF(1,Current_Year);
P2T_EFF = [0.214, 0.2, 0.187, 0.173, 0.16, 0.147];
P2T_EFF = P2T_EFF(1,Current_Year);
% Variable
Q_ES = sdpvar(1,1,'full'); % Electrolysis system capacity
P_ES = sdpvar(Typical_Day,24,'full'); % Electrolysis system input power
H2_ES = sdpvar(Typical_Day,24,'full'); % Electrolysis system hydrogen output
%% H2 Compressor (HC)
P2A_HC = WACC*(1+WACC)^20/((1+WACC)^20-1); % Compressor annualization factor
CAPEX_HC =[2500, 1900, 1900, 1900, 1900, 1900]; % €/kW
CAPEX_HC = CAPEX_HC(1,Current_Year);
Q_HC = sdpvar(1,1,'full'); % H2 compressor capacity
P_HC = sdpvar(Typical_Day,24,'full'); % H2 compressor power, kW
H2_HC = sdpvar(Typical_Day,24,'full'); % H2 compressor output
%% H2 Storage (HS)
P2A_HS = WACC*(1+WACC)^30/((1+WACC)^30-1); % H2 storage annualization factor
CAPEX_HS = [493, 483, 483, 483, 483, 483]*1000; % H2 storage capacity cost, €/tH2
CAPEX_HS = CAPEX_HS(1,Current_Year);
Q_HS = sdpvar(1,1,'full'); % H2 storage capacity
H2_HC = sdpvar(Typical_Day,24,'full'); % H2 storage input
H2_HS_OUT = sdpvar(Typical_Day,24,'full'); % H2 storage output
%% Methanol Production System
P2A_MeOH = WACC*(1+WACC)^30/((1+WACC)^30-1); % MeOH system annualization factor
CAPEX_MeOH = [4598, 3947, 3947, 3389, 3389, 3100]*1000;
CAPEX_MeOH = CAPEX_MeOH(1,Current_Year);
Q_MeOH = sdpvar(1,1,'full'); % MeOH system capacity
P_MeOH = sdpvar(Typical_Day,24,'full'); % MeOH system input power
MeOH = sdpvar(Typical_Day,24,'full'); % MeOH system output
%% OWF (Offshore Wind Farm)
C_WT = [50.49, 45.44, 40.39, 38.21, 36.04, 33.86]/1000; % €/kWh
C_WT = C_WT(1,Current_Year);
P_WT = 50*1000*[5.961540808	6.423875702	4.213424661	3.033112039	3.865710359	2.172573181	2.022795199	2.845551714	2.665887473	3.64486761	6.11309824	6.423875702
5.812509275	6.267202796	3.979400543	2.754743196	3.64486761	2.250157879	1.950559462	2.57896332	2.57896332	3.432600179	5.961540808	6.11309824
6.11309824	6.11309824	3.979400543	2.410824817	3.537672593	2.172573181	1.88006426	2.329568015	2.57896332	3.329629143	5.665982414	5.961540808
6.267202796	5.961540808	3.865710359	2.172573181	3.432600179	2.172573181	1.744210557	2.172573181	2.49394951	3.432600179	5.665982414	5.665982414
6.423875702	5.665982414	3.865710359	2.096792696	3.228738258	2.022795199	1.678809604	2.172573181	2.410824817	3.537672593	5.380357804	5.665982414
6.745011469	5.812509275	4.095298235	1.950559462	3.033112039	1.950559462	1.552953364	2.022795199	2.329568015	3.537672593	5.104497171	5.521938999
6.583138184	5.812509275	4.213424661	2.022795199	2.938334253	1.88006426	1.433549839	1.950559462	2.410824817	3.432600179	4.97017528	5.380357804
6.583138184	5.961540808	4.213424661	2.022795199	2.845551714	1.811288367	1.32042922	1.950559462	2.410824817	3.432600179	5.104497171	5.104497171
6.423875702	6.11309824	4.213424661	1.950559462	2.665887473	1.744210557	1.32042922	2.096792696	2.329568015	3.432600179	5.104497171	4.838230705
6.11309824	6.267202796	4.213424661	1.88006426	2.49394951	1.744210557	1.32042922	2.096792696	2.250157879	3.64486761	4.97017528	4.708642221
5.961540808	5.961540808	4.095298235	1.811288367	2.410824817	1.811288367	1.433549839	2.096792696	2.250157879	3.537672593	5.241217604	4.5813886
5.812509275	5.521938999	4.095298235	1.88006426	2.329568015	1.88006426	1.492455625	2.096792696	2.250157879	3.432600179	5.521938999	4.708642221
5.665982414	5.241217604	4.095298235	2.022795199	2.329568015	1.88006426	1.615064282	2.172573181	2.329568015	3.432600179	5.521938999	4.708642221
5.380357804	5.104497171	4.095298235	2.172573181	2.250157879	1.88006426	1.811288367	2.172573181	2.329568015	3.432600179	5.521938999	4.708642221
5.104497171	5.241217604	4.095298235	2.410824817	2.329568015	1.950559462	1.950559462	2.172573181	2.410824817	3.537672593	5.380357804	4.708642221
5.104497171	5.521938999	4.213424661	2.49394951	2.410824817	2.096792696	2.172573181	2.250157879	2.57896332	3.754206457	5.380357804	4.838230705
5.521938999	5.961540808	4.095298235	2.57896332	2.410824817	2.250157879	2.410824817	2.329568015	2.845551714	4.095298235	5.665982414	5.104497171
5.961540808	6.267202796	4.333801046	2.665887473	2.49394951	2.172573181	2.57896332	2.57896332	2.938334253	4.213424661	5.665982414	5.380357804
6.423875702	6.583138184	4.838230705	2.665887473	2.49394951	2.096792696	2.754743196	2.754743196	3.129906299	4.456448617	5.665982414	5.665982414
6.423875702	6.745011469	4.838230705	2.57896332	2.49394951	2.096792696	2.754743196	2.938334253	3.033112039	4.456448617	5.521938999	5.961540808
6.423875702	6.909516782	4.838230705	2.665887473	2.665887473	2.172573181	2.665887473	3.033112039	3.228738258	4.456448617	5.521938999	6.11309824
6.423875702	6.745011469	4.838230705	2.938334253	2.754743196	2.172573181	2.49394951	3.228738258	3.129906299	4.333801046	5.241217604	6.423875702
6.267202796	6.745011469	4.708642221	3.129906299	2.938334253	2.250157879	2.329568015	3.228738258	2.938334253	4.213424661	5.104497171	6.583138184
6.11309824	6.583138184	4.708642221	3.033112039	2.938334253	2.172573181	2.250157879	3.129906299	2.938334253	3.979400543	4.97017528	6.583138184
];
P_WT = P_WT(:,1:Typical_Day);
%% External Electricity Source
% Parameter
C_GRID = 0.194; % External electricity purchase price, €/kWh
CO2_EFF = 359.64; % Carbon intensity of grid electricity, gCO2/kWh
% Variable
P_GRID = sdpvar(Typical_Day,24); % Externally purchased electricity, kWh
%% Constant
Constraints = [];
Constraints = [Constraints; P_GRID>=0];
for month = 1 : Typical_Day  
    % 28.2g/MJ constraint for carbon intensity
    Constraints = [Constraints; sum(P_GRID(month,:))*(360/Typical_Day)*CO2_EFF+sum(CO2_DAC(month,:))*(360/Typical_Day)*1000000+sum(CO2_GRID(month,:))*(360/Typical_Day)*1000000-...
        sum(MeOH(month,:))*(360/Typical_Day)*1.375*1000000<=28.2*sum(MeOH(month,:))*(360/Typical_Day)*1000*19.9];
end
% Power balance
Constraints = [Constraints; P_WT'+P_BAT_DIS+P_GRID==P_BAT_CHA+P_DAC+P_CC+P_ES+P_HC+P_MeOH+P_EWB];
% Battery constraints
Constraints = [Constraints; Q_BAT>=0; 0<=Q_BAT_INT<=Q_BAT];
Constraints = [Constraints; 0<=P_BAT_CHA<=Q_BAT_INT*TEMP_BAT_CHA; 0<=P_BAT_DIS<=Q_BAT_INT*TEMP_BAT_DIS]; % Charge/discharge power limits
Constraints = [Constraints; TEMP_BAT_CHA+TEMP_BAT_DIS==1]; % Single operation mode constraint
for month = 1 : Typical_Day
    for hour = 1 : 24
        % SOC constraints
        Constraints = [Constraints; 0.05*Q_BAT<=0.5*Q_BAT+(sum(-P_BAT_DIS(month,1:hour)/BAT_EFF+P_BAT_CHA(month,1:hour)*BAT_EFF))<=0.95*Q_BAT];
    end
    % Daily SOC balance
    Constraints = [Constraints; -sum(P_BAT_DIS(month,:),2)/BAT_EFF+sum(P_BAT_CHA(month,:),2)*BAT_EFF==0];
end
% DAC constraints
Constraints = [Constraints; Q_DAC>=0; P_DAC>=0];
Constraints = [Constraints; 0<=CO2_DAC<=Q_DAC; P_DAC==CO2_DAC*P2CO2; CO2_DAC+CO2_GRID-CO2_CC+CO2_CS_OUT>=1.46*MeOH; CO2_GRID>=0]; % Capacity, power consumption, CO2 balance
% Electric Water Boiler constraints
Constraints = [Constraints; Q_EWB>=0; 0<=P_EWB<=Q_EWB; 0.99*P_EWB+P2T_EFF*P_ES+T_TS_OUT-T_TS_IN>=CO2_DAC*T2CO2];
% Thermal Storage constraints
Constraints = [Constraints; Q_TS>=0; T_TS_OUT>=0; T_TS_IN>=0; T_TS_IN<=1/7*Q_CS];
for month = 1 : Typical_Day
    for hour = 1 : 24
        % SOC constraints
        Constraints = [Constraints; 0.05*Q_TS<=0.5*Q_TS+(sum(-T_TS_OUT(month,1:hour)+T_TS_IN(month,1:hour)))<=0.95*Q_TS];
    end
end
% Daily SOC balance
Constraints = [Constraints; -sum(T_TS_OUT,2)+sum(T_TS_IN,2)==0];
% CO2 Compressor constraints
Constraints = [Constraints; Q_CC>=0; P_CC>=0];
Constraints = [Constraints; 0<=CO2_CC<=Q_CC; P_CC==99*CO2_CC]; % Capacity and power consumption
% CO2 Storage constraints
Constraints = [Constraints; Q_CS>=0; CO2_CS_OUT>=0; CO2_CC>=0];
Constraints = [Constraints; CO2_CC<=1/6*Q_CS]; % CO2 balance
for month = 1 : Typical_Day
    for hour = 1 : 24
        % SOC constraints
        Constraints = [Constraints; 0.05*Q_CS<=0.5*Q_CS+(sum(-CO2_CS_OUT(month,1:hour)+CO2_CC(month,1:hour)))<=0.95*Q_CS];
    end
end
% Daily SOC balance
Constraints = [Constraints; -sum(CO2_CS_OUT,2)+sum(CO2_CC,2)==0];
% Electrolysis System constraints
Constraints = [Constraints; Q_ES>=0; H2_ES>=0];
Constraints = [Constraints; 0.25*Q_ES<=P_ES<=Q_ES; H2_ES-H2_HC+H2_HS_OUT>=0.199*MeOH]; % Capacity, power, H2 balance
Constraints = [Constraints; H2_ES==3.6/141860*P_ES*P2H_EFF];
for month = 1 : Typical_Day
    for hour = 2 : 24
        % Ramp constraints
        Constraints = [Constraints; P_ES(month,hour)-P_ES(month,hour-1)<=0.5*P_ES(month,hour-1)];
        Constraints = [Constraints; P_ES(month,hour-1)-P_ES(month,hour)<=0.5*P_ES(month,hour-1)];
    end
end
% H2 Compressor constraints
Constraints = [Constraints; Q_HC>=0; H2_HC>=0];
Constraints = [Constraints; 0<=P_HC<=Q_HC; P_HC==990*H2_HC]; % Capacity and power consumption
% H2 Storage constraints
Constraints = [Constraints; Q_HS>=0; H2_HS_OUT>=0];
Constraints = [Constraints; H2_HC<=1/6*Q_HS]; % H2 balance
for month = 1 : Typical_Day
    for hour = 1 : 24
        % SOC constraints
        Constraints = [Constraints; 0.05*Q_HS<=0.5*Q_HS+(sum(-H2_HS_OUT(month,1:hour)+H2_HC(month,1:hour)))<=0.95*Q_HS];
    end
end
% Daily SOC balance
Constraints = [Constraints; -sum(H2_HS_OUT,2)+sum(H2_HC,2)==0];
% Methanol Production System constraints
Constraints = [Constraints; Q_MeOH>=0; P_MeOH>=0];
Constraints = [Constraints; 0.5*Q_MeOH<=MeOH<=Q_MeOH; P_MeOH==169*MeOH]; % Capacity and power consumption
for month = 1 : Typical_Day
    for hour = 2 : 24
        % Ramp constraints
        Constraints = [Constraints; P_MeOH(month,hour)-P_MeOH(month,hour-1)<=0.02*P_MeOH(month,hour-1)];
        Constraints = [Constraints; P_MeOH(month,hour-1)-P_MeOH(month,hour)<=0.2*P_MeOH(month,hour-1)];
    end
end
%% Objective function
Cost_EXTRA = sum(P_GRID,'all')*(360/Typical_Day)*C_GRID;
Cost_EXTRA2 = C_CO2*sum(CO2_GRID,'all')*(360/Typical_Day);
Cost_Battery = P2A_BAT*CAPEX_BAT*Q_BAT + OPEX_BAT*Q_BAT + P2A_BAT*CAPEX_BAT_INT*Q_BAT_INT + OPEX_BAT_INT*Q_BAT_INT; % Battery
Cost_DAC = (P2A_DAC+0.04)*CAPEX_DAC*Q_DAC + OPEX_DAC*sum(CO2_DAC,'all')*(360/Typical_Day); % DAC
Cost_EWB = (P2A_EWB+0.015)*CAPEX_EWB*Q_EWB + OPEX_EWB*sum(P_EWB,'all')*(360/Typical_Day); % Electric Water Boiler
Cost_TS = (P2A_TS+0.0075)*27*Q_TS + 0.0001*sum(T_TS_IN,'all')*(360/Typical_Day); % Thermal Storage
Cost_CC = (P2A_CC+0.04)*338000*Q_CC + 0.1*sum(CO2_CC,'all')*(360/Typical_Day); % CO2 Compressor
Cost_CS = (P2A_CS+0.013)*22000*Q_CS + 0.1*sum(CO2_CC,'all')*(360/Typical_Day); % CO2 Storage
Cost_ES = (P2A_ES+0.035)*CAPEX_ES*Q_ES + OPEX_ES*P2H_EFF*sum(P_ES,'all')*(360/Typical_Day); % Electrolysis System
Cost_HC = (P2A_HC+0.04)*CAPEX_HC*Q_HC + 0.0001/0.025*sum(P_HC,'all')*(360/Typical_Day); % H2 Compressor
Cost_HS = (P2A_HS+0.01)*CAPEX_HS*Q_HS + 0.0001*141860/3.6*sum(H2_HC,'all')*(360/Typical_Day); % H2 Storage
Cost_MeOH = (P2A_MeOH+0.04)*CAPEX_MeOH*Q_MeOH + 11*sum(MeOH,'all')*(360/Typical_Day); % Methanol Production
Cost_Electricity = C_WT*sum(P_WT,'all')*(360/Typical_Day); % OWF Electricity Purchase
Cost = Cost_EXTRA + Cost_EXTRA2 + Cost_Battery + Cost_DAC + Cost_EWB + Cost_TS + Cost_CC + Cost_CS + Cost_ES + Cost_HC + Cost_HS + Cost_MeOH + Cost_Electricity;
%% LCOM Calculation
MeOH_total = sdpvar(1,1,'full');
Im_MeOH_total = sdpvar(1,1,'full');
Constraints = [Constraints; MeOH_total==sum(MeOH,'all')*(360/Typical_Day); Im_MeOH_total*MeOH_total>=1; Im_MeOH_total>=0; MeOH_total>=0];
LCOM = Cost*Im_MeOH_total;
ops=sdpsettings('verbose', 2, 'showprogress',1,'debug',1);
optimize(Constraints,LCOM,ops)
%% LCOM Result Output (Columns 1,2,3 show installation, O&M, and electricity costs for different components)
C_average = value((Cost_EXTRA+Cost_Electricity)/(sum(P_GRID,'all')*(360/Typical_Day)+sum(P_WT,'all')*(360/Typical_Day))); % Average electricity price
% Hydrogen production
Result(1,1) = value((P2A_ES)*CAPEX_ES*Q_ES)/value(Cost)*value(LCOM);
Result(1,2) = value((0.035)*CAPEX_ES*Q_ES + OPEX_ES*P2H_EFF*sum(P_ES,'all')*(360/Typical_Day))/value(Cost)*value(LCOM);
Result(1,3) = value(sum((P_ES),'all'))*C_average*(360/Typical_Day)/value(Cost)*value(LCOM); 
% Carbon capture
Result(2,1) = value((P2A_DAC)*CAPEX_DAC*Q_DAC)/value(Cost)*value(LCOM) + value(Cost_EXTRA2)/value(Cost)*value(LCOM);
Result(2,2) = value((0.04)*CAPEX_DAC*Q_DAC + OPEX_DAC*sum(CO2_DAC,'all')*(360/Typical_Day))/value(Cost)*value(LCOM);
Result(2,3) = value(sum((P_DAC),'all'))*C_average*(360/Typical_Day)/value(Cost)*value(LCOM); 
% Heat supply
Result(3,1) = value((P2A_EWB)*CAPEX_EWB*Q_EWB)/value(Cost)*value(LCOM);
Result(3,2) = value((0.015)*CAPEX_EWB*Q_EWB + OPEX_EWB*sum(P_EWB,'all')*(360/Typical_Day)+(0.0075)*27*Q_TS)/value(Cost)*value(LCOM);
Result(3,3) = value(sum((P_EWB),'all'))*C_average*(360/Typical_Day)/value(Cost)*value(LCOM); 
% Methanol production
Result(4,1) = value((P2A_MeOH)*CAPEX_MeOH*Q_MeOH)/value(Cost)*value(LCOM);
Result(4,2) = value((0.04)*CAPEX_MeOH*Q_MeOH + 11*sum(MeOH,'all')*(360/Typical_Day))/value(Cost)*value(LCOM);
Result(4,3) = value(sum((P_MeOH),'all'))*C_average*(360/Typical_Day)/value(Cost)*value(LCOM); 
% Storage
Result(5,1) = value(P2A_BAT*CAPEX_BAT*Q_BAT+P2A_BAT*CAPEX_BAT_INT*Q_BAT_INT+(P2A_TS)*27*Q_TS+0.0001*sum(T_TS_IN,'all')*(360/Typical_Day)+...
    (P2A_CC)*338000*Q_CC + (P2A_CS)*22000*Q_CS + (P2A_HC)*CAPEX_HC*Q_HC+(P2A_HS)*CAPEX_HS*Q_HS)/value(Cost)*value(LCOM);
Result(5,2) = value(OPEX_BAT*Q_BAT+OPEX_BAT_INT*Q_BAT_INT+(0.04)*338000*Q_CC +...
    0.1*sum(CO2_CC,'all')*(360/Typical_Day) + (0.013)*22000*Q_CS + 0.1*sum(CO2_CC,'all')*(360/Typical_Day) +...
    (0.04)*CAPEX_HC*Q_HC + 0.0001/0.025*sum(P_HC,'all')*(360/Typical_Day)+(0.01)*CAPEX_HS*Q_HS + 0.0001*141860/3.6*sum(H2_HC,'all')*(360/Typical_Day))/value(Cost)*value(LCOM);
Result(5,3) = value(sum((P_BAT_CHA-P_BAT_DIS),'all')+sum((P_CC),'all')+sum((P_HC),'all'))*C_average*(360/Typical_Day)/value(Cost)*value(LCOM);
% LCOM
LCOM = value(LCOM);
%% GHG Emission Intensity Output (g/MJ, monthly)
for month = 1 : Typical_Day  
    GHG(1,month)=value(sum(P_GRID(month,:))*(360/Typical_Day)*CO2_EFF+sum(CO2_DAC(month,:))*(360/Typical_Day)*1000000+sum(CO2_GRID(month,:))*(360/Typical_Day)*1000000-...
        sum(MeOH(month,:))*(360/Typical_Day)*1.375*1000000)/value(sum(MeOH(month,:))*(360/Typical_Day)*1000*19.9);
end
%% Power Balance Output
P_ES = value(P_ES)';
P_ES = reshape(P_ES,1,288)';
P_DAC = value(P_DAC)';
P_DAC = reshape(P_DAC,1,288)';
P_EWB = value(P_EWB)';
P_EWB = reshape(P_EWB,1,288)';
P_MeOH = value(P_MeOH)';
P_MeOH = reshape(P_MeOH,1,288)';
P_CC = value(P_CC)';
P_CC = reshape(P_CC,1,288)';
P_total = [P_ES P_DAC P_EWB P_MeOH P_CC]/1000;
%% Raw Materials and Products
CO2_GRID = value(CO2_GRID)';
CO2_GRID = reshape(CO2_GRID,1,288)';
H2_ES = value(H2_ES)';
H2_ES = reshape(H2_ES,1,288)';
MeOH = value(MeOH)';
MeOH = reshape(MeOH,1,288)';
Supply = [CO2_GRID H2_ES MeOH];