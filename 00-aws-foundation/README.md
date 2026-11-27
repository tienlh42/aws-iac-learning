# 00 - Nền AWS (1-2 tuần)

Mục tiêu: hiểu các dịch vụ lõi đủ để biết Terraform đang tạo ra cái gì.

## Checklist

### Tài khoản và bảo mật
- [ ] Tạo AWS account, bật MFA cho root
- [ ] Tạo IAM user (hoặc IAM Identity Center) riêng để làm lab
- [ ] Tạo AWS Budgets alert
- [ ] Cài AWS CLI, chạy `aws configure` (hoặc `aws configure sso`), kiểm tra bằng `aws sts get-caller-identity`

### IAM
- [ ] Phân biệt user, group, role, policy
- [ ] Đọc hiểu một policy JSON (Effect, Action, Resource, Condition)
- [ ] Hiểu least privilege và vì sao EC2 nên dùng role thay vì access key

### VPC và network
- [ ] VPC, CIDR, subnet public/private
- [ ] Internet Gateway, NAT Gateway, route table
- [ ] Security Group vs Network ACL
- [ ] Tự vẽ sơ đồ một VPC 2 AZ, mỗi AZ có 1 public + 1 private subnet

### Compute, storage, database
- [ ] EC2: AMI, instance type, key pair, user data
- [ ] S3: bucket, object, bucket policy, versioning, chặn public access
- [ ] RDS: engine, subnet group, vì sao đặt trong private subnet
- [ ] Biết ALB, CloudFront, Route 53 dùng để làm gì

### Thực hành tay (ClickOps) để so sánh với IaC sau này
- [ ] Tạo bằng console: 1 VPC, 1 EC2 public chạy nginx, SSH/SSM vào được
- [ ] Xoá sạch tất cả, ghi lại số bước đã làm vào phần ghi chú

## Tài liệu

- [open-guides/og-aws](https://github.com/open-guides/og-aws): hướng dẫn thực chiến AWS (ít cập nhật từ 2024, khái niệm vẫn dùng tốt)
- [roadmap.sh/aws](https://roadmap.sh/aws)

## Ghi chú

