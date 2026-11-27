# Bài 1: IAM cơ bản

Học xong bài này anh sẽ:
- Hiểu IAM là gì bằng một ví dụ đời thường
- Đọc được một policy JSON
- Tự tạo một role chỉ được đọc đúng một thư mục trong S3, rồi thử xem nó bị chặn ở đâu

Thời gian: khoảng 1 buổi. Chi phí: gần như 0.

Học xong bài này rồi mới qua [Bài 2: IAM nâng cao](bai-2-nang-cao.md).

## Checklist

- [ ] Phần 0: làm quen AWS CLI
- [ ] Phần 1: hiểu IAM bằng ví dụ tòa nhà
- [ ] Phần 2: đọc một policy
- [ ] Phần 3: làm bài tập đọc policy
- [ ] Phần 4: thực hành tạo role chỉ đọc S3
- [ ] Trả lời 3 câu tự kiểm tra

---

## Phần 0: Làm quen AWS CLI

Các lệnh dưới đây **chỉ đọc**, chạy thoải mái không tốn tiền và không làm hỏng gì. Output mẫu dùng account giả `111122223333`.

### Cấu trúc một lệnh

```
aws   s3    ls     --profile learn   --output table
 │    │     │      │                 │
 │    │     │      │                 └─ kiểu hiển thị kết quả
 │    │     │      └─ dùng danh tính nào
 │    │     └─ hành động
 │    └─ dịch vụ (s3, ec2, iam, sts...)
 └─ chương trình AWS CLI
```

Mọi lệnh đều theo khuôn `aws <dịch vụ> <hành động> [tuỳ chọn]`. Thực chất mỗi lệnh là một lời gọi API tới AWS qua HTTPS, kết quả trả về dạng JSON.

### 1. Kiểm tra phiên bản và cấu hình

```powershell
aws --version
aws configure list --profile learn
```

```
aws-cli/2.42.4 Python/3.14.10 Windows/11 exe/AMD64

NAME       : VALUE                    : TYPE             : LOCATION
profile    : learn                    : manual           : --profile
access_key : ****************KYHF     : sso              :
secret_key : ****************4LXE     : sso              :
region     : ap-southeast-1           : config-file      : ~/.aws/config
```

Cột `TYPE = sso` cho thấy key là **tạm thời**, lấy từ phiên đăng nhập SSO, không phải key cố định.

### 2. "Tôi đang là ai?" và 3 kiểu output

```powershell
aws sts get-caller-identity --profile learn
```

Mặc định ra **JSON** (dễ cho máy đọc):

```json
{
    "UserId": "AROAEXAMPLEID:Scott",
    "Account": "111122223333",
    "Arn": "arn:aws:sts::111122223333:assumed-role/AWSReservedSSO_AdministratorAccess_abc123/Scott"
}
```

Thêm `--output table` cho **bảng** (dễ cho người đọc):

```powershell
aws sts get-caller-identity --profile learn --output table
```

```
---------------------------------------------------------------------------------------------
|                                    GetCallerIdentity                                      |
+---------+---------------------------------------------------------------------------------+
|  Account|  111122223333                                                                   |
|  Arn    |  arn:aws:sts::111122223333:assumed-role/AWSReservedSSO_AdministratorAccess_.../Scott |
|  UserId |  AROAEXAMPLEID:Scott                                                            |
+---------+---------------------------------------------------------------------------------+
```

Thêm `--output text` cho **chữ thuần**, các cột cách nhau bằng tab (tiện để gán vào biến trong script):

```
111122223333	arn:aws:sts::111122223333:assumed-role/.../Scott	AROAEXAMPLEID:Scott
```

### 3. Lọc kết quả bằng `--query`

`--query` chọn đúng phần cần lấy trong JSON:

```powershell
aws sts get-caller-identity --profile learn --query Account --output text
```

```
111122223333
```

File `chuan-bi.ps1` dùng chính lệnh này để lấy account ID.

Lọc danh sách, đổi tên cột:

```powershell
aws ec2 describe-vpcs --profile learn --query "Vpcs[].{Id:VpcId,Cidr:CidrBlock,Default:IsDefault}" --output table
```

```
-------------------------------------------------------
|                    DescribeVpcs                     |
+----------------+----------+-------------------------+
|      Cidr      | Default  |           Id            |
+----------------+----------+-------------------------+
|  172.31.0.0/16 |  True    |  vpc-0example1234567    |
+----------------+----------+-------------------------+
```

Đọc `--query` như sau: `Vpcs[]` = lấy từng VPC trong danh sách, `{Id:VpcId, ...}` = chỉ giữ các trường này và đặt tên cột mới. Bỏ `--query` đi để thấy JSON gốc dài cỡ nào.

Lọc theo điều kiện:

```powershell
aws ec2 describe-regions --profile learn --query "Regions[?starts_with(RegionName,'ap-')].RegionName" --output text
```

```
ap-south-1	ap-northeast-3	ap-northeast-2	ap-northeast-1	ap-southeast-1	ap-southeast-2
```

`[?...]` = chỉ giữ phần tử thoả điều kiện, ở đây là region bắt đầu bằng `ap-` (châu Á - Thái Bình Dương).

### 4. Liệt kê bucket S3

```powershell
aws s3 ls --profile learn
```

```
2026-07-13 15:33:51 my-first-bucket
2026-05-01 04:09:34 aws-cloudtrail-logs-111122223333-abcd1234
```

`aws s3` là bộ lệnh "dễ dùng" giống lệnh file (`ls`, `cp`, `rm`). Muốn chi tiết hơn thì dùng `aws s3api`, gọi thẳng từng API của S3.

### 5. Khi lệnh bị lỗi

```powershell
aws s3 ls s3://bucket-khong-ton-tai-xyz-123 --profile learn
$LASTEXITCODE
```

```
aws: [ERROR]: An error occurred (NoSuchBucket) when calling the ListObjectsV2 operation: The specified bucket does not exist
254
```

Đọc lỗi theo 3 phần:
- `NoSuchBucket`: **mã lỗi**, dùng để tra Google hay docs.
- `ListObjectsV2`: **API** mà lệnh thực sự gọi. `aws s3 ls` bên dưới chính là `ListObjectsV2`.
- `254`: **exit code**. `0` là thành công, khác `0` là lỗi. Script dựa vào số này để biết lệnh chạy được hay không.

Hai lỗi anh sẽ gặp nhiều nhất:

| Lỗi | Nghĩa | Cách xử lý |
|---|---|---|
| `Token has expired` / `The SSO session has expired` | Phiên SSO hết hạn | `aws sso login --profile learn` |
| `AccessDenied` / `UnauthorizedOperation` | Không đủ quyền | Chạy `aws sts get-caller-identity` xem đang dùng đúng danh tính chưa, rồi xem policy |

### 6. Tự tra cứu

```powershell
aws s3 help
aws s3 ls help
```

Mở trang hướng dẫn của dịch vụ hoặc hành động, có cả ví dụ ở cuối. Bấm `Space` để sang trang, `q` để thoát.

---

## Phần 1: Hiểu IAM bằng ví dụ tòa nhà

Hãy tưởng tượng **tài khoản AWS là một tòa nhà văn phòng**, còn **IAM là phòng bảo vệ** quyết định ai được vào phòng nào.

| Trong tòa nhà | Trong AWS | Ghi nhớ |
|---|---|---|
| Chủ tòa nhà, có chìa khoá mọi phòng | **Root user** | Cất chìa khoá vào két (MFA), không dùng hằng ngày |
| Nhân viên có thẻ từ cố định | **IAM user** (có access key) | Mất thẻ là người khác dùng được mãi, nên công ty hạn chế loại này |
| Thẻ khách phát ở quầy, hết giờ tự khoá | **IAM role** | Ai được phép thì "nhận thẻ" (assume role), dùng xong tự hết hạn. **Đây là cách nên dùng** |
| Tờ giấy ghi "thẻ này mở được phòng nào" | **Policy** | Viết bằng JSON |
| Danh sách "ai được nhận thẻ khách này" | **Trust policy** | Mỗi role có một danh sách như vậy |

Khi anh đăng nhập portal SSO lúc nãy, thực chất anh đang **nhận một thẻ khách** tên `AdministratorAccess`. Thẻ hết hạn sau vài giờ, đó là lý do thỉnh thoảng phải `aws sso login` lại.

---

## Phần 2: Đọc một policy

Mỗi policy trả lời 4 câu hỏi: **Cho hay cấm? Làm gì? Với cái gì? Khi nào?**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/reports/*",
      "Condition": { "Bool": { "aws:SecureTransport": "true" } }
    }
  ]
}
```

Dịch ra tiếng Việt:

| Dòng | Câu hỏi | Nghĩa |
|---|---|---|
| `"Effect": "Allow"` | Cho hay cấm? | **Cho phép** |
| `"Action": "s3:GetObject"` | Làm gì? | **Tải file** từ S3 |
| `"Resource": ".../reports/*"` | Với cái gì? | Các file trong thư mục `reports/` của bucket `my-bucket` |
| `"Condition": ...` | Khi nào? | Chỉ khi kết nối bằng **HTTPS** |

Đọc cả câu: *"Cho phép tải file trong `reports/` của `my-bucket`, nếu đi qua HTTPS."*

Hai dòng còn lại không cần nghĩ nhiều:
- `"Version": "2012-10-17"`: luôn ghi đúng như vậy, đây là phiên bản ngôn ngữ policy, không phải ngày tạo.
- `"Statement": [...]`: danh sách các điều khoản. Một policy có thể có nhiều điều khoản.

### 3 quy tắc vàng

1. **Mặc định là cấm.** Không có dòng nào cho phép thì bị chặn.
2. **Muốn làm được thì phải có `Allow`.**
3. **`Deny` luôn thắng.** Chỉ cần một dòng `Deny` là mọi `Allow` khác đều vô tác dụng, giống biển "CẤM VÀO" dán ở cửa.

### Một điểm hay nhầm: bucket và file

S3 có hai loại "cái gì":
- **Bucket** (cái tủ): `arn:aws:s3:::my-bucket`. Ví dụ hành động "xem trong tủ có gì" (`s3:ListBucket`).
- **File** (giấy tờ trong tủ): `arn:aws:s3:::my-bucket/*`. Ví dụ hành động "lấy một tờ ra" (`s3:GetObject`).

Ghi nhầm loại thì policy không có tác dụng.

---

## Phần 3: Bài tập đọc policy

Tự trả lời trước rồi mới bấm xem đáp án.

**Câu 1**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::data-bucket/*" }
  ]
}
```

Người có policy này **xem danh sách file** trong `data-bucket` được không?

<details><summary>Đáp án</summary>

**Không.** Policy chỉ cho "lấy một tờ ra" (`GetObject`), không cho "xem trong tủ có gì" (`ListBucket`). Người này tải được file nếu biết chính xác tên, nhưng không liệt kê được.
</details>

**Câu 2**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "s3:*", "Resource": "*" },
    { "Effect": "Deny", "Action": "s3:DeleteObject", "Resource": "*" }
  ]
}
```

`s3:*` nghĩa là mọi hành động với S3. Vậy người này **xoá file** được không?

<details><summary>Đáp án</summary>

**Không.** Dòng 1 cho phép mọi thứ, nhưng dòng 2 cấm xoá. Quy tắc vàng số 3: `Deny` luôn thắng.
</details>

**Câu 3**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*",
      "Condition": { "StringEquals": { "aws:RequestedRegion": "ap-southeast-1" } }
    }
  ]
}
```

Người này tạo máy EC2 ở **Mỹ** (`us-east-1`) được không?

<details><summary>Đáp án</summary>

**Không.** Điều kiện chỉ cho phép khi làm ở Singapore (`ap-southeast-1`). Ở region khác thì không có `Allow` nào khớp → quy tắc vàng số 1: mặc định là cấm. Công ty hay dùng cách này để nhân viên không lỡ tạo máy ở region lạ rồi quên tắt.
</details>

---

## Phần 4: Thực hành - tạo role chỉ đọc một thư mục S3

**Tình huống:** có một bucket chứa 2 thư mục:
- `reports/`: báo cáo, team báo cáo được đọc
- `private/`: bảng lương, tuyệt đối không cho xem

Mình sẽ tạo một "thẻ khách" (role) tên `lab-s3-reader` chỉ mở được `reports/`, rồi đeo thẻ đó vào thử.

### Bước 1: Chuẩn bị

Mở PowerShell, chạy từng lệnh:

```powershell
cd C:\aws-iac-learning\00-aws-foundation\iam-lab
aws sso login --profile learn
. .\chuan-bi.ps1
```

- Lệnh 2: đăng nhập lại cho chắc phiên chưa hết hạn.
- Lệnh 3 (có dấu chấm và dấu cách ở đầu): chạy file [chuan-bi.ps1](chuan-bi.ps1). File này lấy account ID của anh, đặt tên bucket là `iac-lab-<account-id>`, và tạo sẵn lệnh `Expand-Policy`.

**`Expand-Policy` để làm gì?** Các file policy trong thư mục `policies/` ghi `<ACCOUNT_ID>` và `<BUCKET>` thay cho giá trị thật, vì repo đang public. `Expand-Policy` giống máy photo điền sẵn tên: nó copy file policy, điền giá trị thật vào, lưu vào thư mục `out/` (không bị đẩy lên GitHub).

Tạo bucket và 2 file mẫu:

```powershell
aws s3 mb "s3://$Bucket" --profile learn
Set-Content out/q1.txt "Bao cao quy 1"
Set-Content out/salary.txt "Bang luong bi mat"
aws s3 cp out/q1.txt "s3://$Bucket/reports/q1.txt" --profile learn
aws s3 cp out/salary.txt "s3://$Bucket/private/salary.txt" --profile learn
```

- `s3 mb` (make bucket): tạo bucket.
- `Set-Content`: tạo file text trên máy.
- `s3 cp`: upload file lên S3. Tên `reports/q1.txt` tự tạo "thư mục" `reports/`.

### Bước 2: Đọc 2 file policy của role

Một role luôn cần **2 tờ giấy**:

**Tờ 1: Ai được nhận thẻ này** ([policies/trust-sso-admin.json](policies/trust-sso-admin.json))

Đọc theo 4 câu hỏi: *"Cho phép (`Allow`) nhận thẻ (`sts:AssumeRole`), người nhận phải là role SSO `AdministratorAccess` trong account của anh (`Condition`)."* Nghĩa là chỉ anh (khi đăng nhập SSO) mới đeo được thẻ này.

**Tờ 2: Thẻ này mở được gì** ([policies/lab2-s3-reader.json](policies/lab2-s3-reader.json))

Có 2 điều khoản:

| Điều khoản | Đọc thành câu |
|---|---|
| `ListOnlyReportsPrefix` | Cho phép **xem danh sách** trong bucket, nhưng chỉ khi đang xem thư mục `reports/` |
| `ReadReportsObjects` | Cho phép **tải file** nằm trong `reports/` |

Không có điều khoản nào cho `private/` hay cho ghi file → theo quy tắc vàng số 1, những việc đó bị cấm.

### Bước 3: Tạo role

```powershell
aws iam create-role --role-name lab-s3-reader --assume-role-policy-document (Expand-Policy trust-sso-admin.json) --profile learn
aws iam put-role-policy --role-name lab-s3-reader --policy-name s3-read-reports --policy-document (Expand-Policy lab2-s3-reader.json) --profile learn
```

- Lệnh 1: tạo role kèm **tờ 1** (ai được nhận thẻ).
- Lệnh 2: gắn **tờ 2** (thẻ mở được gì) vào role.

### Bước 4: Tạo profile để "đeo thẻ"

```powershell
aws configure set role_arn "arn:aws:iam::${AccountId}:role/lab-s3-reader" --profile lab-s3-reader
aws configure set source_profile learn --profile lab-s3-reader
aws configure set region ap-southeast-1 --profile lab-s3-reader
Start-Sleep 10
aws sts get-caller-identity --profile lab-s3-reader
```

- 3 lệnh `configure set` tạo profile `lab-s3-reader` trong `~/.aws/config`. Ý nghĩa: *"dùng danh tính `learn` để đi nhận thẻ `lab-s3-reader`"*.
- `Start-Sleep 10`: đợi 10 giây. Role mới tạo cần vài giây để AWS cập nhật ở mọi nơi.
- `get-caller-identity`: hỏi "tôi đang là ai". Thấy chữ `assumed-role/lab-s3-reader` là đã đeo thẻ thành công.

### Bước 5: Thử thẻ

Chạy từng lệnh, so với cột "Kết quả đúng":

| # | Thử làm gì | Lệnh | Kết quả đúng | Vì sao |
|---|---|---|---|---|
| 1 | Xem thư mục `reports/` | `aws s3 ls "s3://$Bucket/reports/" --profile lab-s3-reader` | Thấy `q1.txt` | Có điều khoản cho xem `reports/` |
| 2 | Đọc báo cáo | `aws s3 cp "s3://$Bucket/reports/q1.txt" - --profile lab-s3-reader` | In ra "Bao cao quy 1" | Có điều khoản cho tải file trong `reports/` |
| 3 | Xem thư mục `private/` | `aws s3 ls "s3://$Bucket/private/" --profile lab-s3-reader` | AccessDenied | Chỉ được xem `reports/` |
| 4 | Đọc bảng lương | `aws s3 cp "s3://$Bucket/private/salary.txt" - --profile lab-s3-reader` | AccessDenied (403) | Không có điều khoản nào cho `private/` |
| 5 | Upload file | `aws s3 cp out/q1.txt "s3://$Bucket/reports/new.txt" --profile lab-s3-reader` | AccessDenied | Không có điều khoản cho ghi |

Dấu `-` ở cuối lệnh 2 và 4 nghĩa là "in nội dung file ra màn hình" thay vì lưu thành file.

Cả 5 lệnh ra đúng là anh đã làm được **least privilege** (cấp quyền tối thiểu): thẻ chỉ mở đúng cánh cửa cần mở.

### Bước 6: Dọn dẹp (chỉ khi không học tiếp Bài 2)

Bài 2 dùng lại bucket và role này. Nếu anh **chưa** học tiếp ngay, chạy:

```powershell
aws s3 rb "s3://$Bucket" --force --profile learn
aws iam delete-role-policy --role-name lab-s3-reader --policy-name s3-read-reports --profile learn
aws iam delete-role --role-name lab-s3-reader --profile learn
```

- `s3 rb --force`: xoá hết file rồi xoá bucket.
- Phải gỡ policy khỏi role trước thì mới xoá được role.

---

## Ở công ty thật làm thế nào?

- Nhân viên đăng nhập qua SSO giống anh đang làm, không ai được cấp access key cố định.
- Server (EC2, Lambda) cũng dùng role, không nhúng key vào code hay file `.env`.
- Policy không tạo bằng tay như bài này mà viết trong Terraform, review qua merge request trước khi áp dụng. Anh sẽ học cách này ở Giai đoạn 01.

## 3 câu tự kiểm tra

1. Role khác IAM user ở điểm nào? Vì sao công ty thích role hơn?
2. Một policy có cả `Allow s3:*` và `Deny s3:DeleteObject`. Kết quả là gì?
3. Vì sao lệnh 4 ở Bước 5 bị chặn, dù policy không có dòng `Deny` nào?

<details><summary>Đáp án</summary>

1. Role không có mật khẩu hay key cố định, chỉ cấp "thẻ tạm" có hạn dùng. Lộ thẻ tạm thì một lúc sau nó tự hết hạn. Lộ key của IAM user thì người khác dùng được mãi tới khi bị phát hiện.
2. Làm được mọi thứ với S3, **trừ xoá file**. `Deny` luôn thắng.
3. Quy tắc vàng số 1: mặc định là cấm. Không có `Allow` nào cho `private/` thì tự động bị chặn, không cần `Deny`.
</details>

## Ghi chú

