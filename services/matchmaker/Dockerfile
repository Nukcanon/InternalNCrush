FROM python:3.13-slim-bookworm
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libfontconfig1 libx11-6 libxcursor1 libxinerama1 libgl1 libxi6 libxrandr2 libasound2 libpulse0 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY services/matchmaker/requirements.txt /app/services/matchmaker/requirements.txt
RUN pip install --no-cache-dir -r services/matchmaker/requirements.txt
COPY services/matchmaker/fetch_godot.py /tmp/fetch_godot.py
RUN python /tmp/fetch_godot.py "$TARGETARCH"
COPY games/relaystrike /app/games/relaystrike
COPY services/matchmaker /app/services/matchmaker
RUN python games/relaystrike/tools/prepare_assets.py && godot --headless --path games/relaystrike --editor --import --quit && godot --headless --path games/relaystrike --script res://tools/build_models.gd && godot --headless --path games/relaystrike --editor --import --quit
RUN useradd --create-home --uid 10001 arena && chown -R arena:arena /app
USER arena
ENV GODOT=godot PYTHONUNBUFFERED=1 MAX_ROOMS=4
EXPOSE 8080 27900 27901 27902 27903
CMD ["python", "-m", "uvicorn", "services.matchmaker.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1", "--proxy-headers", "--forwarded-allow-ips", "*", "--limit-concurrency", "128", "--timeout-keep-alive", "5", "--no-access-log"]
