/*
Query pulls contact information and demographics for students who is near the completion of the program of study but did not pass the QL courses
Parameters:
         Bachelors degree with 90% completion or total of 110 credits earned
         Associates with  90% completion or total of 50 credits earned
*/

-- demographics
with ds as (select  dim_student_key, id_weber, name_full_legal, email, email_home_address, phone_cell_number, phone_home_number,
                         age, race_ethnicity_desc_new, sex_desc, marital_status_desc, stu_application_term, stu_hours_earned_transfer, 
                    address_ma_street_line1, address_ma_street_line2, address_ma_city, address_ma_state_code, address_ma_zip 
            from red.dim_student                                                               
            ),
-- department and college desc     
     fps as ( select fp.dim_student_key, fp.dim_college_key, college_description, degree_code,  degree_desc, degree_percent, 
                        program_desc, major_1_dept_desc, major_1_percent 
            from red.fact_program_of_study fp
            join   red.dim_college dc	on fp.dim_college_key = dc.dim_college_key	           
            where fp.current_ind = 1 
            and fp.priority	= 1                                                                 -- only current program with first priority
            and regexp_like(degree_code, '^A|^B')
            ),
-- latest GPA and credits            
     fsh as (select *
                from (  select dim_student_key, term_code as last_term, term_desc as last_term_desc, hours_earned_transfer, 
                        hours_earned_institutional, hours_earned_overall, gpa_overall, 
                        RANK() OVER (partition by dim_student_key order by term_code desc) as rn
                        from red.fact_student_history)       
            where rn = 1 
            ),
-- target list of students            
     st as (
                 select distinct(ds.dim_student_key)
            from red.dim_student ds	
            join red.fact_program_of_study fps on fps.dim_student_key = ds.dim_student_key	    -- program of study, 
            join red.fact_student_history fsh on ds.dim_student_key = fsh.dim_student_key	    -- credit hours
            join red.fact_student_transcript fst on fst.dim_student_key = ds.dim_student_key        -- math classes taken
            where not exists (
                    select 1
                    from red.fact_student_degree fsd
                    where ds.dim_student_key = fsd.dim_student_key
                    and degree_type_code not in ('CT', 'CC', 'CP', 'ID'))                   -- exclude people who graduated other that with certificate
            and fps.current_ind = 1

            and (fsh.ql_met_current_ind	= 0                                                 -- met QL by taking math classes (the indicator does not capture all students)
                OR ds.math_ql_dev_entry_desc != 'Met Math QL Prior to Entry')               -- met QL requirements on entry

            and NOT EXISTS (select 1                                                        -- exclude people who passed any Ql class
                    from red.fact_student_transcript fst_exclude
                    where fst_exclude.dim_student_key = ds.dim_student_key	
                    and fst_exclude.attribute_list like '%QL%'
                    and fst_exclude.grade_category	= 'Pass'                            -- keep people who tried but failed QL class.
                    )
            )
                  
select  
        ID_WEBER, name_full_legal, EMAIL	,EMAIL_HOME_ADDRESS	, COALESCE(PHONE_CELL_NUMBER, PHONE_HOME_NUMBER) as phone_number,
        AGE	,RACE_ETHNICITY_DESC_NEW	,SEX_DESC	,MARITAL_STATUS_DESC	,
        ADDRESS_MA_STREET_LINE1	,ADDRESS_MA_STREET_LINE2	,ADDRESS_MA_CITY	,ADDRESS_MA_STATE_CODE,	ADDRESS_MA_ZIP,
        COLLEGE_DESCRIPTION,	DEGREE_CODE,	DEGREE_DESC,	DEGREE_PERCENT,	PROGRAM_DESC,	MAJOR_1_DEPT_DESC,	MAJOR_1_PERCENT,	
        LAST_TERM,	LAST_TERM_DESC,	hours_earned_transfer,
        HOURS_EARNED_INSTITUTIONAL,	HOURS_EARNED_OVERALL,	GPA_OVERALL

from st
inner join fps on fps.dim_student_key = st.dim_student_key
inner join fsh on st.dim_student_key = fsh.dim_student_key
inner join ds on ds.dim_student_key = st.dim_student_key	   
where ds.stu_hours_earned_transfer > 0                                                      -- use dim_student table for the latest transfer data 
and         (
                (fps.degree_code like 'A%' and fsh.hours_earned_institutional > 50)
            or  (fps.degree_code like 'B%' and fsh.hours_earned_institutional > 110)
            or  (fps.degree_code like 'B%' and fps.degree_percent > 90)
            or  (fps.degree_code like 'A%' and fps.degree_percent > 90)
            )
and st.dim_student_key	not in (select distinct(dim_student_key)                            -- not taking math this fall
                                from red.FACT_COURSE_ATTRIBUTE fca
                                where fca.course_attribute_code LIKE '%QL%' 
                                and fca.term_code > 202510
                                )
                                    
and st.dim_student_key	not in (
                                select distinct(dim_student_key)                            -- EXCLUDE STUDENTS WHO TRANSFERRED QL CLASSES (if other indicators failed)
                                from red.fact_student_transfer_course t_course
                                where t_course.grade_category = 'Pass'
                                and t_course.attribute_list LIKE '%QL%'
                                )
order by id_weber desc