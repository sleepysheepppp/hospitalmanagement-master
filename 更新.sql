-- 1. 更新医生状态
UPDATE hospital_doctor 
SET department = 'Updated Department' 
WHERE mobile = '1112223333';

-- 2. 更新患者症状
UPDATE hospital_patient 
SET symptoms = 'Updated: Fever and Headache' 
WHERE mobile = '4445556666';

-- 3. 更新预约状态
UPDATE hospital_appointment 
SET status = 1 
WHERE patientName = 'Test Patient';

SELECT '✅ 更新完成！' as message;