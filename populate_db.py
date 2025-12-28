import os
import django
from datetime import date, timedelta

# 配置Django环境
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hospitalmanagement.settings')
django.setup()

# 补充导入Group模型（关键修复）
from django.contrib.auth.models import User, Group
from hospital.models import Doctor, Patient, Appointment, PatientDischargeDetails

# -------------------------- 1. 创建管理员账号 --------------------------
def create_admin():
    """创建医院管理员（加入ADMIN组，可直接登录）"""
    admin_user = User.objects.create_user(
        username='hospital_admin',
        password='Admin@123456',  # 登录密码
        email='admin@hospital.com',
        first_name='Hospital',
        last_name='Admin'
    )
    # 关键：将管理员加入ADMIN组（匹配项目的is_admin判断逻辑）
    admin_group, created = Group.objects.get_or_create(name='ADMIN')
    admin_group.user_set.add(admin_user)
    print(f"✅ 管理员创建完成：用户名=hospital_admin，密码=Admin@123456（已加入ADMIN组）")
    return admin_user

# -------------------------- 2. 创建医生数据（待审核+已通过） --------------------------
def create_doctors():
    """创建6个医生（3个已通过审核，3个待审核），覆盖所有科室"""
    # 先获取/创建DOCTOR组
    doctor_group, _ = Group.objects.get_or_create(name='DOCTOR')
    
    doctor_data = [
        ('dr_heart', 'Doctor@123', 'John', 'Smith', '123 Heart St, NY', '12345678901', 'Cardiologist', True),
        ('dr_skin', 'Doctor@123', 'Emily', 'Davis', '456 Skin Ave, LA', '12345678902', 'Dermatologists', True),
        ('dr_emergency', 'Doctor@123', 'Michael', 'Brown', '789 Emergency Rd, CHI', '12345678903', 'Emergency Medicine Specialists', True),
        ('dr_allergy', 'Doctor@123', 'Lisa', 'Wilson', '321 Allergy Ln, TX', '12345678904', 'Allergists/Immunologists', False),
        ('dr_anesthesia', 'Doctor@123', 'David', 'Lee', '654 Anesthesia Dr, FL', '12345678905', 'Anesthesiologists', False),
        ('dr_colon', 'Doctor@123', 'Sarah', 'Clark', '987 Colon St, WA', '12345678906', 'Colon and Rectal Surgeons', False),
    ]
    
    created_doctors = []
    for idx, (username, pwd, fname, lname, addr, mobile, dept, status) in enumerate(doctor_data):
        user = User.objects.create_user(
            username=username,
            password=pwd,
            email=f'{username}@hospital.com',
            first_name=fname,
            last_name=lname
        )
        # 关键：将医生用户加入DOCTOR组
        doctor_group.user_set.add(user)
        
        doctor = Doctor.objects.create(
            user=user,
            address=addr,
            mobile=mobile,
            department=dept,
            status=status,  # 修复：添加逗号 ← 核心修改处1
            profile_pic=None  # 关键：为头像字段设空值
        )
        created_doctors.append(doctor)
        print(f"✅ 医生创建完成：{fname} {lname} | 科室={dept} | 审核状态={'已通过' if status else '待审核'}")
    return created_doctors

# -------------------------- 3. 创建患者数据（待审核+已入院+已出院） --------------------------
def create_patients(approved_doctors):
    """创建5个患者（1个待审核，2个已入院，2个已出院）"""
    # 先获取/创建PATIENT组
    patient_group, _ = Group.objects.get_or_create(name='PATIENT')
    
    patient_data = [
        ('pat_001', 'Patient@123', 'Tom', 'Green', '111 Main St, NY', '98765432101', 'Chest Pain', approved_doctors[0].user.id, False, False),
        ('pat_002', 'Patient@123', 'Amy', 'White', '222 Park Ave, LA', '98765432102', 'Skin Rash', approved_doctors[1].user.id, True, False),
        ('pat_003', 'Patient@123', 'Bob', 'Taylor', '333 Lake Rd, CHI', '98765432103', 'Severe Pain', approved_doctors[2].user.id, True, False),
        ('pat_004', 'Patient@123', 'Alice', 'Moore', '444 Hill Ln, TX', '98765432104', 'Allergy Reaction', approved_doctors[0].user.id, True, True),
        ('pat_005', 'Patient@123', 'Chris', 'King', '555 Beach Dr, FL', '98765432105', 'Stomach Ache', approved_doctors[1].user.id, True, True),
    ]
    
    created_patients = []
    for idx, (username, pwd, fname, lname, addr, mobile, symptoms, doc_id, status, is_discharged) in enumerate(patient_data):
        user = User.objects.create_user(
            username=username,
            password=pwd,
            email=f'{username}@hospital.com',
            first_name=fname,
            last_name=lname
        )
        # 关键：将患者用户加入PATIENT组
        patient_group.user_set.add(user)
        
        patient = Patient.objects.create(
            user=user,
            address=addr,
            mobile=mobile,
            symptoms=symptoms,
            assignedDoctorId=doc_id,
            admitDate=date.today() - timedelta(days=7) if is_discharged else date.today(),
            status=status,  # 修复：添加逗号 ← 核心修改处2
            profile_pic=None  # 关键：为头像字段设空值
        )
        created_patients.append((patient, is_discharged))
        print(f"✅ 患者创建完成：{fname} {lname} | 症状={symptoms} | 审核状态={'已通过' if status else '待审核'} | 出院状态={'已出院' if is_discharged else '未出院'}")
    return created_patients

# -------------------------- 4. 创建预约数据（待审核+已批准+已完成） --------------------------
def create_appointments(doctors, patients):
    """创建预约记录（覆盖不同状态）"""
    # 筛选已通过审核的医生和患者
    approved_doctors = [d for d in doctors if d.status]
    approved_patients = [p[0] for p in patients if p[0].status]
    
    appointment_data = [
        # (患者ID, 医生ID, 患者姓名, 医生姓名, 描述, 审核状态)
        (approved_patients[0].user.id, approved_doctors[0].user.id, approved_patients[0].get_name, approved_doctors[0].get_name, 'Follow up for chest pain', True),
        (approved_patients[1].user.id, approved_doctors[1].user.id, approved_patients[1].get_name, approved_doctors[1].get_name, 'Skin rash treatment', True),
        (approved_patients[2].user.id, approved_doctors[2].user.id, approved_patients[2].get_name, approved_doctors[2].get_name, 'Emergency checkup', False),
        (approved_patients[3].user.id, approved_doctors[0].user.id, approved_patients[3].get_name, approved_doctors[0].get_name, 'Allergy follow up (completed)', True),
    ]
    
    for idx, (pat_id, doc_id, pat_name, doc_name, desc, status) in enumerate(appointment_data):
        appointment = Appointment.objects.create(
            patientId=pat_id,
            doctorId=doc_id,
            patientName=pat_name,
            doctorName=doc_name,
            description=desc,
            status=status,
            appointmentDate=date.today() + timedelta(days=idx+1)  # 补充预约日期（模型必填）
        )
        print(f"✅ 预约创建完成：患者={pat_name} | 医生={doc_name} | 状态={'已批准' if status else '待审核'}")
    return

# -------------------------- 5. 创建出院详情（含发票数据） --------------------------
def create_discharge_details(patients, doctors):
    """为已出院患者创建出院详情和发票数据"""
    discharged_patients = [p[0] for p in patients if p[1]]  # 筛选已出院的患者
    approved_doctors = {d.user.id: d for d in doctors if d.status}
    
    for patient in discharged_patients:
        doctor = approved_doctors.get(patient.assignedDoctorId)
        if not doctor:
            continue
        
        admit_date = patient.admitDate
        release_date = date.today()
        day_spent = (release_date - admit_date).days
        
        # 费用计算
        room_charge = 1500 * day_spent
        doctor_fee = 5000
        medicine_cost = 3500
        other_charge = 1000
        total = room_charge + doctor_fee + medicine_cost + other_charge
        
        discharge = PatientDischargeDetails.objects.create(
            patientId=patient.user.id,
            patientName=patient.get_name,
            assignedDoctorName=doctor.get_name,
            address=patient.address,
            mobile=patient.mobile,
            symptoms=patient.symptoms,
            admitDate=admit_date,
            releaseDate=release_date,
            daySpent=day_spent,
            medicineCost=medicine_cost,
            roomCharge=room_charge,
            doctorFee=doctor_fee,
            OtherCharge=other_charge,
            total=total
        )
        print(f"✅ 出院详情创建完成：患者={patient.get_name} | 总费用={total} | 住院天数={day_spent}")
    return

# -------------------------- 主执行函数 --------------------------
if __name__ == '__main__':
    # 清空现有数据（可选，测试用）
    print("🗑️  清空现有测试数据...")
    # 按依赖顺序删除：先删子表，再删主表
    PatientDischargeDetails.objects.all().delete()
    Appointment.objects.all().delete()
    Patient.objects.all().delete()
    Doctor.objects.all().delete()
    # 只删除脚本创建的用户，避免误删其他数据
    User.objects.filter(username__in=['hospital_admin', 'dr_heart', 'dr_skin', 'dr_emergency', 'dr_allergy', 'dr_anesthesia', 'dr_colon', 'pat_001', 'pat_002', 'pat_003', 'pat_004', 'pat_005']).delete()
    
    # 按顺序创建数据
    admin = create_admin()
    doctors = create_doctors()
    patients = create_patients(doctors)
    create_appointments(doctors, patients)
    create_discharge_details(patients, doctors)
    
    print("\n🎉 所有测试数据填充完成！")
    print("📌 关键账号（可直接登录）：")
    print("   - 管理员：username=hospital_admin | password=Admin@123456")
    print("   - 已通过医生：username=dr_heart | password=Doctor@123")
    print("   - 已通过患者：username=pat_002 | password=Patient@123")