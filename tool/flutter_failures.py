"""Izlasa `flutter test --reporter json` izvadi un izdrukā kritušos testus kā GitHub anotācijas."""
import json
import sys

names, failed = {}, []
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.strip()
    if not line.startswith("{"):
        continue
    e = json.loads(line)
    if e.get("type") == "testStart":
        names[e["test"]["id"]] = e["test"]["name"]
    elif e.get("type") == "error":
        msg = (e.get("error", "") + "\n" + e.get("stackTrace", ""))[:1500]
        failed.append((names.get(e["testID"], "?"), msg))
for name, msg in failed:
    print(f"::error title={name}::" + msg.replace("%", "%25").replace("\r", "").replace("\n", "%0A"))
sys.exit(1 if failed else 0)
