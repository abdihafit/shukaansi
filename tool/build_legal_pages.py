"""Builds the public legal pages from the documents bundled in the app.

    python tool/build_legal_pages.py

Reads assets/legal/{terms,privacy}_{en,so}.md and writes web/legal/*.html.
Flutter copies web/ into build/web, which Firebase Hosting serves, so the
pages appear at /legal/terms.html, /legal/privacy.html and the -so variants.
Run it whenever a document changes, then rebuild and deploy the web app.
"""

import html
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'assets' / 'legal'
OUT = ROOT / 'web' / 'legal'

DOCS = {
    'terms': {'en': 'Terms of Use', 'so': 'Shuruudaha Isticmaalka'},
    'privacy': {'en': 'Privacy Policy', 'so': 'Siyaasadda Asturnaanta'},
}
LANGUAGE_NAMES = {'en': 'English', 'so': 'Soomaali'}

STYLE = """
:root { color-scheme: light dark; --bg: #FAF7EE; --text: #1B2A26; --muted: #55625E;
  --brand: #064E43; --gold: #C99734; --card: #FFFFFF; --line: #E4DED0; }
@media (prefers-color-scheme: dark) { :root { --bg: #10251F; --text: #EEF3F0;
  --muted: #B5C2BD; --brand: #8FD3C2; --card: #16302A; --line: #2A4740; } }
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text);
  font: 17px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
header { border-bottom: 3px solid var(--gold); background: var(--card); }
.bar { max-width: 760px; margin: 0 auto; padding: 16px; display: flex;
  justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
.brand { font-weight: 700; letter-spacing: 0.18em; color: var(--brand); }
nav a { color: var(--brand); margin-left: 12px; text-decoration: none; font-weight: 600;
  display: inline-block; padding: 8px 4px; }
nav a[aria-current] { text-decoration: underline; text-underline-offset: 4px; }
main { max-width: 760px; margin: 0 auto; padding: 24px 16px 64px; }
h1 { font-size: 1.9rem; line-height: 1.25; margin: 8px 0 4px; }
h2 { font-size: 1.2rem; color: var(--brand); margin: 32px 0 8px; }
p, li { overflow-wrap: anywhere; }
ul { padding-left: 1.25rem; }
.updated { color: var(--muted); margin-top: 0; }
footer { color: var(--muted); font-size: 0.9rem; border-top: 1px solid var(--line);
  margin-top: 40px; padding-top: 16px; }
"""


def render(markdown):
    out, items = [], []

    def flush():
        if items:
            out.append('<ul>' + ''.join(f'<li>{i}</li>' for i in items) + '</ul>')
            items.clear()

    first_paragraph = True
    for raw in markdown.splitlines():
        line = raw.rstrip()
        if not line:
            continue
        text = html.escape(line[2:] if line.startswith(('# ', '- ')) else line)
        if line.startswith('# '):
            flush()
            out.append(f'<h1>{text}</h1>')
        elif line.startswith('## '):
            flush()
            out.append(f'<h2>{html.escape(line[3:])}</h2>')
        elif line.startswith('- '):
            items.append(text)
        else:
            flush()
            cls = ' class="updated"' if first_paragraph else ''
            out.append(f'<p{cls}>{text}</p>')
            first_paragraph = False
    flush()
    return '\n'.join(out)


def page(doc, lang):
    body = render((SOURCE / f'{doc}_{lang}.md').read_text(encoding='utf-8'))
    links = []
    for other in DOCS:
        current = ' aria-current="page"' if other == doc else ''
        links.append(f'<a href="{file_name(other, lang)}"{current}>{DOCS[other][lang]}</a>')
    other_lang = 'so' if lang == 'en' else 'en'
    links.append(f'<a href="{file_name(doc, other_lang)}" lang="{other_lang}" '
                 f'hreflang="{other_lang}">{LANGUAGE_NAMES[other_lang]}</a>')
    title = f'{DOCS[doc][lang]} · SHUKAANSI'
    return f"""<!doctype html>
<html lang="{lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<style>{STYLE}</style>
</head>
<body>
<header><div class="bar"><span class="brand">SHUKAANSI</span><nav>{''.join(links)}</nav></div></header>
<main>
{body}
<footer>SHUKAANSI</footer>
</main>
</body>
</html>
"""


def file_name(doc, lang):
    return f'{doc}.html' if lang == 'en' else f'{doc}-so.html'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for doc in DOCS:
        for lang in ('en', 'so'):
            (OUT / file_name(doc, lang)).write_text(page(doc, lang), encoding='utf-8', newline='\n')
            print('wrote', OUT / file_name(doc, lang))


if __name__ == '__main__':
    main()
