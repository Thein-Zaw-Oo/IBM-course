

*-------------------------------------------------------------------------------
* 2. Import XLSForm metadata // surveyCTO form
*-------------------------------------------------------------------------------

*TZO
gl sct "C:\Users\DELL\Dropbox\internetcensorship\02_survey\SurveyCTOs\endline"
*global sct "C:\Users\Dell\Dropbox\internetcensorship\02_survey\SurveyCTOs"
local xlsform "$sct/Final_internet_censorship_endline_ml.xlsx"

*YLH

*gl sct "C:\Users\HP\Dropbox\internetcensorship\02_survey\SurveyCTOs"
*global sct "C:\Users\Dell\Dropbox\internetcensorship\02_survey\SurveyCTOs"
local xlsform "$sct/Final_internet_censorship_endline_ml.xlsx"

*---- survey sheet -------------------------------------------------------------
frame create survey_meta

frame survey_meta {
    import excel "`xlsform'", sheet("survey") firstrow clear
    keep if strpos(type, "select_multiple")
	//qno is Quation number of each question , manually separate it from Question (label:English)
	// To do so, when you design surveyCTO form, you use QNO like separation ".", like KA1. question labelling
    keep name type qno 

    
    * Clean list_name: Remove the prefix and any extra spaces
    gen list_name = subinstr(type, "select_multiple", "", 1)
    replace list_name = trim(list_name)
	
    replace qno=trim(qno)
	
	format qno %10s
	
    tempfile s_meta
    save `s_meta'
}



*---- choices sheet ------------------------------------------------------------
frame create choices_meta
frame choices_meta {
	
    import excel "`xlsform'", sheet("choices") firstrow clear
	
    keep list_name name labelEnglish
    
    * Clean list_name to ensure match with survey_meta
    replace list_name = trim(list_name)
    *set trace on
	destring name, replace 
	*replace name=trim(name)
	
    rename name choice_value
    rename labelEnglish choice_label
    
    * CRITICAL: Convert choice_value to string to match dummy suffixes (e.g., "1")
    tostring choice_value, replace
    
    tempfile c_meta
    save `c_meta'
}

*-------------------------------------------------------------------------------
* 3. Label existing select_multiple dummy variables
*-------------------------------------------------------------------------------

frame change main

* Get the list of all select_multiple question names
frame survey_meta: levelsof name, local(mult_vars) clean

foreach var of local mult_vars {

    * 1. Get the list name for this variable
    frame survey_meta: levelsof list_name if name=="`var'", local(clist) clean
    
    * 2. NEW: Get the question number (qno) for this variable
    local qno ""
    frame survey_meta: levelsof qno if name=="`var'", local(qno) clean

    * 3. Get all choice values associated with this list
    frame choices_meta: levelsof choice_value if list_name=="`clist'", local(vals) clean

    foreach v of local vals {
        
        * 4. Extract the English label
        local lbl ""
        frame choices_meta: levelsof choice_label if list_name=="`clist'" & choice_value=="`v'", local(lbl) clean

        * 5. Construct the expected dummy variable name
        local dvar "`var'_`v'"

        * 6. Apply the label: "QNO. Label" (e.g., "D9a. Spouse/partner")
        capture confirm variable `dvar'
        if !_rc {
            if `"`lbl'"' != "" {
                * Concatenate qno and label here
                label variable `dvar' `"`qno'. `lbl'"'
				
				capture {
				lab drop `dvar'
				}
				
                label def `dvar' 1"Yes" 0"No"
	             label val `dvar' `dvar'
			
				
              display "Success: `dvar' labeled as: `qno'. `lbl'"
            }
        }
        else {
            display as text "Note: Variable `dvar' not found in dataset"
        }
    }
}



