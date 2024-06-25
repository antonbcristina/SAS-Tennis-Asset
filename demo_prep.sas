libname tennis "...\Tennis\Data + Programs";
%let rawdata=...\Tennis\Data + Programs\Raw;

/***************************************************/
/**************     Identify players       *********/
/**************  from Athletes Earnings ************/
/*Data Source: https://www.kaggle.com/datasets/dimitrisangelide/top-10-highestpaid-athletes-tennis-nba-soccer*/
/***************************************************/

proc import datafile="&rawdata\Athletes Earnings.csv" out=earnings replace;
	guessingrows=max;
run;

data earnings;
	set earnings;
	where year>2011 and sport="Tennis";
	if player="Grigor Dmitrov" then player="Grigor Dimitrov";
	rename rank=Earnings_Rank;
	keep player;
run;

proc sort data=earnings out=tennis.earnings nodupkey;
	by player;
run;


/*******************************************/
/************   DEMOGRAPHICS  **************/
/*Data Source: https://github.com/JeffSackmann/tennis_atp/blob/master/atp_players.csv*/
/*******************************************/

/*Importing player demographics and assigning gender*/
proc import datafile="&rawdata\atp_players.csv" out=atp_players replace;
	guessingrows=10000;
run;

data atp_players;
	set atp_players(rename=(dob=dob_n));
	Gender="M";
	Player = catx(" ", name_first, name_last);
	dob_c=put(dob_n,$8.);
	DOB=input(dob_c,anydtdte.);
	drop wikidata_id name_first name_last dob_:;
	format dob date9.;
run;

proc import datafile="&rawdata\wta_players.csv" out=wta_players replace;
run;

data wta_players;
	set wta_players(rename=(dob=dob_n));
	gender="F";
	player = catx(" ", name_first, name_last);
	if name_first="Li" and name_last="Na" then height=172;
	dob_c=put(dob_n,$8.);
	dob=input(dob_c,anydtdte.);
	drop wikidata_id name_first name_last dob_:;
	format dob date9.;
run;

data players;
	set atp_players wta_players;
run;

/*Merge in demographis*/
proc sort data=players out=players;
	by player;
run;

proc sort data=tennis.earnings out=earnings;
	by player;
run;

data tennis.demo;
	retain player_id player dob gender;
	merge players(in=b) earnings(in=a) ;
	by player;
	if a;	
run;

*Make variable name capitalization consistent;
proc datasets lib=tennis nolist;
  modify demo;
     rename player_id=Player_ID
	 		player=Player
			dob=DOB
			gender=Gender
            hand=Hand
            ioc=IOC
            height=Height;
run;


/******************************************/
/********* HIGHEST RANK by player *********/
/****           2012-2021              ****/
/*Data Source: https://github.com/JeffSackmann/tennis_atp/tree/master*/
/******************************************/

proc import datafile="&rawdata\wta_rankings_10s.csv" out=wta_rankings_10s replace;
run;

proc import datafile="&rawdata\wta_rankings_20s.csv" out=wta_rankings_20s replace;
run;

proc import datafile="&rawdata\atp_rankings_10s.csv" out=atp_rankings_10s replace;
run;

proc import datafile="&rawdata\atp_rankings_20s.csv" out=atp_rankings_20s replace;
run;

data rankings;
	set wta_rankings_10s wta_rankings_20s atp_rankings_10s atp_rankings_20s;
	Year = substrn(ranking_date,1,4);
	if 2012 <=year<= 2021;
	keep player rank points year;
	rename player=Player_ID;
run;

proc sort data=rankings out=rankings ;
	by player_id year rank;
run;

proc sort data=rankings out=rankings2 nodupkey ;
	by player_id year ;
run;

proc sort data=tennis.demo out=demo;
	by player_id;
run;

data tennis.demo_rank;
	retain player_id player dob gender hand ioc height year;
	merge demo(in=a) rankings2 ;
	by Player_ID ;
	if a;
run;

*Make variable name capitalization consistent;
proc datasets lib=tennis nolist;
  modify demo_rank;
     rename player_id=Player_ID
	 		player=Player
			dob=DOB
			gender=Gender
            hand=Hand
            ioc=IOC
            height=Height
			year=Year
			rank=Rank
			points=Points;
run;