-- 1. 统计总数
SELECT '=== 基本统计 ===' as title;
SELECT 
    '医生总数' as 类型,
    COUNT(*) as 数量
FROM hospital_doctor
UNION ALL
SELECT 
    '患者总数',
    COUNT(*)
FROM hospital_patient
UNION ALL
SELECT 
    '预约总数',
    COUNT(*)
FROM hospital_appointment;

-- 2. 医生状态统计
SELECT '=== 医生状态 ===' as title;
SELECT 
    CASE status 
        WHEN 1 THEN '已批准'
        ELSE '待审核'
    END as 状态,
    COUNT(*) as 数量
FROM hospital_doctor
GROUP BY status;

-- 3. 患者状态统计
SELECT '=== 患者状态 ===' as title;
SELECT 
    CASE status 
        WHEN 1 THEN '已入院'
        ELSE '待审核'
    END as 状态,
    COUNT(*) as 数量
FROM hospital_patient
GROUP BY status;

-- 4. 预约状态统计
SELECT '=== 预约状态 ===' as title;
SELECT 
    CASE status 
        WHEN 0 THEN '待处理'
        WHEN 1 THEN '已批准'
        ELSE '已完成'
    END as 状态,
    COUNT(*) as 数量
FROM hospital_appointment
GROUP BY status;