# AWS IaC Learning

Lộ trình tự học Infrastructure as Code trên AWS, công cụ chính là Terraform (khoảng 10-12 tuần).

## Tiến độ

| Giai đoạn | Nội dung | Thời gian | Trạng thái |
|---|---|---|---|
| [00](00-aws-foundation/README.md) | Nền AWS | 1-2 tuần | [ ] |
| [01](01-terraform-basics/README.md) | Terraform cơ bản | 2 tuần | [ ] |
| [02](02-terraform-intermediate/README.md) | Terraform trung cấp | 2-3 tuần | [ ] |
| [03](03-quality-cicd/README.md) | Chất lượng và CI/CD | 2 tuần | [ ] |
| [04](04-advanced/README.md) | Nâng cao (chọn khi cần) | tuỳ | [ ] |

Mỗi giai đoạn có một thư mục: `README.md` chứa checklist và tài liệu, code thực hành đặt ngay trong thư mục đó.

## Quy tắc an toàn chi phí

- [x] Bật MFA cho root account, không dùng root để làm lab
- [x] Tạo AWS Budgets alert (ví dụ 5 USD/tháng) trước khi tạo bất kỳ tài nguyên nào
- [ ] Học xong mỗi buổi chạy `terraform destroy`
- [ ] Cẩn thận với tài nguyên tính tiền theo giờ: NAT Gateway, EKS control plane, RDS, ALB
- [ ] Không commit `*.tfstate`, `*.tfvars`, access key (đã chặn trong `.gitignore`)

## Tài liệu tổng hợp

- [roadmap.sh/terraform](https://roadmap.sh/terraform): khung lộ trình để đối chiếu
- [shuaibiyy/awesome-tf](https://github.com/shuaibiyy/awesome-tf): danh sách tổng hợp Terraform/OpenTofu
- [bregman-arie/devops-exercises](https://github.com/bregman-arie/devops-exercises): câu hỏi ôn Terraform và AWS
