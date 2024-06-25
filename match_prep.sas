libname tennis "...\Tennis\Data + Programs";
%let rawdata=...\Tennis\Data + Programs\Raw;



/******************************************/
/******* Matches/Tourneys by player *******/
/****           2012-2021              ****/
/*Data Source: https://github.com/JeffSackmann/tennis_atp/tree/master*/
/******************************************/

%macro imp(org);
	
	%do year=2012 %to 2021;
		proc import datafile="&rawdata\&org._matches_&year..csv" out=&org._matches_&year(drop=minutes w_SvGms l_SvGms winner_seed loser_seed) replace;
			guessingrows=3000;
		run;
	
		%if &year=2012 %then %do;
			data tennis.&org._all_matches;
				set &org._matches_&year;
			run;
		%end;

		%else %do;
			data tennis.&org._all_matches;
				set tennis.&org._all_matches &org._matches_&year;
			run;
		%end;

	%end;


%mend;

%imp(wta)
%imp(atp)

data tennis.all_matches;
	set tennis.wta_all_matches tennis.atp_all_matches;
run;


/*All matches by year for players of interest*/
proc sql;
	create table all_matches as
	select p.Player_ID, p.Player, Tourney_Name, Tourney_Level, Tourney_Date, Winner_ID, W_Ace, W_Df, Loser_ID, L_Ace, L_Df, Score 
	from tennis.all_matches as m inner join tennis.demo as p
	on (p.player_id=m.winner_id or p.player_id=m.loser_id) 
	order by 1, 3;
quit;	

*Address inconsistent tournament names;
data all_matches;
	set all_matches;
	if tourney_name=:"BJK Cup Finals" then tourney_name="BJK Cup";
	if tourney_name=:"Davis Cup" then tourney_name="Davis Cup";
	if tourney_name=:"Fed Cup" then tourney_name="Fed Cup";
	if find(tourney_name,"Hertogenbosch","i") then tourney_name="'s Hertogenbosch"; 
	if tourney_name="Us Open" then tourney_name="US Open";
	if tourney_name="St Petersburg" then tourney_name="St. Petersburg";
	Year = substrn(tourney_date,1,4); 
run;

proc sort data=all_matches;
	by player_id year tourney_name ;
run;

data all_player_matches;
	set all_matches;
	by player_id year tourney_name ;
	retain Max_Ace Max_Df;

	/*Reset all counts*/
	if first.year then do;
		Matches=0;
		Tourneys=0;
		Slams=0;
		Max_Ace=0; Max_Df=0;  Total_Ace=0; Total_Df=0;
		W=0;  L=0; Win_Per=0; 
	end;

	/*Total slams played that year*/
	if first.player_id and first.year and first.tourney_name and tourney_level="G" then slams=1;
	else if first.tourney_name and tourney_level="G" then slams+1;

	/*Total tournaments that year*/
	if first.player_id and first.year and first.tourney_name then tourneys=1;
	else if first.tourney_name then tourneys+1;



	/*Total matches played that year,  excluding all walkovers */
	if score^="W/O" then do;
		if first.player_id and first.year then matches=1;
		else matches+1;

		/*Wins*/
		if first.player_id and first.year and player_id=winner_id then w=1;
		else if player_id=winner_id then w+1;

		/*Loses*/
		if first.player_id and first.year and player_id=loser_id then l=1;
		else if player_id=loser_id then l+1;
	end;

	
	/*Max and total(ace) that year*/
	if first.player_id and first.year then do;
		if player_id=winner_id then do;
			max_ace=w_ace;
			total_ace=w_ace;
		end;
		else if player_id=loser_id then do;
			max_ace=l_ace;
			total_ace=l_ace;
		end;
	end;
	else do;
		if player_id=winner_id then do;
			if w_ace>max_ace then max_ace=w_ace;
			total_ace+w_ace;
		end;
		else if player_id=loser_id then do;
			if l_ace>max_ace then max_ace=l_ace;
			total_ace+l_ace;
		end;
	end;

	/*Max and total(df) that year*/
	if first.player_id and first.year then do;
		if player_id=winner_id then do;
			max_df=w_df;
			total_df=w_df;
		end;
		else if player_id=loser_id then do;
			max_df=l_df;
			total_df=l_df;
		end;
	end;
	else do;
		if player_id=winner_id then do;
			if w_df>max_df then max_df=w_df;
			total_df+w_df;
		end;
		else if player_id=loser_id then do;
			if l_df>max_df then max_df=l_df;
			total_df+l_df;
		end;
	end;

	if last.year;

	/*Win %*/
	win_per = w/matches;

	keep player_id player year max_ace max_df matches slams w l win_per total_ace total_df tourneys;
	format win_per percent10.2;
run;

data tennis.demo_rank_matches;
	retain Player_ID Player DOB Gender Hand IOC Height Year Rank Points Tourneys Slams Matches W L Win_Per Max_Ace Max_Df Total_Ace Total_Df;
	merge tennis.demo_rank all_player_matches;
	by player_id year;
run;
