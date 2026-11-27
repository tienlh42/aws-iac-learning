# 02 - Terraform trung cấp (2-3 tuần)

Mục tiêu: tổ chức code để dùng lại được, làm việc nhóm được, tách nhiều môi trường.

## Checklist

### Remote state
- [ ] Backend S3 (bật versioning + encryption cho bucket state)
- [ ] State locking bằng `use_lockfile = true` (Terraform >= 1.10, không cần DynamoDB; tutorial cũ còn dùng DynamoDB)
- [ ] Di chuyển state local lên S3 bằng `terraform init -migrate-state`

### Module
- [ ] Tự viết 1 module (input variables, outputs, `README`)
- [ ] Dùng module từ Terraform Registry, khoá version
- [ ] Đọc code `terraform-aws-modules/terraform-aws-vpc` để học cách viết module chuẩn

### Ngôn ngữ
- [ ] `count` vs `for_each` (và vì sao nên ưu tiên `for_each`)
- [ ] `dynamic` block
- [ ] Hàm hay dùng: `merge`, `lookup`, `cidrsubnet`, `templatefile`
- [ ] `lifecycle`: `prevent_destroy`, `create_before_destroy`, `ignore_changes`

### Quản lý state và tài nguyên có sẵn
- [ ] `terraform import` / `import` block
- [ ] `moved` block khi đổi tên resource
- [ ] `terraform state mv`, `state rm` (biết khi nào cần, dùng cẩn thận)

### Nhiều môi trường
- [ ] So sánh workspaces vs tách thư mục theo môi trường (`envs/dev`, `envs/prod`)
- [ ] Chọn 1 cách và giải thích lý do vào phần ghi chú

### Dự án
- [ ] VPC (2 AZ) + ALB + EC2 hoặc ECS + RDS chạy một app Django
- [ ] Tách thành module: `network`, `app`, `database`
- [ ] Chạy được cho 2 môi trường dev và prod với biến khác nhau
- [ ] Destroy sạch sau khi xong

## Tài liệu

- [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [antonbabenko/terraform-best-practices](https://github.com/antonbabenko/terraform-best-practices): quy ước cấu trúc và đặt tên

## Ghi chú

