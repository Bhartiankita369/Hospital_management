use hospital_management 

Select * from appointments
Select * from billing 
Select * from doctors
Select * from patients
Select * from treatments


-- 1. Total number of registered candidates
Select * from patients

-- 2.Provide the second patient row 
Select * from patients
limit 1 
offset 1 

-- 3. how many patients are recently registered(in last 30 days)
Select * from patients
where registration_date >= (Select max(registration_date) - interval 30 day from patients)
order by registration_date desc;

select max(registration_date) - interval 30 day 
from patients

-- 4. how many doctors are available in hospital
Select count(*) from doctors

-- 5. what are distinct specialisation in the hospital

select distinct(specialization) from doctors

-- 6.sort the doctors based on experience and provide first and last name of doctor together
Select concat(first_name,' ',last_name) as Doctors_name, specialization, years_experience from doctors
order by years_experience desc


-- 7.find the doctors name ending with 'is' based on first name
Select First_name from doctors 
where first_name  like '%is';

-- 8.count dictinct phone no
Select count(distinct(phone_number))
from doctors

-- 9.what is total no of rows 
Select * from appointments
Select count(*) from appointments

-- 10.what is the appointment status distribution
Select status, count(*) from appointments
group by status

-- 11.provide me the status types whose count is more than 50
Select status, count(*) from appointments
group by status
Having count(*) > 50;

-- 12.find all the appointments in the last 7 days
Select *  from appointments 
where appointment_date >= (Select max(appointment_date) - interval 7 day from appointments)
order by appointment_date desc;

-- 13. find date wise count of status
Select  appointment_date, status, count(status) as status_count 
from appointments
group by appointment_date, status
order by appointment_date desc; 

-- 14.Most common treatment_type
Select treatment_type, count(*) from treatments
group by treatment_type
order by count(*) desc 
limit 1 ;

-- 15.find min cost, max cost, avg cost of the treatment
-- select * from treatments
Select min(cost), max(cost), round(avg(cost),1) 
from treatments

-- 16.PAYMENT STATUS DISTRIBUTION
Select * from billing
Select payment_status, count(*)
from billing 
group by payment_status;

Select * from patients
-- 17.how many patients are registered from each address?
Select address,  count(*) as patient_count 
from patients
group by address
order by patient_count desc;

-- 18. what is age distribution of patients?
Select patient_id, first_name, gender , timestampdiff(year, date_of_birth, curdate()) as age
from patients 
order by age desc;

-- 19. Age group segmentation
-- 18-35
-- 36-55
-- 56+


Select  
     case 
         when TIMESTAMPDIFF(year, date_of_birth, curdate()) < 18 Then 'Under_18'
         when TIMESTAMPDIFF(year,date_of_birth, curdate())  between 18 and 35 then 'adult' 
         when TIMESTAMPDIFF(year, date_of_birth, curdate()) between 36 and 55 Then 'matured'
         Else 'Seniors'
     end as age_group , 
count(*) as patient_count
from patients
group by age_group
order by patient_count desc;

-- 20.which email domains are most commonly used by patients
select substring_index(email, '@', -1) as email_domain,
count(*) as patient_count
from patients
group by email_domain;

-- 21.which month had higher patient registeration
-- Select * from patients

Select year(registration_date) as year,
month(registration_date) as month, 
count(*) as patient_count
from patients
group by year, month
order by patient_count desc;

-- 22. which month had higher patient registeration
Select month(registration_date) as month, 
count(*) as patient_count
from patients
group by month
order by patient_count desc;

-- 23.Which medical specialisation are most in demand based on appointment volume?
-- Select * from appointments

Select d.Specialization, count(a.appointment_id) as total_appointment
from doctors d 
join appointments a on d.doctor_id = a.doctor_id
group by d.specialization 
order by total_appointment desc;

-- 24.are critical specialization supported by senior experienced doctor or junior doctor?
-- Select * from doctors

Select Specialization, count(*) as total_doctors,
sum( case WHEN years_experience < 15 Then 1 else 0 end) as junoir_doc,
sum( case WHEN years_experience >= 15 Then 1 else 0 end) as senior_doc
from doctors
group by specialization;

-- 25. make a table/master data>> appointments with patient details and doctor specialzation
Select a.appointment_id, 
concat(p.first_name, ' ', p.last_name) as patient_name, 
concat(d.first_name,' ', d. last_name) as doctor_name, 
d.specialization, 
a.appointment_date, 
a.appointment_time, 
a.reason_for_visit, 
a.status  
from appointments a
join patients p 
on a.patient_id = p.patient_id
join doctors d 
on a.doctor_id = d.doctor_id
order by appointment_date desc 
limit 5

-- 26. which doctors are overloaded and which have available capacity based on appointment volume
Select  concat(d.first_name,' ', d.last_name) as doc_name,
d.specialization, 
count(a.appointment_id) as total_pa
from patients p 
join appointments a 
on p.patient_id = a.patient_id
join doctors d 
on a.doctor_id = d.doctor_id
group by doc_name, d.specialization
order by total_pa desc;

-- 27.build a big master data where we can see the entire journey of a patient >> from appointment>treatment>billing
Select concat(p.first_name, ' ', p.last_name) as patient_name, 
p.patient_id,
a.appointment_date, a.reason_for_visit,
a.appointment_id,
a.status,
t.treatment_id, 
t.treatment_type, 
t.cost,
b.bill_id, 
b.amount, 
b.payment_status 
From patients p
join appointments a on p.patient_id = a.patient_id
Left join treatments t on a.appointment_id = t.appointment_id
left join billing b on t.treatment_id = b.treatment_id

-- 28.what is total revenue generated by company
Select sum(amount) as revenue 
from billing
where payment_status = 'paid'

-- 29. -- Which patients contribute the most revenue
Select p.patient_id,
concat(p.first_name, ' ' , p.last_name) as patient_name,
amount) as total_amount
from patients p 
join billing b on p.patient_id = b.patient_id
where b.payment_status = 'paid'
group by p.patient_id, patient_name
order by total_amount desc;
 
-- 30.
-- RFM Segmentation 
-- Recency, Frequency and Monetary
-- Create RFM metrcis per patient using: last_visit, total_visit, paid_spend
-- label "champions", "Loyal high value", "risk"


WITH rfm AS (
  SELECT
    p.patient_id,
    CONCAT(p.first_name,' ',p.last_name) AS patient_name,
    MAX(a.appointment_date) AS last_visit,
    COUNT(DISTINCT a.appointment_id) AS frequency,
    COALESCE(SUM(CASE WHEN b.payment_status='Paid' THEN b.amount END),0) AS monetary
  FROM patients p
  LEFT JOIN appointments a ON a.patient_id = p.patient_id
  LEFT JOIN billing b ON b.patient_id = p.patient_id
  GROUP BY p.patient_id, patient_name
),
scored AS (
  SELECT
    *,
    DATEDIFF(CURDATE(), last_visit) AS recency_days,
    NTILE(4) OVER (ORDER BY DATEDIFF(CURDATE(), last_visit) ASC) AS r_score, -- lower recency better
    NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
    NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
  FROM rfm
)
SELECT
  patient_id, patient_name,
  recency_days, frequency, monetary,
  r_score, f_score, m_score,
  CONCAT(r_score,f_score,m_score) AS rfm_code,
  CASE
    WHEN r_score >=3 AND f_score >=3 AND m_score >=3 THEN 'Champions'
    WHEN f_score >=3 AND m_score >=3 THEN 'Loyal High Value'
    WHEN r_score <=2 AND f_score <=2 THEN 'At Risk / Inactive'
    WHEN f_score >=3 THEN 'Frequent Visitors'
    WHEN m_score >=3 THEN 'High Spenders'
    ELSE 'Regular'
  END AS segment
FROM scored
ORDER BY monetary DESC, frequency DESC;



-- 31.-- outlier detection
-- are there treatments with unusually high cost that require review

Select treatment_id, treatment_type, cost from treatments
where cost > (select avg(cost) + 2* stddev(cost) from treatments);

-- 32.Rank doctors by total appointment
Select d.Doctor_id , 
concat(d.first_name,' ', d.last_name) as doctor_name,
d.specialization,
count(appointment_id) as total_appointment
from appointments a 
join doctors d on d.doctor_id = a.doctor_id
group by doctor_name, d.doctor_id, d.specialization
order by total_appointment desc 
limit 5;

-- 33. Rank patients by total spending (VIP patients)
Select concat(p.first_name,' ', p.last_name) as patient_name, p.patient_id,
sum(b.amount),
rank() over(order by sum(b.amount) Desc) as spending_rnk
from patients p 
join billing b 
on p.patient_id = b.patient_id 
where b.payment_status = 'paid'
group by patient_name , p.patient_id;

-- 34.select treatement by frequency

Select treatment_type, count(*) as treatment_count
rank() over(order by count(*) Desc) as freq_rank
from treatments
group by treatment_type;









