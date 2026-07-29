# -*- coding: utf-8 -*-
import base64
import json
import os
import urllib.request
import zlib

FLOWS_DIR = os.path.join(os.path.dirname(__file__), "flows")

JOBS = [
    ("flow-00-overview.mmd", "00-总览-四条用户路径.png"),
    ("flow-A-preset.mmd", "A-浏览与选用预置场景.png"),
    ("flow-B-create.mmd", "B-创建自定义场景.png"),
    ("flow-C-manage.mmd", "C-管理已有自定义场景.png"),
    ("flow-D-newflow.mmd", "D-从新建流程选用场景.png"),
    ("flow-E-states.mmd", "E-状态机总图.png"),
]


def encode_mermaid(text: str) -> str:
    """mermaid.ink pako encoding (url-safe base64 of zlib-compressed JSON)."""
    payload = json.dumps({"code": text, "mermaid": {"theme": "default"}}, ensure_ascii=False)
    compressed = zlib.compress(payload.encode("utf-8"), level=9)
    return base64.urlsafe_b64encode(compressed).decode("ascii")


def download_png(code: str, out_path: str) -> None:
    encoded = encode_mermaid(code)
    url = f"https://mermaid.ink/img/pako:{encoded}?type=png&bgColor=white"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    with open(out_path, "wb") as f:
        f.write(data)
    print(f"OK  {out_path}  ({len(data)//1024} KB)")


def main():
    os.makedirs(FLOWS_DIR, exist_ok=True)
    for src_name, out_name in JOBS:
        src = os.path.join(FLOWS_DIR, src_name)
        out = os.path.join(FLOWS_DIR, out_name)
        with open(src, "r", encoding="utf-8") as f:
            code = f.read().strip()
        print(f"Rendering {src_name} ...")
        download_png(code, out)
    print("All done.")


if __name__ == "__main__":
    main()
