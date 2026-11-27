# Bài 2: IAM nâng cao

Cần học xong [Bài 1](README.md) trước, và **giữ lại** bucket + role `lab-s3-reader` của Bài 1.

Học xong bài này anh sẽ biết 3 công cụ công ty dùng để giữ an toàn:
- **Permission boundary**: đặt hạn mức quyền tối đa
- **Bucket policy**: nội quy dán ngay tại tài nguyên
- **Kiểm tra policy tự động**: bắt lỗi trước khi áp dụng

Thời gian: khoảng 1 buổi.

## Checklist

- [ ] Phần 1: permission boundary
- [ ] Phần 2: bucket policy
- [ ] Phần 3: kiểm tra policy tự động
- [ ] Phần 4: dọn dẹp
- [ ] Đọc phần "Chuẩn doanh nghiệp"
- [ ] Trả lời 3 câu tự kiểm tra

## Chuẩn bị

Mở PowerShell mới thì chạy lại:

```powershell
cd C:\aws-iac-learning\00-aws-foundation\iam-lab
aws sso login --profile learn
. .\chuan-bi.ps1
```

---

## Phần 1: Permission boundary - hạn mức quyền

### Hiểu bằng ví dụ

Giống **hạn mức thẻ tín dụng**: dù cửa hàng "cho phép" anh mua món 100 triệu, thẻ có hạn mức 20 triệu thì vẫn không quẹt được.

- **Policy** = những gì được phép làm (cửa hàng cho mua gì)
- **Boundary** = trần tối đa (hạn mức thẻ)
- **Quyền thật** = phần **nằm trong cả hai**

Boundary **không cho thêm quyền**, nó chỉ chặn trên.

### Tình huống

Công ty cho team dev một role có quyền admin (`AdministratorAccess`) để tự do thử nghiệm, nhưng muốn chắc chắn team chỉ đụng được S3 và chỉ xem được EC2 ở Singapore. Đặc biệt **không được đụng IAM**, để không ai tự cấp thêm quyền cho mình.

Boundary nằm ở [policies/lab3-dev-boundary.json](policies/lab3-dev-boundary.json). Đọc thành câu:
- `MaxS3`: tối đa là mọi việc với S3
- `MaxEc2ReadOnlyInSingapore`: tối đa là **xem** EC2 (`ec2:Describe*`), và chỉ ở Singapore

### Làm

```powershell
aws iam create-policy --policy-name lab-dev-boundary --policy-document (Expand-Policy lab3-dev-boundary.json) --profile learn
aws iam create-role --role-name lab-dev --assume-role-policy-document (Expand-Policy trust-sso-admin.json) --permissions-boundary "arn:aws:iam::${AccountId}:policy/lab-dev-boundary" --profile learn
aws iam attach-role-policy --role-name lab-dev --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile learn
```

- Lệnh 1: lưu boundary thành một policy riêng.
- Lệnh 2: tạo role `lab-dev`, gắn **hạn mức** là boundary vừa tạo.
- Lệnh 3: cấp cho role quyền **admin toàn phần**.

Tạo profile để đeo thẻ `lab-dev` (giống Bài 1):

```powershell
aws configure set role_arn "arn:aws:iam::${AccountId}:role/lab-dev" --profile lab-dev
aws configure set source_profile learn --profile lab-dev
aws configure set region ap-southeast-1 --profile lab-dev
Start-Sleep 10
```

### Thử

| # | Thử làm gì | Lệnh | Kết quả đúng | Vì sao |
|---|---|---|---|---|
| 1 | Xem bảng lương | `aws s3 ls "s3://$Bucket/private/" --profile lab-dev` | Thấy `salary.txt` | Admin cho phép, boundary cũng cho S3 |
| 2 | Xem mạng ở Singapore | `aws ec2 describe-vpcs --region ap-southeast-1 --profile lab-dev` | Thấy danh sách VPC | Admin cho phép, boundary cho xem EC2 ở Singapore |
| 3 | Xem mạng ở Mỹ | `aws ec2 describe-vpcs --region us-east-1 --profile lab-dev` | UnauthorizedOperation | Boundary chỉ cho Singapore |
| 4 | Xem danh sách user | `aws iam list-users --profile lab-dev` | AccessDenied | Boundary không có IAM, dù role có quyền admin |

Lệnh 4 là điểm quan trọng nhất: **có quyền admin mà vẫn bị chặn**, vì vượt hạn mức.

---

## Phần 2: Bucket policy - nội quy dán tại cửa

### Hiểu bằng ví dụ

Tới giờ mình chỉ dùng policy gắn vào **người** (role), giống giấy phép cầm theo người. **Bucket policy** thì gắn vào **tài nguyên**, giống **nội quy dán ở cửa phòng**: ai bước vào cũng phải theo, bất kể giấy phép của họ ghi gì.

### Tình huống

Phòng chứa dữ liệu có 2 nội quy:
1. Chỉ được vào bằng **cửa an toàn** (HTTPS), cửa thường (HTTP) bị khoá.
2. **Chỉ admin được xoá file**, kể cả người có quyền `s3:*` cũng không được.

Nội quy nằm ở [policies/lab4-bucket-policy.json](policies/lab4-bucket-policy.json). Đọc thành câu:
- `DenyInsecureTransport`: **cấm** mọi người (`"Principal": "*"`) làm mọi việc với bucket, **nếu** không đi qua HTTPS.
- `DenyDeleteExceptSsoAdmin`: **cấm** mọi người xoá file, **trừ** role SSO `AdministratorAccess` của anh.

Cả hai đều là `Deny`, nên theo quy tắc vàng số 3 chúng luôn thắng.

### Làm

```powershell
aws s3api put-bucket-policy --bucket $Bucket --policy (Expand-Policy lab4-bucket-policy.json) --profile learn
```

Lệnh này "dán nội quy" lên cửa bucket.

### Thử

| # | Thử làm gì | Lệnh | Kết quả đúng | Vì sao |
|---|---|---|---|---|
| 1 | `lab-dev` xoá báo cáo | `aws s3 rm "s3://$Bucket/reports/q1.txt" --profile lab-dev` | AccessDenied | Nội quy cấm xoá, dù `lab-dev` có quyền `s3:*` |
| 2 | Anh đọc file qua HTTP | `aws s3api get-object --bucket $Bucket --key reports/q1.txt out/http.txt --endpoint-url http://s3.ap-southeast-1.amazonaws.com --profile learn` | AccessDenied | Nội quy cấm HTTP, kể cả admin |
| 3 | Anh đọc file qua HTTPS | `aws s3 cp "s3://$Bucket/reports/q1.txt" - --profile learn` | In ra "Bao cao quy 1" | Đi đúng cửa an toàn |

`--endpoint-url http://...` ở lệnh 2 ép AWS CLI đi qua HTTP. Bình thường CLI luôn dùng HTTPS.

Lưu ý: bucket policy có `"Principal": "*"` nhưng chỉ chứa `Deny` thì **không** làm bucket thành public. Chỉ `Allow` cho `*` mới mở public.

---

## Phần 3: Kiểm tra policy tự động

### Hiểu bằng ví dụ

Giống **phần mềm soát lỗi chính tả** trước khi gửi văn bản. Công ty không đợi tới lúc chạy thật mới biết policy sai.

AWS có 2 công cụ:
- **Access Analyzer**: đọc policy, báo lỗi sai cú pháp và chỗ nguy hiểm
- **Policy Simulator**: giả lập "nếu làm việc X thì có được không", không cần tạo role thật

### 3.1 Access Analyzer

File [policies/lab5-bad-policy.json](policies/lab5-bad-policy.json) có 3 lỗi cố ý. Anh đọc thử xem tìm được mấy lỗi, rồi chạy:

```powershell
aws accessanalyzer validate-policy --policy-type IDENTITY_POLICY --policy-document file://policies/lab5-bad-policy.json --profile learn --query "findings[].[findingType,issueCode]" --output table
```

Kết quả sẽ báo 2 lỗi:

| Báo gì | Nghĩa là |
|---|---|
| `ERROR INVALID_ACTION` | `s3:GetObjects` không tồn tại, đúng ra là `s3:GetObject` (thừa chữ `s`) |
| `SECURITY_WARNING PASS_ROLE_WITH_STAR_IN_RESOURCE` | Cho phép "trao thẻ bất kỳ" (`iam:PassRole` trên `*`). Người có quyền này có thể trao thẻ admin cho một máy EC2 do mình tạo, rồi mượn máy đó làm việc admin. Đây là lỗ hổng leo thang quyền rất kinh điển |

**Lỗi thứ 3 không bị báo:** `ec2:StartInstances` (bật máy EC2) nhưng `Resource` lại là bucket S3. Không khớp nhau nên dòng này vô tác dụng. Công cụ không bắt được hết lỗi.

### 3.2 Policy Simulator

Dùng simulator để bắt lỗi thứ 3, hỏi: *"policy này có cho bật máy EC2 không?"*

```powershell
aws iam simulate-custom-policy --policy-input-list (Get-Content policies/lab5-bad-policy.json -Raw) --action-names ec2:StartInstances --resource-arns "arn:aws:ec2:ap-southeast-1:${AccountId}:instance/i-0123456789abcdef0" --profile learn --query "EvaluationResults[].EvalDecision"
```

Kết quả `implicitDeny` (bị chặn vì không có `Allow` nào khớp): policy *trông như* cho bật máy nhưng thực tế không cho gì.

Bài học: **công cụ đọc policy không thay được việc thử hành vi thật.**

---

## Phần 4: Dọn dẹp toàn bộ

```powershell
aws s3 rb "s3://$Bucket" --force --profile learn

aws iam delete-role-policy --role-name lab-s3-reader --policy-name s3-read-reports --profile learn
aws iam delete-role --role-name lab-s3-reader --profile learn

aws iam detach-role-policy --role-name lab-dev --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --profile learn
aws iam delete-role --role-name lab-dev --profile learn
aws iam delete-policy --policy-arn "arn:aws:iam::${AccountId}:policy/lab-dev-boundary" --profile learn

Remove-Item -Recurse out
```

- Bucket xoá được vì nội quy chừa quyền xoá cho admin (anh).
- Role phải gỡ hết policy rồi mới xoá được.

Mở file `~/.aws/config`, xoá 2 mục `[profile lab-s3-reader]` và `[profile lab-dev]`.

Kiểm tra đã sạch (cả 2 lệnh không in ra gì là xong):

```powershell
aws iam list-roles --query "Roles[?starts_with(RoleName, 'lab-')].RoleName" --output text --profile learn
aws s3 ls --profile learn | Select-String iac-lab
```

---

## AWS quyết định cho hay không (bản đầy đủ)

Ghép Bài 1 và Bài 2 lại, AWS kiểm tra theo thứ tự:

```
1. Có Deny nào ở bất kỳ đâu không? (policy của người, bucket policy...)  → có: CHẶN
2. Có vượt trần không? (boundary, SCP)                                   → có: CHẶN
3. Có Allow nào khớp không?                                              → có: CHO PHÉP
4. Không có gì khớp                                                      → CHẶN (mặc định)
```

## Chuẩn doanh nghiệp

| Công ty làm gì | Vì sao |
|---|---|
| Tách nhiều account: dev, staging, prod riêng | Lỡ tay ở dev không ảnh hưởng prod |
| Nhân viên đăng nhập SSO, gán quyền theo **nhóm** (Developers, ReadOnly, Admins) | Nghỉ việc chỉ cần khoá một chỗ. Đổi vị trí chỉ cần đổi nhóm |
| Không ai giữ access key cố định | Người dùng SSO, server dùng role, CI/CD dùng OIDC |
| Đặt trần quyền bằng boundary và **SCP** (trần cho cả account) | Dù cấp nhầm quyền cũng không vượt quá giới hạn |
| Bucket policy bắt buộc HTTPS, chặn public | Bảo vệ dữ liệu ngay tại tài nguyên |
| Policy viết trong Terraform, CI chạy Access Analyzer trước khi merge | Bắt lỗi trước khi lên môi trường thật |

Lưu ý: account của anh hiện là **management account** (tài khoản quản lý) của Organization. SCP không áp dụng lên management account, nên công ty không chạy ứng dụng trong account này. Anh sẽ học tách account ở Giai đoạn 04.

## 3 câu tự kiểm tra

1. Role có `AdministratorAccess` nhưng boundary chỉ cho S3. Role này tạo IAM user được không?
2. Policy gắn vào role khác bucket policy ở điểm nào?
3. Vì sao `iam:PassRole` trên `*` nguy hiểm?

<details><summary>Đáp án</summary>

1. **Không.** Quyền thật là phần nằm trong cả policy lẫn boundary. Boundary không có IAM nên bị chặn.
2. Policy gắn vào role là "giấy phép cầm theo người": người này được làm gì. Bucket policy là "nội quy dán tại cửa": ai vào bucket này cũng phải theo.
3. Người có quyền này trao được thẻ mạnh (ví dụ admin) cho máy EC2 hoặc Lambda do mình tạo, rồi mượn máy đó làm những việc mình không được phép làm.
</details>

## Ghi chú

