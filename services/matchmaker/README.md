> **Legacy 1.0.x service.** This allocator is retained for historical reference. The 1.1.0 deployment uses `services/directory/` and does not run game processes on the NAS. See [current NAS setup](../../nas/README.md).

# Matchmaker service source

Linux/NAS 설치 및 운영: [nas/README.md](../../nas/README.md).

이 폴더는 FastAPI 로비·입장권·방 수명 관리와 Docker 이미지 빌드 소스입니다. 실제 배포 파일 `compose.yaml`, `Caddyfile`, `.env.example`은 저장소 루트의 `nas/`에 있습니다. Windows 실행 안내는 [windows/README.md](../../windows/README.md)를 확인하세요.
