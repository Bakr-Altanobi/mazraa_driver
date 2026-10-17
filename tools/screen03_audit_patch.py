from pathlib import Path


def replace(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if old not in text:
        if new in text:
            return
        raise SystemExit(f"Expected text not found in {path}: {old[:120]!r}")
    file.write_text(text.replace(old, new))


replace(
    "lib/features/home/home_screen.dart",
    "operationalStatus: nextAccepting ? 1 : 0,",
    "operationalStatus: nextAccepting ? 3 : 1,",
)

models = Path("lib/core/models/app_models.dart")
text = models.read_text()
text = text.replace(
    "vehicleType: _enumLabel(json['vehicleType'], const [\n      'None',\n      'Motorcycle',\n      'Car',\n      'Van',\n      'Truck',\n    ]),",
    "vehicleType: _enumLabel(json['vehicleType'], const [\n      'Car',\n      'Bike',\n      'Van',\n      'Truck',\n    ]),",
)
text = text.replace(
    "approvalStatus: _enumLabel(json['approvalStatus'], const [",
    "approvalStatus: _oneBasedEnumLabel(json['approvalStatus'], const [",
)
text = text.replace(
    "operationalStatus: _enumLabel(json['operationalStatus'], const [\n      'Offline',\n      'Online',\n      'Busy',\n      'OnBreak',\n    ]),",
    "operationalStatus: _oneBasedEnumLabel(json['operationalStatus'], const [\n      'Offline',\n      'Online',\n      'Available',\n      'Busy',\n    ]),",
)
helper = """\nString _oneBasedEnumLabel(Object? value, List<String> labels) {\n  if (value is num) {\n    final index = value.toInt() - 1;\n    if (index >= 0 && index < labels.length) return labels[index];\n  }\n  return value?.toString() ?? labels.first;\n}\n"""
if "String _oneBasedEnumLabel" not in text:
    text += helper
models.write_text(text)

capture = Path(".github/scripts/capture-main-screen.sh")
text = capture.read_text()
text = text.replace(
    "grep -Eq \"أنت متصل|You are online\" artifacts/window.xml 2>/dev/null \\\n    && grep -Fq \"SHP-9101\" artifacts/window.xml 2>/dev/null \\\n    && grep -Fq \"YER\" artifacts/window.xml 2>/dev/null",
    "grep -Eq \"صباح الخير، عبدالرحمن|Good morning\" artifacts/window.xml 2>/dev/null \\\n    && grep -Eq \"طلبات اليوم|Today's orders\" artifacts/window.xml 2>/dev/null \\\n    && grep -Eq \"ابدأ استقبال الطلبات|Start receiving orders\" artifacts/window.xml 2>/dev/null",
)
text = text.replace(
    "if grep -Eq \"أنت متصل|You are online\" artifacts/window.xml 2>/dev/null; then\n      profile_ready=true\n    fi\n    if grep -Fq \"SHP-9101\" artifacts/window.xml 2>/dev/null; then\n      shipment_ready=true\n    fi\n    if grep -Fq \"YER\" artifacts/window.xml 2>/dev/null; then\n      wallet_ready=true\n    fi",
    "if grep -Eq \"صباح الخير، عبدالرحمن|Good morning\" artifacts/window.xml 2>/dev/null; then\n      profile_ready=true\n    fi\n    if grep -Eq \"طلبات اليوم|Today's orders\" artifacts/window.xml 2>/dev/null; then\n      shipment_ready=true\n    fi\n    if grep -Eq \"ابدأ استقبال الطلبات|Start receiving orders\" artifacts/window.xml 2>/dev/null; then\n      wallet_ready=true\n    fi",
)
capture.write_text(text)
