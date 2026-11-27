# 01 - Terraform cơ bản (2 tuần)

Mục tiêu: viết, plan, apply, destroy được một hạ tầng nhỏ trên AWS.

## Checklist

### Cài đặt
- [ ] Cài Terraform, kiểm tra `terraform version`
- [ ] Cài extension HashiCorp Terraform cho VS Code

### Khái niệm
- [ ] IaC là gì, declarative vs imperative
- [ ] Workflow: `init` → `plan` → `apply` → `destroy`
- [ ] `terraform` block, `required_providers`, khoá version provider
- [ ] `provider "aws"` và region
- [ ] `resource` vs `data` source
- [ ] `variable` (type, default, validation), `output`, `locals`
- [ ] Cách truyền biến: `-var`, `*.tfvars`, biến môi trường `TF_VAR_*`
- [ ] State: `terraform.tfstate` chứa gì, vì sao không commit
- [ ] Lệnh hay dùng: `fmt`, `validate`, `show`, `state list`, `output`
- [ ] Dependency ngầm (tham chiếu thuộc tính) vs `depends_on`

### Thực hành
- [ ] Lab 1: tạo 1 S3 bucket bằng Terraform, rồi destroy
- [ ] Lab 2: tạo EC2 + Security Group, output ra public IP
- [ ] Lab 3: sửa tay một tag trên console rồi chạy `plan` để thấy drift
- [ ] Dự án: host web tĩnh bằng S3 + CloudFront (OAC, bucket private)

## Tài liệu

- [hashicorp-education/learn-terraform-get-started-aws](https://github.com/hashicorp-education/learn-terraform-get-started-aws): tutorial chính thức
- [sidpalas/devops-directive-terraform-course](https://github.com/sidpalas/devops-directive-terraform-course): khoá từ cơ bản tới pro, có video miễn phí
- [MichaelCade/90DaysOfDevOps](https://github.com/MichaelCade/90DaysOfDevOps): phần IaC/Terraform

## Ghi chú

