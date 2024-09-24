
-- Creating temporary table ///////////////////////////////
CREATE PRIVATE TEMPORARY TABLE ora$ptt_temp1
On COMMIT Preserve Definition
as         with 
    fet as (select dim_student_key, fet.dim_test_key, fet.test_code, fet.test_score, dt.test_desc, test_min_value, test_max_value
            from red.fact_external_test fet
            join red.dim_test dt on fet.dim_test_key = dt.dim_test_key
            where dim_test_date_key > '20190101'), --'20120101'
    
    fst as (select fst.dim_student_key, fst.dim_course_key, fst.term_code, fst.course_number, campus_code,fst.grade_code_final, fst.grade_category, fst.grade_mode_code
            from RED.FACT_STUDENT_TRANSCRIPT fst
            WHERE TERM_CODE > '202120' --'201420'
            and   SUBJECT_CODE = 'ENGL' 
            AND COURSE_NUMBER = '0900' --(0900,1005,1006,1007,1010,2010,2015)
            AND GRADE_CATEGORY in ('Pass','Fail', 'Withdrew')  -- 'Fail', 'Withdrew', 'Other'
            and grade_mode_code != 'C' -- exclude credit/non-credit grading
            ),
            
    ds as (select dim_student_key, id_weber, stu_type_code, stu_type_desc, stu_hs_gpa_verified, stu_hs_gpa, stu_time_status_desc,
            act_english, act_reading, act_composite, ENGLISH_COMP_ENTRY_PLACEMENT
            from red.dim_student) 
        

select 
        dim_student_key, stu_hs_gpa, stu_time_status_desc, 
        act_composite, ds.ENGLISH_COMP_ENTRY_PLACEMENT,
        fst.dim_course_key, fst.term_code, fst.course_number, fst.grade_code_final, fst.grade_category,
        fet.test_code, fet.test_score
          
from red.dim_student ds
join fst using (dim_student_key)
join fet using (dim_student_key)
where test_code in ('PEC') -- Placement 'PEC' and ACT Composite 'A01'
AND ds.ENGLISH_COMP_ENTRY_PLACEMENT = 'Level 1 ENGL 0900'
order by dim_student_key, term_code

;

--////////////////////////////////////
select count(distinct(dim_student_key)) from ora$ptt_temp1; -- check number of students

--///////////////////////////////////
-- Self join to get records at first term
select  t1.dim_student_key, t1.stu_hs_gpa, t1.stu_time_status_desc, 
        t1.act_composite, t1.ENGLISH_COMP_ENTRY_PLACEMENT,
        t1.term_code, t1.course_number, t1.grade_code_final, t1.grade_category,
        t1.test_code, t1.test_score

from ora$ptt_temp1 t1 
JOIN (select dim_student_key, min(term_code) min_term
        from ora$ptt_temp1
        group by dim_student_key) min
on min.dim_student_key=t1.dim_student_key and t1.term_code = min.min_term

;



