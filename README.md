# Edumy Project

Repository tổng hợp chứa cả phiên bản Web và Mobile App của **Edumy** dưới dạng **Git Submodules** (mỗi phần là một repository độc lập):

- **`Edumy-main/`** — Bản Web & Backend ([`bac1234556/Edumy`](https://github.com/bac1234556/Edumy))
- **`Edumy-App/`** — Bản Mobile App ([`bac1234556/Edumy-App`](https://github.com/bac1234556/Edumy-App))

## Hướng dẫn sử dụng

### Clone toàn bộ project (bao gồm cả 2 repo con)

```bash
git clone --recursive https://github.com/bac1234556/Edumy-Project.git
```

Nếu đã clone mà chưa có code bên trong 2 thư mục con:

```bash
git submodule update --init --recursive
```

### Cập nhật code mới nhất từ cả 2 repo con

```bash
git submodule update --remote --merge
```
