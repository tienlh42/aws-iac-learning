# 03 - Chất lượng và CI/CD (2 tuần)

Mục tiêu: Terraform chạy qua pipeline, có kiểm tra tự động, không ai `apply` từ máy cá nhân.

## Checklist

### Kiểm tra code
- [ ] `terraform fmt -check` và `terraform validate`
- [ ] [tflint](https://github.com/terraform-linters/tflint) với ruleset AWS
- [ ] Quét bảo mật bằng [checkov](https://github.com/bridgecrewio/checkov) hoặc [trivy](https://github.com/aquasecurity/trivy) (tfsec đã gộp vào trivy)
- [ ] Ước tính chi phí bằng [infracost](https://github.com/infracost/infracost)
- [ ] (Tuỳ chọn) pre-commit hook chạy fmt + tflint

### Pipeline (GitLab CI hoặc GitHub Actions)
- [ ] Đăng nhập AWS bằng OIDC, không lưu access key trong biến CI
- [ ] Mở MR → tự chạy `plan`, đăng kết quả plan
- [ ] Merge vào main → `apply` (có bước duyệt tay cho prod)
- [ ] Lưu plan file làm artifact, `apply` đúng plan đã duyệt

### Test
- [ ] `terraform test` (file `*.tftest.hcl`) cho 1 module
- [ ] Biết Terratest là gì và khi nào cần

### Dự án
- [ ] Gắn pipeline cho dự án ở giai đoạn 02

## Ghi chú

