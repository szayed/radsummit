/**********************************************************************
*   Project: Unblocking Entrepreneurial Potential                     *                
*                                                                     *
*   Summary: This do-file analyzes data from screening tool           *
*    to select eligible participants                                  *
*                                                                     *
*   Contributors: Stephanie Zayed(szayed@poverty-action.org)          *
*				  											          *
*                                                                     *
*   Date of last change: 08/08/2019                                   *                                             
*                                                                     *
**********************************************************************/

//This is an example change for LAC RAD summit


	clear all
	set more off
	cap log close
	version 14.2

*****************************************
*               CONTENTS                *
*-------------------------------------  *
*   1-Directory                         *
*   2-Import                            *
*   3-Analysis to determine elegibility *
*   4-Stratification variables          *
*   5-Additional cleaning and analysis  *
*   6-Save clean dataset to be          *
*     used in randomization             * 
*****************************************

***************************************
* 1-Directory                         *
***************************************
		global screendir "cd"X:\Dropbox\Learning in Colombia\Project Development\Wave 2\Data Collection\Screening Tool"
			
		global screendata "$screendir\usedata"
		global screenraw "$screendir\rawdata"
		global screenlog "screendir\logs"
		global screenPII "$screendata\PII"
		global screenNOPII "$screendata\NOPII"
		

***************************************
* 2-Import                            *
***************************************
	$screenNOPII
	use "screening_cleandata_Aug22", clear

*****************************************
* 3-Analysis to determine elegibility   *
*****************************************

		gen age_group=1 if age>=18 & age<=28
		replace age_group=2 if age>28 & age<=59
		replace age_group=3 if age_group==.
		la def young 1 "18-28" 2 "29-59" 3 "Older than 59"
		la val age_group young
		label var age_group "Age group"
		tab project age_group
		
//BASIC CRITERIA
		gen drop=0
		replace drop=1 if read_yn!=1 // 1
		replace drop=1 if write_yn!=1 // 1
		replace drop=1 if contact==4 // 0
		replace drop=1 if age>=0 & age<=17 //0
		replace drop=1 if city!=1 // 4
		
		replace drop=1 if business_yn==2 & start_business_yn==2 // 15
		replace drop=1 if business_yn==2 & start_business_yn!=1 // 5
		replace drop=1 if business_yn!=1 & start_business_yn==2 // 1
		replace drop=1 if business_yn==.r & start_business_yn==.r // 1
	
			//Replace drop if participant from May Pilot or Wave 1
			replace drop=1 if pilot_may==1 // 0
			replace drop=1 if wave_1==1 // 7

			tab project if drop==0
			gen basiccriteria=1 if drop==0 //1=complies with basic criteria
			replace basiccriteria=0 if basiccriteria==. 
			
			label var basiccriteria "Complies with basic criteria"

	tab project age_group if drop==0
	
	//INCOME CRITERIA
		gen sales_confirmation=1 if sales>=1 & sales<=7
		replace drop=1 if income==0 & sales_confirmation==. // 21 NO SALES AND NO INCOME
		tab project if drop==0
		gen incomecriteria=1 if drop==0
		replace incomecriteria=0 if incomecriteria==. 
		
		drop sales_confirmation
		
		tab project age_group if drop==0
		
		label var incomecriteria "Complies with having income>0 or sales>0"

	//QUALITY OF BUSINESS/IDEA
	
		*Classifies business or business idea //
		gen classify=1 if (start_business_sector>=1 & start_business_sector<=4) | (business_sector>=1 & business_sector<=4)
		replace classify=0 if classify==.
		replace drop=1 if classify==0 //2
			
			drop classify
			
		*business/business idea description //
		replace drop=1 if business_idea_description=="" | business_idea_desc=="no" | business_idea_desc=="NO" | ///
						  business_idea_desc=="No aplica" | business_idea_desc=="no aplica"  | business_idea_desc=="no aplica" | ///
						  business_idea_desc=="prefiero no responder" // 17
			
			
		****NOTE CHANGE THIS TO USE THE SPLIT STEPS***
		*Took concrete steps in business or business idea //
		foreach var of varlist business_steps_* businessidea_steps_* {
			replace `var'="" if `var'=="Ninguno de los anteriores"
		}
		replace drop=1 if (business_steps_1=="" & business_steps_2=="" & business_steps_3=="" & business_steps_4==""  & business_steps_5==""  & business_steps_6==""  & business_steps_7=="") & start_business_yn!=1 // 3
		replace drop=1 if (businessidea_steps_1=="" & businessidea_steps_2=="" & businessidea_steps_3=="" & businessidea_steps_4=="" & businessidea_steps_5=="" & businessidea_steps_6=="")& business_yn!=1 // 6
				
		*If only business, and does not have sales 
		replace drop=1 if sales==0 & start_business_yn!=1 & sales_past3months==2 & sales_past6months==2 //1
						
		tab project if drop==0
		gen qualitycriteria=1 if drop==0
		replace qualitycriteria=0 if qualitycriteria==. 
		
		label var qualitycriteria "Complies with business/idea quality"
		
		
	//OTHER DROP DUE TO LOGISTICS
	
		*Victims and Migrants criteria
		gen Victim_Migrant=1 if registered_victim==1 | venezuela_migrant==1 | exposed_armed_conflict==1 | project==8 | project==9 | project==10
		replace Victim_Migrant=0 if Victim_Migrant==.
		la var Victim_Migrant "Reports being victim or having migrated from Venezuela"
		la def yesno 1 Yes 0 No
		la values Victim_Migrant yesno	
		
		
		//LGTBQ participants that are not victim/migrants or younger than 29
		*replace drop=2 if project==2 & age_group!=1 & Victim_Migrant!=1 //People from LGTBQ who are not udner 28 and not victim/migrant are not prioritized
		
		
		//OTHER QUESTIONS FOR PRIORITIZATION
		//PAST BUSINESS: if you don't have a business, you have a business idea, 
		
		*replace drop=2 if drop!=1 & //This is to identify people who should and should not be prioritized in case we have more people than we need
		
		
	*Label drop variables
	label var drop "Identifies participants who are eligible to participate in the program. 1=Not eligible"
	

		
	*Sub-population groups - trainers´ groups
		
		********NOTE: REVIEW THIS CLOSELY!!*********
		
		tab project
		
		gen sub_population=1 if project==1 & drop==0 //DISABILITIES
		replace sub_population=2 if project==5 & drop==0 & age_group!=1 //ADULTS
		replace sub_population=3 if age_group==1 & sub_population==. & drop==0 //YOUTH
		replace sub_population=4 if age_group==3 & sub_population==. & drop==0 //ELDERLY
		replace sub_population=5 if sub_population==. & drop==0 & Victim_Migrant==1 //ELIGIBLE TERRITORIAL - VICTIM OR MIGRANT
		replace sub_population=6 if sub_population==. & drop==0 & Victim_Migrant==0 //ELIGIBLE TERRITORIAL - NOT VICTIM OR MIGRANT
		
		label def subpop 1 "Proyecto Discapacidad" ///
						 2 "Proyecto Adultez" ///
						 3 "Proyecto Juventud" ///
						 4 "Proyecto Vejez" ///
						 5 "Proyecto Territorial - Víctima o Migrante" ///
						 6 "Proyecto Territorial - No es ni Víctima ni Migrante"
		
		label val sub_population subpop
		label var sub_population "Trainer groups"

		tab sub_pop
	*Low-medium income
	gen low_income=1 if income>=1 & income<=5
	label var low_income "Observations with income between 100 and 1.999.999 pesos"

***************************************
* 5-Stratification variables          *
***************************************	
	
	//1. age group, 2. business sector, 3. business status (running/idea), 4. income level 5. sales level 6. victim or migrant 

		//1. Generate age groups variables
			gen age_range_strat=1 if age>=18 & age <=28
			replace age_range_strat=2 if age>=29 & age <=45
			replace age_range_strat=3 if age>=46 & age <=59
			replace age_range_strat=4 if age>=60
					
			label def agerange 1 "18 to 28" 2 "29 to 45" 3 "46 to 59" 4 "More than 59"
				label val age_range agerange 
				label val age_range_strat agerange
				tab age_range_strat
				label var age_range_strat "Age range stratification variable"
	
		//2. business sector
			*We are going to use the business sector if they have business and business idea
			gen sector_strat=business_sector
			replace sector_strat=start_business_sector if sector_strat==. | sector_strat==.d | sector_strat==.r
			*Most of the pople who answered none of the above are providing a service
			replace sector_strat=3 if sector_strat==4
			label val sector_strat sectoridea
			label var sector_strat "Business or business idea sector startification variable"
		
		//3. generate variable to distinguish people who ONLY have a busines,ONLY have a business idea or have BOTH business and business idea and those who don't have EITHER
		
		gen entrepreneurship_strat=0
		replace entrepreneurship_strat=1 if business_yn==1 & (start_business_yn==2 | start_business_yn==. | start_business_yn==.r | start_business_yn==.d) //business yes idea no
		replace entrepreneurship_strat=2 if start_business_yn==1 & (business_yn==2 | business_yn==. | business_yn==.r | business_yn==.d) //business no idea yes
		replace entrepreneurship_strat=3 if business_yn==1 & start_business_yn==1 //business and idea
		replace entrepreneurship_strat=4 if (business_yn==2 | business_yn==. | business_yn==.r | business_yn==.d) & (start_business_yn==2 | start_business_yn==. | start_business_yn==.r | start_business_yn==.d) //business no idea no
		
		label def entrep 1 "Only business" 2 "Only business idea" 3 "Business and business idea" 4 "No business and no business idea"
		label val entrepreneurship_strat entrep
		label var entrepreneurship_strat "Entrepreneurship status stratification variable"
			
		//4. income level
		gen income_level_strat=1 if income>=0 & income<=3
		replace income_level_strat=2 if income>=4 & income<=7
		replace income_level_strat=3 if income_level_strat==.
		la def income 1 "< approx 1 min salary" 2 "> approx 1 min salary" 3 "Refusal"
		la values income_level_strat income
			label var income_level_strat "Income only stratification variable"
			
			
		//5. sales level
		
		gen sales_level_strat=1 if sales>=0 & sales<=3
		replace sales_level_strat=2 if sales>=4 & sales<=7
		replace sales_level_strat=3 if sales_level_strat==.
		la def sales 1 "< approx 1 min salary" 2 "> approx 1 min salary" 3 "Refusal/NA"
		la values sales_level_strat sales
				label var sales_level_strat "Sales only stratification variable"
				
				//5.a. Generate income and sales joint strata variable
				gen income_sales_strat=sales if entrepreneurship==1 | entrepreneurship==3
				replace income_sales_strat=income if (income_sales_strat==. | income_sales_strat==.r  | income_sales_strat==.d | income_sales_strat==.n | income_sales_strat==.) & entrepreneurship==2
				rename income_sales_strat income_sales


				gen income_sales_strat=1 if income_sales>=0 & income_sales<=3
				replace income_sales_strat=2 if income_sales>=4 & income_sales<=7
				replace income_sales_strat=3 if sales_level_strat==. | income_sales_strat==.r  | income_sales_strat==.d | income_sales_strat==.n | income_sales_strat==.
				
					la values income_sales_strat sales
					label var income_sales_strat "Income/Sales stratification variable"
					
					drop income_sales
					
		//6. Victim or migrant
		gen Victim_Migrant_strat=Victim_Migrant
		label var Victim_Migrant_strat "Victim/Migrant stratification variable"
		
		//7. Sex
		gen sex_strat=sex
		label var sex_strat "Sex stratification variable"
		
***************************************
* 6-Additional cleaning and analysis  *
***************************************			
		
		//Generate status for Alcaldía report
		gen status=1 if drop==0
		replace status=2 if drop==1
		*replace status=3 if drop==2
			label var status "Eligibility status"
			label def estado 1 "Priorizado en revisión" 2 "Rechazado"
			label val status estado
		
		
		//Create a variable for enumerator groups by locality for data collection purposes
		gen enumerator_group=0
		replace enumerator_group=1 if locality==13 | locality==1 | locality==18 | locality==12 | locality==20 | locality==5 | locality==16 //san cristobal, antonio nariño, tunjuelito, rafael uribe, usme, ciudad bolivar, sumapaz
		replace enumerator_group=2 if locality==9 | locality==14 | locality==10 | locality==11 | locality==8 | locality==3 // la candelaria, santa fe, martires, puente aranda, kennedy, bosa
		replace enumerator_group=3 if locality==19 | locality==15 | locality==6 | locality==7 | locality==4 | locality==2 | locality==17 // usaquen, suba, engativa, fontibon, chapinero, barrios unidos, tesuaquillo
		
		label var enumerator_group "Location classification for enumerator assignation"
		label def enum 1 "Christian" 2 "Luis" 3 "Lina"
		label val enumerator_group enum
	
*****************************************************
* 7-Save clean dataset to be used in randomization  *
*****************************************************	
		
		$screenNOPII
		save screening_cleandata_analysis, replace //to merge with PII in 04_Export do-file and create report for Alcaldia and database for datacollection
		
		
		
		