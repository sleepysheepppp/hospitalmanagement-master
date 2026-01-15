--几个基本表的查询
SELECT 'hospital_appointment 表结构:' as info;
PRAGMA table_info(hospital_appointment);

SELECT 'hospital_patient 表结构:' as info;
PRAGMA table_info(hospital_patient);

SELECT 'hospital_doctor 表结构:' as info;
PRAGMA table_info(hospital_doctor);



-- 1. 插入测试医生
INSERT INTO auth_user (username, password, email, first_name, last_name, is_staff, is_active, is_superuser, date_joined)
VALUES ('test_doc', 'pbkdf2_sha256$test123', 'test_doctor@example.com', 'Test', 'Doctor', 0, 1, 0, datetime('now'));

INSERT INTO hospital_doctor (user_id, address, mobile, department, status)
VALUES (last_insert_rowid(), '123 Test St', '1112223333', 'General', 1);

-- 2. 插入测试患者1
INSERT INTO auth_user (username, password, email, first_name, last_name, is_staff, is_active, is_superuser, date_joined)
VALUES ('test_pat', 'pbkdf2_sha256$test456', 'test_patient@example.com', 'Test', 'Patient', 0, 1, 0, datetime('now'));

INSERT INTO hospital_patient (user_id, address, mobile, symptoms, assignedDoctorId, admitDate, status)
VALUES (
    last_insert_rowid(),
    '456 Patient Ave',
    '4445556666',
    'Headache',
    last_insert_rowid() - 1,  -- 假设医生ID是上一个插入的ID
    date('now'),
    1
);

-- 3. 插入测试预约
INSERT INTO hospital_appointment (patientId, doctorId, patientName, doctorName, description, status, appointmentDate)
VALUES (
    last_insert_rowid() - 1,  -- 患者ID
    last_insert_rowid() - 2,  -- 医生ID
    'Test Patient',
    'Test Doctor',
    'Checkup',
    0,
    date('now', '+3 days')
);

-- 显示结果
SELECT '✅ 测试数据已重新插入' as 结果;
SELECT '医生:' as 类型, username, first_name, last_name FROM auth_user WHERE username = 'test_doc'
UNION ALL
SELECT '患者:', username, first_name, last_name FROM auth_user WHERE username = 'test_pat';