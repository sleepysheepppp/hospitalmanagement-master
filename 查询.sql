-- 1.1 查看所有医生的基本信息
SELECT '1. 医生基本信息（前10位）' as 查询标题;
SELECT 
    d.user_id as 医生ID,
    u.username as 用户名,
    u.first_name || ' ' || u.last_name as 姓名,
    d.department as 科室,
    d.mobile as 手机号,
    CASE d.status 
        WHEN 1 THEN '✅ 已批准'
        ELSE '⏳ 待审核'
    END as 状态
FROM hospital_doctor d
JOIN auth_user u ON d.user_id = u.id
ORDER BY d.department, u.last_name
LIMIT 10;


-- ========== 2. 条件查询：按条件筛选 ==========
-- 2.1 查找特定科室的医生
SELECT '3. 查找心内科的医生' as 查询标题;
SELECT 
    u.first_name || ' ' || u.last_name as 医生姓名,
    d.department as 科室,
    d.mobile as 联系电话
FROM hospital_doctor d
JOIN auth_user u ON d.user_id = u.id
WHERE d.department LIKE '%Cardiologist%' 
   OR d.department LIKE '%心脏%'
   OR d.department LIKE '%心内%'
ORDER BY d.status DESC;

-- 2.2 查找今天入院的患者
SELECT '4. 今日入院的患者' as 查询标题;
SELECT 
    u.first_name || ' ' || u.last_name as 患者姓名,
    p.symptoms as 症状,
    p.admitDate as 入院时间,
    TIME('now') as 当前时间
FROM hospital_patient p
JOIN auth_user u ON p.user_id = u.id
WHERE date(p.admitDate) = date('now')
AND p.status = 1;

-- 2.3 查找有特定症状的患者
SELECT '5. 查找有疼痛症状的患者' as 查询标题;
SELECT 
    u.first_name || ' ' || u.last_name as 患者姓名,
    p.symptoms as 症状,
    p.admitDate as 入院日期,
    CASE 
        WHEN p.symptoms LIKE '%Pain%' THEN '🔴 有疼痛'
        WHEN p.symptoms LIKE '%pain%' THEN '🔴 有疼痛'
        WHEN p.symptoms LIKE '%痛%' THEN '🔴 有疼痛'
        ELSE '其他症状'
    END as 症状类型
FROM hospital_patient p
JOIN auth_user u ON p.user_id = u.id
WHERE p.symptoms LIKE '%Pain%' 
   OR p.symptoms LIKE '%pain%'
   OR p.symptoms LIKE '%痛%'
ORDER BY p.admitDate DESC
LIMIT 10;

-- ========== 3. 排序查询：按不同字段排序 ==========
-- 3.1 按科室字母顺序排序医生
SELECT '6. 按科室排序的医生列表' as 查询标题;
SELECT 
    ROW_NUMBER() OVER (ORDER BY d.department) as 序号,
    d.department as 科室,
    u.first_name || ' ' || u.last_name as 医生姓名,
    d.mobile as 电话
FROM hospital_doctor d
JOIN auth_user u ON d.user_id = u.id
WHERE d.status = 1
ORDER BY d.department
LIMIT 15;

-- 3.2 按入院时间倒序排序患者
SELECT '7. 最新入院的患者' as 查询标题;
SELECT 
    ROW_NUMBER() OVER (ORDER BY p.admitDate DESC) as 排名,
    u.first_name || ' ' || u.last_name as 患者姓名,
    p.symptoms as 症状,
    p.admitDate as 入院日期,
    CASE 
        WHEN date('now') = date(p.admitDate) THEN '🆕 今天'
        WHEN julianday('now') - julianday(p.admitDate) <= 7 THEN '📅 一周内'
        ELSE '📆 更早'
    END as 入院时间
FROM hospital_patient p
JOIN auth_user u ON p.user_id = u.id
WHERE p.status = 1
ORDER BY p.admitDate DESC
LIMIT 10;

-- ========== 4. 分组查询：统计信息 ==========
-- 4.1 统计各科室医生数量
SELECT '8. 各科室医生数量统计' as 查询标题;
SELECT 
    d.department as 科室,
    COUNT(*) as 医生总数,
    SUM(CASE WHEN d.status = 1 THEN 1 ELSE 0 END) as 已批准,
    SUM(CASE WHEN d.status = 0 THEN 1 ELSE 0 END) as 待审核,
    ROUND(SUM(CASE WHEN d.status = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as 批准率
FROM hospital_doctor d
GROUP BY d.department
ORDER BY COUNT(*) DESC;

-- 4.2 统计每日入院患者数量
SELECT '9. 按日期统计患者入院数量' as 查询标题;
SELECT 
    date(p.admitDate) as 入院日期,
    COUNT(*) as 患者数量,
    GROUP_CONCAT(u.first_name || ' ' || LEFT(u.last_name, 1) || '.') as 患者姓名缩写
FROM hospital_patient p
JOIN auth_user u ON p.user_id = u.id
WHERE p.status = 1
GROUP BY date(p.admitDate)
ORDER BY date(p.admitDate) DESC
LIMIT 10;

-- 4.3 统计症状出现的频率
SELECT '10. 常见症状统计' as 查询标题;
SELECT 
    CASE 
        WHEN symptoms LIKE '%Pain%' OR symptoms LIKE '%痛%' THEN '疼痛类'
        WHEN symptoms LIKE '%Fever%' OR symptoms LIKE '%发烧%' OR symptoms LIKE '%热%' THEN '发热类'
        WHEN symptoms LIKE '%Cough%' OR symptoms LIKE '%咳嗽%' THEN '呼吸道类'
        WHEN symptoms LIKE '%Rash%' OR symptoms LIKE '%疹%' THEN '皮肤类'
        WHEN symptoms LIKE '%Allergy%' OR symptoms LIKE '%过敏%' THEN '过敏类'
        ELSE '其他症状'
    END as 症状分类,
    COUNT(*) as 患者数量,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospital_patient), 1) as 占比百分比,
    GROUP_CONCAT(SUBSTR(symptoms, 1, 15)) as 症状示例
FROM hospital_patient
WHERE status = 1
GROUP BY 症状分类
ORDER BY COUNT(*) DESC;

-- ========== 5. 关联查询：连接多个表 ==========
-- 5.1 查看患者及其主治医生
SELECT '11. 患者及其主治医生' as 查询标题;
SELECT 
    p.user_id as 患者ID,
    u_p.first_name || ' ' || u_p.last_name as 患者姓名,
    p.symptoms as 症状,
    d.department as 主治科室,
    u_d.first_name || ' ' || u_d.last_name as 主治医生,
    d.mobile as 医生电话,
    p.admitDate as 入院日期
FROM hospital_patient p
JOIN auth_user u_p ON p.user_id = u_p.id
LEFT JOIN hospital_doctor d ON p.assignedDoctorId = d.user_id
LEFT JOIN auth_user u_d ON d.user_id = u_d.id
WHERE p.status = 1
ORDER BY p.admitDate DESC
LIMIT 10;

-- 5.2 查看医生的预约情况
SELECT '12. 医生的预约统计' as 查询标题;
SELECT 
    d.user_id as 医生ID,
    u.first_name || ' ' || u.last_name as 医生姓名,
    d.department as 科室,
    COUNT(a.id) as 总预约数,
    SUM(CASE WHEN a.status = 1 THEN 1 ELSE 0 END) as 已批准,
    SUM(CASE WHEN a.status = 0 THEN 1 ELSE 0 END) as 待处理,
    SUM(CASE WHEN a.status = 2 THEN 1 ELSE 0 END) as 已完成,
    MIN(a.appointmentDate) as 最早预约,
    MAX(a.appointmentDate) as 最晚预约
FROM hospital_doctor d
JOIN auth_user u ON d.user_id = u.id
LEFT JOIN hospital_appointment a ON d.user_id = a.doctorId
WHERE d.status = 1
GROUP BY d.user_id
HAVING COUNT(a.id) > 0
ORDER BY COUNT(a.id) DESC
LIMIT 10;

-- 5.3 查看今日和明日的预约
SELECT '13. 近期预约（今日和明日）' as 查询标题;
SELECT 
    a.patientName as 患者姓名,
    a.doctorName as 医生姓名,
    a.appointmentDate as 预约时间,
    CASE 
        WHEN date(a.appointmentDate) = date('now') THEN '📅 今日'
        WHEN date(a.appointmentDate) = date('now', '+1 day') THEN '📅 明日'
        ELSE '未来'
    END as 预约日期,
    a.description as 预约事由,
    CASE a.status 
        WHEN 0 THEN '⏳ 待处理'
        WHEN 1 THEN '✅ 已批准'
        WHEN 2 THEN '✓ 已完成'
        ELSE '其他'
    END as 状态
FROM hospital_appointment a
WHERE date(a.appointmentDate) = date('now')
   OR date(a.appointmentDate) = date('now', '+1 day')
ORDER BY a.appointmentDate, a.status;

-- ========== 6. 实用查询：系统状态检查 ==========
-- 6.1 检查系统状态概览
SELECT '14. 医院管理系统状态概览' as 查询标题;
SELECT 
    '👨‍⚕️ 医生总数' as 项目,
    (SELECT COUNT(*) FROM hospital_doctor) as 数量,
    (SELECT COUNT(*) FROM hospital_doctor WHERE status=1) as 有效数量
UNION ALL
SELECT 
    '👨‍⚕️ 患者总数',
    (SELECT COUNT(*) FROM hospital_patient),
    (SELECT COUNT(*) FROM hospital_patient WHERE status=1)
UNION ALL
SELECT 
    '📅 预约总数',
    (SELECT COUNT(*) FROM hospital_appointment),
    (SELECT COUNT(*) FROM hospital_appointment WHERE status=1)
UNION ALL
SELECT 
    '👤 系统用户',
    (SELECT COUNT(*) FROM auth_user),
    (SELECT COUNT(*) FROM auth_user WHERE is_active=1)
UNION ALL
SELECT 
    '📊 今日新增患者',
    (SELECT COUNT(*) FROM hospital_patient WHERE date(admitDate)=date('now')),
    (SELECT COUNT(*) FROM hospital_patient WHERE date(admitDate)=date('now') AND status=1);

-- 6.2 检查数据完整性
SELECT '15. 数据完整性检查' as 查询标题;
SELECT 
    '未分配医生的患者' as 检查项目,
    COUNT(*) as 问题数量,
    GROUP_CONCAT(u.first_name || ' ' || u.last_name) as 涉及患者
FROM hospital_patient p
JOIN auth_user u ON p.user_id = u.id
WHERE p.assignedDoctorId IS NULL 
   OR p.assignedDoctorId NOT IN (SELECT user_id FROM hospital_doctor WHERE status=1)
   AND p.status = 1
UNION ALL
SELECT 
    '手机号缺失的医生',
    COUNT(*),
    GROUP_CONCAT(u.first_name || ' ' || u.last_name)
FROM hospital_doctor d
JOIN auth_user u ON d.user_id = u.id
WHERE d.mobile IS NULL OR d.mobile = ''
UNION ALL
SELECT 
    '症状描述为空的患者',
    COUNT(*),
    GROUP_CONCAT(u.first_name || ' ' || u.last_name)
FROM hospital_patient p
JOIN auth_user u ON p.user_id = u.id
WHERE p.symptoms IS NULL OR p.symptoms = '';

-- ========== 7. 格式化输出：美化显示 ==========
-- 7.1 医生目录（格式化输出）
SELECT '16. 医生目录（按科室分组）' as 查询标题;
WITH doctor_groups AS (
    SELECT 
        d.department as 科室,
        u.first_name || ' ' || u.last_name as 医生姓名,
        d.mobile as 联系电话,
        CASE d.status 
            WHEN 1 THEN '● 可预约'
            ELSE '○ 审核中'
        END as 状态,
        ROW_NUMBER() OVER (PARTITION BY d.department ORDER BY u.last_name) as 科室内序号
    FROM hospital_doctor d
    JOIN auth_user u ON d.user_id = u.id
    WHERE d.status = 1
)
SELECT 
    科室,
    GROUP_CONCAT(
        '  ' || 科室内序号 || '. ' || 医生姓名 || ' (' || 联系电话 || ') ' || 状态,
        CHAR(10)
    ) as 医生列表
FROM doctor_groups
GROUP BY 科室
ORDER BY 科室;

-- 7.2 患者快速查看表
SELECT '17. 患者快速查看表' as 查询标题;
SELECT 
    'ID: ' || p.user_id || 
    ' | 姓名: ' || u.first_name || ' ' || u.last_name ||
    ' | 症状: ' || SUBSTR(p.symptoms, 1, 15) || 
    CASE WHEN LENGTH(p.symptoms) > 15 THEN '...' ELSE '' END ||
    ' | 入院: ' || p.admitDate ||
    ' | 状态: ' || CASE p.status WHEN 1 THEN '住院' ELSE '待审' END
    as 患者信息
FROM hospital_patient p
JOIN auth_user u ON p.user_id = u.id
WHERE p.status = 1
ORDER BY p.admitDate DESC
LIMIT 15;

-- ========== 8. 时间相关查询 ==========
-- 8.1 本周活跃情况
SELECT '18. 本周医疗活动统计' as 查询标题;
SELECT 
    strftime('%w', a.appointmentDate) as 星期,
    CASE strftime('%w', a.appointmentDate)
        WHEN '0' THEN '周日'
        WHEN '1' THEN '周一'
        WHEN '2' THEN '周二'
        WHEN '3' THEN '周三'
        WHEN '4' THEN '周四'
        WHEN '5' THEN '周五'
        WHEN '6' THEN '周六'
    END as 星期名称,
    COUNT(*) as 预约数量,
    COUNT(DISTINCT a.doctorId) as 参与医生数,
    COUNT(DISTINCT a.patientId) as 涉及患者数
FROM hospital_appointment a
WHERE strftime('%Y-%W', a.appointmentDate) = strftime('%Y-%W', 'now')
GROUP BY strftime('%w', a.appointmentDate)
ORDER BY strftime('%w', a.appointmentDate);

-- 8.2 最近7天入院趋势
SELECT '19. 最近7天患者入院趋势' as 查询标题;
WITH dates AS (
    SELECT date('now', '-' || n || ' days') as day
    FROM (VALUES (0),(1),(2),(3),(4),(5),(6)) as t(n)
)
SELECT 
    d.day as 日期,
    CASE strftime('%w', d.day)
        WHEN '0' THEN '周日'
        WHEN '1' THEN '周一'
        WHEN '2' THEN '周二'
        WHEN '3' THEN '周三'
        WHEN '4' THEN '周四'
        WHEN '5' THEN '周五'
        WHEN '6' THEN '周六'
    END as 星期,
    COALESCE(p.admission_count, 0) as 入院人数,
    CASE 
        WHEN COALESCE(p.admission_count, 0) = 0 THEN '─'
        WHEN COALESCE(p.admission_count, 0) = 1 THEN '▏'
        WHEN COALESCE(p.admission_count, 0) = 2 THEN '▎'
        WHEN COALESCE(p.admission_count, 0) = 3 THEN '▍'
        WHEN COALESCE(p.admission_count, 0) >= 4 THEN '▌'
    END as 趋势图
FROM dates d
LEFT JOIN (
    SELECT 
        date(admitDate) as admit_day,
        COUNT(*) as admission_count
    FROM hospital_patient
    WHERE date(admitDate) >= date('now', '-7 days')
    GROUP BY date(admitDate)
) p ON d.day = p.admit_day
ORDER BY d.day DESC;