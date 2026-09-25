"""Transcribe result cells without recomputing or changing source precision."""
import csv
import hashlib
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET
import zipfile

source = Path(sys.argv[1])
ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
with zipfile.ZipFile(source) as archive:
    root = ET.fromstring(archive.read("word/document.xml"))
tables = []
for table in root.findall(".//w:tbl", ns):
    tables.append([
        ["".join(t.text or "" for t in cell.findall(".//w:t", ns))
         for cell in row.findall("w:tc", ns)]
        for row in table.findall("w:tr", ns)
    ])
specs = [
    (1, "Select Dose 1", "0.30, 0.40, 0.50, 0.60"),
    (2, "Select Dose 2", "0.15, 0.30, 0.45, 0.60"),
    (3, "Select Dose 3", "0.05, 0.15, 0.30, 0.45"),
    (4, "Select Dose 4", "0.05, 0.10, 0.20, 0.30"),
    (5, "Select Dose 4 (highest available)", "0.05, 0.10, 0.15, 0.20"),
    (6, "No dose recommended", "0.45, 0.55, 0.65, 0.75"),
    (7, "Select Dose 4 (shallow gradient)", "0.15, 0.20, 0.25, 0.30"),
    (8, "Selection distribution (no favored dose)", "0.05, 0.10, 0.45, 0.60"),
    (8, "Above-target selection (Dose 3 or 4)", "0.05, 0.10, 0.45, 0.60"),
    (9, "Selection distribution (no favored dose)", "0.30, 0.30, 0.30, 0.30"),
    (9, "Select any dose 1-4 (all at target)", "0.30, 0.30, 0.30, 0.30"),
    (10, "Select Dose 4 (highest available)", "0.05, 0.05, 0.05, 0.05"),
    (10, "Select any dose 1-4 (all below target)", "0.05, 0.05, 0.05, 0.05"),
]
assert len(tables) == len(specs) == 13
records = []
sections = []
for index, (table, (scenario, endpoint, rates)) in enumerate(zip(tables, specs), 1):
    key = f"word_{index:02d}_scenario_{scenario}"
    distribution = table[0][0] == "Method"
    for row in table[1:]:
        for column, value in zip(table[0][1:], row[1:]):
            match = re.fullmatch(r"(\d+\.\d+) \((\d+\.\d+)\)", value)
            assert match, value
            method = row[0] if distribution else column.split(" ")[0]
            category = column if distribution else row[0]
            records.append(dict(figure=key, scenario=scenario, endpoint=endpoint,
                rates=rates, category=category, method=method, display=value,
                percentage=match[1], mcse=match[2]))
    if index == 9:
        continue  # Retain source data, but omit the above-target selection presentation.
    sections.extend([f"### Scenario {scenario}: {endpoint}", "",
        f"True DLT probabilities: **({rates})**.", "",
        f"![Scenario {scenario}: {endpoint}](docs/figures/{key}.png)", "",
        "<details>", "<summary>Exact source values: percentage (MCSE)</summary>", "",
        "| " + " | ".join(table[0]) + " |",
        "|" + "---|" * len(table[0])])
    sections.extend("| " + " | ".join(row) + " |" for row in table[1:])
    sections.extend(["", "</details>", ""])
data = Path("docs/data")
with (data / "word_all_results.csv").open("w", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=list(records[0]))
    writer.writeheader()
    writer.writerows(records)
(data / "word_source.json").write_text(json.dumps({
    "source": source.name, "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
    "tables": len(tables), "numeric_cells": len(records),
    "note": "Exact transcription of reported results; not a validation of simulation engines or safety equivalence."
}, indent=2) + "\n")
intro = ["## All reported scenario results", "",
    "The **12 displayed result tables** from **ALL SCENARIOS.docx** are shown below as thin-bar charts, including their reported favored-dose settings. The separate Scenario 8 above-target selection section is omitted. Expand each chart's table to see the exact percentages and MCSEs. No results have been rerun or substituted.", "",
    "These are historical reported values, not outputs of the independent local iBOIN engine. Official iBOIN safety equivalence to a uniform 0.90 cutoff remains unverified. iBOIN is unavailable for Scenarios 9 and 10; it is not represented as zero. BOIN is unchanged across prior settings within each scenario.", "",
    "Bar labels show the exact source percentage; error bars show +/- 1.96 times the reported MCSE. Rounding is retained. These intervals are descriptive Monte Carlo intervals, not clinical uncertainty intervals.", "",
    "Scenarios 1 and 2 contain no favored-Dose-4 row in the source; none has been invented. Scenario 8 shows the selection distribution, not MTD accuracy. For Scenario 10, any-dose selection is not target-dose accuracy: all doses are below target.", "",
    "The source's Scenario 8 iBOIN selection distribution sums to 100.02% at its displayed precision; these values are retained without normalization. The source's narrative conclusions are not copied as instructions or treated as verified superiority claims.", "",
    "[All source values (CSV)](docs/data/word_all_results.csv) | [Source provenance](docs/data/word_source.json) | [Separate independent local reruns](docs/data/protocol_performance.csv)", ""]
content = "\n".join(intro + sections)
readme = Path("README.md")
text = readme.read_text()
start = text.index("### Nine-scenario performance") if "### Nine-scenario performance" in text else text.index("## All reported scenario results")
end = text.index("### Outcome definitions", start)
readme.write_text(text[:start] + content + "\n" + text[end:])
Path("docs/protocol_results.md").write_text(content.replace(
    "](docs/", "](").rstrip() + "\n")
print(f"Transcribed {len(records)} numeric cells from {len(tables)} tables exactly.")
