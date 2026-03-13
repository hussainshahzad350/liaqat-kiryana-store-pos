import pathlib

screens = []
for path in pathlib.Path("lib/screens").rglob("*_screen.dart"):
    text = path.read_text()
    screens.append(
        {
            "screen": path.parent.name,
            "file": path.name,
            "lines": len(text.splitlines()),
            "import_count": sum(
                1 for line in text.splitlines() if line.strip().startswith("import ")
            ),
            "show_dialog": text.count("showDialog"),
            "dialog_widgets": text.count("Dialog("),
            "await": text.count("await "),
            "mounted": text.count("context.mounted"),
            "will_pop": text.count("WillPopScope"),
            "text_usage": text.count("Text("),
            "controllers": text.count("Controller"),
        }
    )

screens.sort(key=lambda s: s["lines"], reverse=True)
print(
    "Screen,File,Lines,Imports,ShowDialog,DialogWidgets,Await,Mounted,WillPopScope,TextUsage,Controllers"
)
for s in screens:
    print(
        f"{s['screen']},{s['file']},{s['lines']},{s['import_count']},{s['show_dialog']},{s['dialog_widgets']},{s['await']},{s['mounted']},{s['will_pop']},{s['text_usage']},{s['controllers']}"
    )
