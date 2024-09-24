/*
Using entity table for ONLINE TRACKING DASHBOARD. Used with other sources in the Tableau dashboard
*/
select id_weber, id_lms, name_full, email, employee_class_desc, employee_deptartment_desc, EMPLOYEE_FACULTY_TYPE_CODE,
(case
        when employee_home_org_code LIKE '22%' then 'College of Arts and Humanities'
        when employee_home_org_code LIKE '24%' then 'College of Education'
        when employee_home_org_code LIKE '27%' then 'College of Engr Appl Sci Tech'
        when employee_home_org_code LIKE '21%' then 'College of Health Professions'
        when employee_home_org_code LIKE '25%' then 'College of Science'
        when employee_home_org_code LIKE '26%' then 'College of Social and Behavioral Science'
        when employee_home_org_code LIKE '28%' then 'Continuing Education'
        when employee_home_org_code LIKE '29%' then 'Related Curriculum'
        when employee_home_org_code LIKE '23%' then 'School of Business and Economics'
    else 'No College Designated' end) college__by_org_code

from red.dim_entity
where
id_card_status = 'ACTIVE'
and(role_faculty_ind = 1 or role_adjunct_ind =1) 
and role_primary_desc in ('Faculty', 'Adjunct') 
and employee_job_date_begin is not null  
and employee_position_desc != 'Retiree' 
-- use to filter down entity by type ('ADVSR', 'TRUST', 'NUAMES', 'ROTC', 'FAC', 'CLINC', 'CONCUR', 'ADJNCT', 'VISITF')
and employee_faculty_type_code in ('FAC', 'ADJNCT')  