#!/usr/bin/env python3
"""fr_comments.py — French code comments -> English, via TranslateGemma.

Deterministic pipeline. The translation model NEVER sees a line of code: every
French comment is lifted out of its file (marker and indentation recorded),
translated as bare prose, and written back at its recorded line. The "code
skeleton" of every file — all source with every comment body blanked — is
snapshotted at extract time and compared byte-for-byte at apply time, so a
corrupted translation cannot merge silently.

    scan       count French comments (no network)
    extract    lift French comments into work units + snapshot code skeletons
    translate  drive tg-translate over the units (resume-safe, verified)
    apply      write translations back into the .dart files (skeleton-checked)
    verify     re-prove code is untouched; list French comments still standing
    status     where the job stands

Work dir: .fr2en/ (gitignored). Backends both go through `tg-translate`:
    mac = translategemma-27b-it-mlx-fp16 (oMLX, quality ceiling, 56.7 GB, slow decode)
    box = translategemma-12b-Q8           (llama.cpp router, ~27 t/s decode)
"""

from __future__ import annotations

import argparse
import collections
import difflib
import hashlib
import json
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORK = os.path.join(ROOT, ".fr2en")
IN_DIR = os.path.join(WORK, "in")
OUT_DIR = os.path.join(WORK, "out")
SKEL_DIR = os.path.join(WORK, "skeletons")
REVIEW_DIR = os.path.join(WORK, "review")
PACK_DIR = os.path.join(WORK, "packs")
VERDICT_DIR = os.path.join(WORK, "verdicts")
MANIFEST = os.path.join(WORK, "manifest.json")
LOG = os.path.join(WORK, "run.log")

SRC_LANG = "fr"
TGT_LANG = "en"
DECODE_TPS = {"mac": 7.0, "box": 27.0}          # measured on this estate, 2026-10
# Measured 2026-10-16 on the SAME 70 stratified lines, official tg-translate template:
#   box translategemma-12b-Q8      0.81 s/line  70/70 clean  (0 empty, 0 loop)
#   mac translategemma-27b-it-fp16 ~5.0 s/line  61/70 clean  (5 empty, 4 loop)
# So the box 12B is both FASTER and STRUCTURALLY MORE RELIABLE here, and it costs the
# oMLX ceiling nothing. mac is kept as the quality-ceiling option, not the default.
BOX_LINE_S = 0.81
FR_TOKENS_PER_CHAR = 1 / 3.6
OUT_PER_IN = 1.15

# Line-by-line translation (measured 2026-10-16): sending a whole unit as one block
# degenerates the 27B into a single-token repetition loop on dense technical comments
# (5/8 sampled units failed; no sampling param fixed it). One line per request is clean
# (29/30 dense lines passed). A line that still comes back empty or in a loop is left
# BLANK and filled by the code-truth review stage, never guessed.
#
# The cache key INCLUDES THE MODEL: translations from one backend must never be served
# into another backend's run (measured: the 27B blanks 13% of lines that the 12B
# translates cleanly, so a shared cache would smuggle blanks into a box run).
LINE_CACHE = os.path.join(WORK, "line_cache.json")
OUT_DIR2 = os.path.join(WORK, "out2")        # pass 2 never touches pass 1 output
FAIL_SENTINEL = "\x00FAIL\x00"
PASS = 1   # active translation pass, set by cmd_translate
SINGLE_MAXTOK = 120   # safe cap (longest line ~50 out tokens); bounds degeneration-loop waste

EXCLUDE_DIRS = {".git", "build", ".dart_tool", "l10n", "coverage", "screenshots",
                "assets", "store", "ios", "android", "macos", "linux", "windows", "web"}
EXCLUDE_FILE_RE = re.compile(r"\.(g|freezed)\.dart$|^app_localizations.*\.dart$|\.arb$")
DEFAULT_ROOTS = ["lib", "test", "integration_test", "scripts"]

ACCENTS = set("àâäéèêëîïôöùûüçœæÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒÆ«»")
# Unaccented French function words are the gap that actually bit: 26 comment lines
# (`son formulaire y ajoutait un profil`, `Si [directoryPath] est fourni, utilise ce
# chemin sinon...`) carry NO accent and passed as English on 2026-10-16. The list is
# accent-free on purpose — accents alone already trigger `is_french` — and needs two
# DISTINCT hits per line, so English prose ("set the value", "no element found") is
# not swept in.
FR_WORDS = {"le", "la", "les", "des", "du", "au", "aux", "un", "une", "est", "sont",
            "pour", "avec", "dans", "sur", "par", "cette", "cet", "chaque", "sans",
            "sous", "entre", "après", "apres", "avant", "lorsque", "quand", "ainsi",
            "également", "données", "donnees", "écran", "ecran", "bouton", "valeur",
            "enfant", "temps", "vérifier", "verifier", "requête", "requete", "réponse",
            "reponse", "utilisateur", "rappel", "mesure", "couche", "fichier",
            # added 2026-10-16 after the miss
            "si", "son", "sa", "ses", "ce", "ces", "mon", "ma", "notre", "votre",
            "celui", "celle", "ceux", "soit", "sinon", "sinon", "utilise", "utilisé",
            "utilisé", "fourni", "fournie", "chemin", "devient", "deviennent", "affich",
            "affiche", "affiché", "affichee", "affichee", "formulaire", "profil",
            "profils", "ajoute", "ajoutait", "ajouté", "ajoute", "comme", "aussi",
            "encore", "toujours", "jamais", "peut", "peuvent", "doit", "doivent",
            "faire", "fait", "faite", "dit", "dire", "voir", "voit", "cours",
            "vaut", "aucun", "aucune", "rien", "tous", "toute", "autres", "autre",
            "journal", "liste", "ligne", "lignes", "ordre",
            "insertion", "suppression", "chargement", "charge",
            "chargé", "meme", "mêmes", "memes", "selon", "vers",
            "chez", "apres", "avant", "chaque", "plusieurs", "nimporte", "importe"}
# re.I matters: `Ordre vertical de la zone danger` starts capitalised and was missed.
FR_WORD_RE = re.compile(r"\b(" + "|".join(sorted(set(FR_WORDS), key=len, reverse=True)) + r")\b",
                        re.IGNORECASE)
DECOR_RE = re.compile(r"^[\s\-*_=·•▪◆■□—–/]+$")
FUNC_COMMENT_RE = re.compile(r"^\s*(ignore|coverage|dart|noinspection)\b", re.I)


def is_french(text: str) -> bool:
    """Accent-bearing = French. ASCII-only needs >= 2 DISTINCT French common words,
    so English prose ("// set the value") does not get swept in.

    Code literals in backticks are stripped first: `ORDER BY id` or `autoDispose`
    are not evidence of French prose.
    """
    bare = re.sub(r"`[^`]*`", " ", text)          # `Léa`, `pâteux` are data, not prose
    bare = re.sub(r"\[[^\]]*\]", " ", bare)        # [Ref] links are symbols, not prose
    if any(c in ACCENTS for c in bare):
        return True
    return len({w.group(1) for w in FR_WORD_RE.finditer(bare)}) >= 2


def scan_line(line: str):
    """(comment_start_index or None, continues_multiline_string).

    String-aware: `//` inside "https://…" or 'don\'t // x' is not a comment.
    """
    i, n = 0, len(line)
    state = None  # None | 'dq' | 'sq' | 'tdq' | 'tq'
    while i < n:
        c = line[i]
        if state is None:
            if line.startswith('"""', i):
                state, i = "tdq", i + 3
            elif line.startswith("'''", i):
                state, i = "tq", i + 3
            elif line.startswith("//", i):
                return i, False
            elif c == '"':
                state, i = "dq", i + 1
            elif c == "'":
                state, i = "sq", i + 1
            else:
                i += 1
        elif state in ("dq", "sq"):
            quote = state
            if c == "\\":
                i += 2                       # skip the escaped char
            elif c == ("'" if quote == "sq" else '"'):
                state, i = None, i + 1
            else:
                i += 1
        else:  # triple-quoted: terminates or consumes
            close = '"""' if state == "tdq" else "'''"
            if line.startswith(close, i):
                state, i = None, i + 3
            else:
                i += 1
    return None, state in ("tq", "tdq")


def code_skeleton(text: str) -> str:
    """Every comment body blanked; code punctuation kept. The integrity proof."""
    out = []
    in_block = False
    for line in text.split("\n"):
        if in_block:
            if "*/" in line:
                in_block = False
                j = line.find("*/") + 2
                out.append(" " * j + line[j:])
            else:
                out.append("")
            continue
        start, multiline = scan_line(line)
        if start is None:
            out.append("" if multiline else line)
            continue
        if line[start:start + 2] == "/*":
            if "*/" in line[start + 2:]:
                j = line.find("*/", start) + 2
                out.append(line[:start] + " " * (j - start) + line[j:])
            else:
                in_block = True
                out.append(line[:start])
            continue
        out.append(line[:start].rstrip())
    return "\n".join(out)


def collect_files(roots):
    files = []
    for root in roots:
        abs_root = os.path.join(ROOT, root)
        if not os.path.isdir(abs_root):
            continue
        for dp, dns, fns in os.walk(abs_root):
            dns[:] = [d for d in dns if d not in EXCLUDE_DIRS and not d.startswith(".")]
            for fn in sorted(fns):
                if fn.endswith(".dart") and not EXCLUDE_FILE_RE.search(fn):
                    files.append(os.path.relpath(os.path.join(dp, fn), ROOT))
    return files


def extract_file(rel_path: str):
    """Ordered comment slots: dict(line, marker, indent, prefix, text)."""
    path = os.path.join(ROOT, rel_path)
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    slots = []
    in_block = False
    for no, line in enumerate(lines, 1):
        if in_block:
            if "*/" in line:
                in_block = False
                body = line.split("*/")[0].strip(" *\t")
                if body and is_french(body):
                    slots.append(_slot(no, "/*", line, line, body))
            continue
        start, multiline = scan_line(line)
        if multiline:
            in_block = False
        if start is None:
            continue
        rest = line[start:]
        if rest.startswith("/*"):
            body = rest[2:].split("*/")[0].strip(" *\t")
            in_block = "*/" not in rest
            if body and is_french(body):
                slots.append(_slot(no, "/*", line, line[:start], body))
            continue
        marker = "///" if rest.startswith("///") else "//"
        body = rest.lstrip("/").strip()
        if not body or DECOR_RE.match(body) or FUNC_COMMENT_RE.match(body):
            continue
        if not is_french(body):
            continue
        slots.append(_slot(no, marker, line, line[:start].rstrip(), body))
    return slots


def _slot(no, marker, raw_line, prefix, text):
    return {"line": no, "marker": marker, "indent": len(raw_line) - len(raw_line.lstrip()),
            "prefix": prefix, "text": text}


def chunker(slots, max_lines, max_chars):
    chunks, cur, chars = [], [], 0
    for s in slots:
        if cur and (len(cur) >= max_lines or chars + len(s["text"]) > max_chars):
            chunks.append(cur)
            cur, chars = [], 0
        cur.append(s)
        chars += len(s["text"]) + 1
    if cur:
        chunks.append(cur)
    return chunks


def uid_of(rel_path: str, n: int, total: int) -> str:
    base = rel_path[:-5].replace(os.sep, "__") if rel_path.endswith(".dart") else rel_path
    return base if total == 1 else f"{base}__{n:02d}"


def load_manifest():
    if not os.path.exists(MANIFEST):
        sys.exit("no manifest — run: python3 scripts/fr_comments.py extract")
    with open(MANIFEST, encoding="utf-8") as f:
        return json.load(f)


def save_manifest(m):
    tmp = MANIFEST + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(m, f, ensure_ascii=False, indent=1)
    os.replace(tmp, MANIFEST)


def log(msg):
    os.makedirs(WORK, exist_ok=True)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(msg + "\n")
    print(msg, flush=True)


def skel_path(rel_path):
    return os.path.join(SKEL_DIR, rel_path[:-5].replace(os.sep, "__") + ".skel")


# ---------------------------------------------------------------- commands ----

def cmd_scan(roots, quiet=False):
    files = collect_files(roots)
    per_file = []
    for rel in files:
        slots = extract_file(rel)
        if slots:
            per_file.append((len(slots), sum(len(s["text"]) for s in slots), rel))
    per_file.sort(reverse=True)
    lines = sum(p[0] for p in per_file)
    chars = sum(p[1] for p in per_file)
    est_in = chars * FR_TOKENS_PER_CHAR
    est_out = est_in * OUT_PER_IN
    if quiet:
        return per_file, lines, chars
    print(f"dart files scanned           : {len(files)}")
    print(f"files with French comments : {len(per_file)}")
    print(f"French comment lines       : {lines}")
    print(f"French comment chars       : {chars:,}")
    print(f"est tokens in / out        : {est_in:,.0f} / {est_out:,.0f}")
    for model, rate in DECODE_TPS.items():
        extra = 0.77 * 56.7 if model == "mac" else 6
        print(f"  {model} @ {rate:>4.0f} t/s decode : {est_out / rate / 60:>6.0f} min GPU "
              f"(+{extra:.0f}s cold load)")
    print("\ntop files:")
    for n, c, rel in per_file[:15]:
        print(f"  {n:4d} lines {c:6,d} chars  {rel}")
    return per_file, lines, chars


def cmd_extract(roots, max_lines, max_chars):
    for d in (IN_DIR, OUT_DIR, SKEL_DIR):
        os.makedirs(d, exist_ok=True)
    per_file, total_lines, total_chars = cmd_scan(roots, quiet=True)
    units = []
    for _, _, rel in sorted(per_file, key=lambda x: x[2]):
        slots = extract_file(rel)
        chunks = chunker(slots, max_lines, max_chars)
        for i, chunk in enumerate(chunks, 1):
            uid = uid_of(rel, i, len(chunks))
            with open(os.path.join(IN_DIR, uid + ".in.txt"), "w", encoding="utf-8") as f:
                f.write("\n".join(s["text"] for s in chunk) + "\n")
            units.append({"id": uid, "file": rel, "chunk": i, "chunks": len(chunks),
                          "lines": chunk, "translated": False, "warn": ""})
        with open(skel_path(rel), "w", encoding="utf-8") as f:
            f.write(code_skeleton(open(os.path.join(ROOT, rel), encoding="utf-8").read()))
    save_manifest({"src": SRC_LANG, "tgt": TGT_LANG, "root": ROOT,
                  "created": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
                  "stats": {"files": len(per_file), "lines": total_lines, "chars": total_chars},
                  "units": units})
    sizes = [sum(len(l["text"]) for l in u["lines"]) for u in units]
    print(f"extracted {len(units)} units / {total_lines} comment lines "
          f"from {len(per_file)} files")
    print(f"unit chars: min={min(sizes)} median={sorted(sizes)[len(sizes)//2]} max={max(sizes)}")
    print(f"code skeletons snapshotted -> {os.path.relpath(SKEL_DIR, ROOT)}/ "
          f"({len(per_file)} files)")
    print("next: python3 scripts/fr_comments.py translate --model mac --dry-run")


def call_tg(model, in_path, out_path, max_tokens, temp=0.0):
    cmd = ["tg-translate", SRC_LANG, TGT_LANG, in_path, "--out", out_path,
           "--model", model, "--max-tokens", str(max_tokens), "--temp", str(temp)]
    t0 = time.time()
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError((p.stderr or p.stdout).strip()[:300])
    return p.stderr.strip().splitlines()[-1] if p.stderr.strip() else "", time.time() - t0


def contract(texts, out):
    """Hard contract: one output line per input line, none empty."""
    if len(out) != len(texts):
        return f"line count {len(out)} != {len(texts)}"
    for i, l in enumerate(out):
        if not l.strip():
            return f"empty output at position {i}"
    return None


def soft_warnings(texts, out):
    w = []
    for i, (src, dst) in enumerate(zip(texts, out)):
        if dst.count("`") % 2 != src.count("`") % 2:
            w.append(f"pos{i} backticks")
        for ref in re.findall(r"\[[^\]]+\]", src):
            if ref not in dst:
                w.append(f"pos{i} ref {ref}")
        if any(c in ACCENTS for c in dst) and not re.search(r"[A-ZÀ-Ÿ][a-zà-ÿ]{3,}", dst):
            w.append(f"pos{i} still-French?")
    return w


def _paths():
    """Active (out_dir, cache_path) for the current pass."""
    if PASS == 1:
        return OUT_DIR, LINE_CACHE
    return OUT_DIR2, os.path.join(WORK, f"line_cache.pass{PASS}.json")


def _load_cache():
    path = _paths()[1]
    if os.path.exists(path):
        try:
            return json.load(open(path, encoding="utf-8"))
        except Exception:
            return {}
    return {}


def _save_cache(c):
    with open(_paths()[1], "w", encoding="utf-8") as f:
        json.dump(c, f)


def _line_key(model, unit_id, idx, text):
    """Cache key includes the model so two backends never share cached output."""
    return (f"{model}\x00{unit_id}\x00{idx}\x00"
            f"{hashlib.sha1(text.encode('utf-8')).hexdigest()[:12]}")


def _translate_block_raw(model, texts, max_tokens, tag, temp=0.0):
    """One tg-translate request for a small block -> (lines, stat).

    Returns (None, stat) when the strict one-line-per-line contract is violated
    (degeneration loop, truncation, or an empty line). Raises on transport error.
    """
    tmp = os.path.join(IN_DIR, f"_tmp_{tag}.in.txt")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write("\n".join(texts) + "\n")
    out_tmp = tmp[:-8] + ".out.txt"
    try:
        stat, wall = call_tg(model, tmp, out_tmp, max_tokens, temp)
    except Exception as e:
        try:
            os.remove(tmp)
        except OSError:
            pass
        raise RuntimeError(f"{tag}: {e}") from e
    with open(out_tmp, encoding="utf-8") as f:
        out = [l.rstrip("\n") for l in f]
    if contract(texts, out) is not None:
        return None, stat
    return out, stat


def is_degenerate(line):
    """True when a TranslateGemma output line is unusable: empty, a repetition
    loop, or a prompt/turn-token echo. Deterministic at temp 0, so retrying the
    same line cannot help; blanks are filled by the code-truth review stage."""
    o = line.strip()
    if not o:
        return True
    if "FR:" in o or "<start_of_turn>" in o or "<end_of_turn>" in o:
        return True
    toks = re.findall(r"\S+", o)
    if len(toks) >= 6:
        n = collections.Counter(toks).most_common(1)[0][1]
        if n > max(4, int(len(toks) * 0.4)):
            return True
    return False


def translate_texts(model, texts, max_tokens, tag, depth=0, temp=0.0):
    """Translate N comment lines -> N English lines, ONE REQUEST PER LINE.

    Block mode degenerates on this dense, fragment-heavy corpus, so each line is
    translated alone under tg-translate's official template. A line that comes back
    empty (a mid-sentence fragment) or degenerate (repetition loop / prompt echo)
    is left BLANK and cached as FAIL_SENTINEL — the code-truth review stage fills
    the blanks with code context. Blanks never fail the unit; only transport
    errors do. Returns (out, note, blanks).
    """
    cache = _load_cache()
    out = []
    blanks = []
    for i, line in enumerate(texts):
        k = _line_key(model, tag, i, line)
        if k in cache:
            v = cache[k]
            if v == FAIL_SENTINEL:
                blanks.append(i)
                out.append("")
                continue
            out.append(v)
            continue
        res, _ = _translate_block_raw(model, [line], min(max_tokens, SINGLE_MAXTOK),
                                       f"{tag}_L{i}", temp)
        chosen = res[0] if res is not None else ""
        if is_degenerate(chosen):
            cache[k] = FAIL_SENTINEL
            _save_cache(cache)
            blanks.append(i)
            out.append("")
            continue
        cache[k] = chosen
        _save_cache(cache)
        out.append(chosen)
    warns = soft_warnings(texts, out)
    note = (f"blanks={len(blanks)} {blanks[:10]} " if blanks else "")
    note += ("warn:" + ",".join(warns[:3]) if warns else "")
    return out, note.strip(), blanks


def cmd_translate(model, dry, limit, max_tokens, force, temp=0.0, pass_no=1):
    global PASS
    PASS = pass_no
    out_dir = _paths()[0]
    os.makedirs(out_dir, exist_ok=True)
    tr_key, warn_key, blank_key = (
        ("translated", "warn", "blanks") if pass_no == 1
        else (f"translated{pass_no}", f"warn{pass_no}", f"blanks{pass_no}"))
    m = load_manifest()
    todo = [u for u in m["units"] if force or (not u.get(tr_key) and not u.get("failed"))]
    chars = sum(sum(l["text"] and len(l["text"]) for l in u["lines"]) for u in todo)
    est_out = chars * FR_TOKENS_PER_CHAR * OUT_PER_IN
    rate = DECODE_TPS[model]
    cold = 0.77 * 56.7 if model == "mac" else 6
    if model == "box":
        per_line = BOX_LINE_S
    else:
        per_line = max(1.0, 1 / rate * OUT_PER_IN * 3.6 * 0.5)  # mac observed ~5 s/line
    print(f"units            : {len(todo)} / {len(m['units'])}")
    print(f"source chars     : {chars:,} (~{chars*FR_TOKENS_PER_CHAR:,.0f} in, ~{est_out:,.0f} out)")
    total_lines = sum(len(u["lines"]) for u in todo)
    print(f"backend          : {model} @ ~{rate:.0f} t/s (line-by-line, {total_lines:,} lines)")
    print(f"pass / temp      : pass {pass_no} @ temp {temp}"
          + ("   *** temp 0.0 reproduces pass 1 byte-for-byte — use --temp 0.7" if
             pass_no != 1 and temp == 0.0 else ""))
    print(f"ETA              : ~{est_out/rate/60 + total_lines*per_line/60:.0f} min (+{cold:.0f}s cold load)")
    if dry:
        print("[dry-run] no request sent")
        return
    if model == "mac":
        print("\n*** mac 27B = 56.7 GB into oMLX. It will be requested while another model is\n"
              "*** resident. Run this ONCE, detached (nohup), and do not take a turn against\n"
              "*** the Mac brain until it finishes — every interleaved turn reloads 111 GB.\n")
    done = failed = 0
    t0 = time.time()
    todo = todo[:limit] if limit else todo
    for i, u in enumerate(todo, 1):
        texts = [l["text"] for l in u["lines"]]
        out_path = os.path.join(out_dir, u["id"] + ".out.txt")
        tag = u["id"].replace("__", "_") + (f"_p{pass_no}" if pass_no != 1 else "")
        try:
            out, note, blanks = translate_texts(model, texts, max_tokens, tag, 0, temp)
            with open(out_path, "w", encoding="utf-8") as f:
                f.write("\n".join(out) + "\n")
            u[tr_key] = True
            u[warn_key] = note[-160:]
            u[blank_key] = blanks
            done += 1
        except Exception as e:
            u[tr_key] = False
            u[warn_key] = f"FAILED {e}"[:200]
            if "507" in str(e):
                u["failed"] = True   # oMLX ceiling — free memory (a user decision) before rerunning
            failed += 1
            log(f"[{i}/{len(todo)}] {u['id']}: FAILED {e}")
            if "507" in str(e):
                save_manifest(m)
                sys.exit("\nHTTP 507 — oMLX ceiling refused the 27B. Freeing memory is a USER\n"
                        "decision; otherwise rerun: translate --model box (resumable).")
            continue
        if i % 10 == 0 or i == len(todo):
            save_manifest(m)
            el = time.time() - t0
            log(f"[{i}/{len(todo)}] done={done} failed={failed} elapsed={el/60:.1f}min "
                f"rate={sum(len(t) for u in todo[:i] for t in [u['lines']])/el:.1f} lines/s")
    save_manifest(m)
    log(f"RUN COMPLETE done={done} failed={failed} in {(time.time()-t0)/60:.1f} min")
    print("next: python3 scripts/fr_comments.py verify && ... apply --dry-run")


def cmd_apply(dry):
    m = load_manifest()
    bodies, pending = {}, []
    for u in m["units"]:
        out_path = os.path.join(OUT_DIR, u["id"] + ".out.txt")
        if not os.path.exists(out_path):
            pending.append(u["id"])
            continue
        with open(out_path, encoding="utf-8") as f:
            out = [l.rstrip("\n") for l in f]
        if contract([l["text"] for l in u["lines"]], out):
            pending.append(u["id"])
            continue
        bodies.setdefault(u["file"], []).extend(zip(u["lines"], out))
    if pending:
        print(f"SKIPPED {len(pending)} units (no verified translation): {pending[:8]}")
    touched = 0
    changed = 0
    for rel, pairs in sorted(bodies.items()):
        path = os.path.join(ROOT, rel)
        old = open(path, encoding="utf-8").read()
        lines = old.split("\n")
        for slot, en in pairs:
            en = en.strip()
            if not en:
                sys.exit(f"ABORT {rel}:{slot['line']} — empty translation refused")
            prefix = slot["prefix"]
            lines[slot["line"] - 1] = (prefix + " " if prefix else "") + \
                " " * slot["indent"] + slot["marker"] + " " + en
        new = "\n".join(lines)
        snap_file = skel_path(rel)
        if os.path.exists(snap_file):
            expected = open(snap_file, encoding="utf-8").read()
            got = code_skeleton(new)
            if got != expected:
                print(f"ABORT: code skeleton drift in {rel}")
                for a, b in zip(expected.split("\n"), got.split("\n")):
                    if a != b:
                        print(f"  was: {a}\n  now: {b}")
                        break
                return
        n_diff = sum(1 for a, b in zip(old.split("\n"), lines) if a != b)
        changed += n_diff
        touched += 1
        if not dry:
            tmp = path + ".fr2en.tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                f.write(new)
            os.replace(tmp, path)
    print(f"{'[dry-run] would write ' if dry else 'wrote '}{touched} files, {changed} comment lines"
          f"{', code skeleton verified' if not dry else ''}")


# ------------------------------------------------ code-truth stage ----------
#
# TranslateGemma is faithful, not correct. If the French comment is approximative,
# the English will be fluent and wrong. This stage re-checks every translated
# comment against the code it documents: first mechanically (identifiers and
# literals named in the comment must exist), then semantically (a reasoning model,
# never the translator, reads the comment next to the code and returns a verdict).

SQL_NOISE = {"text", "integer", "real", "not", "null", "default", "primary", "key",
             "autoincrement", "table", "index", "select", "from", "where", "create",
             "alter", "add", "column", "unique", "check", "references", "on", "delete",
             "cascade", "ml", "min", "g", "v1", "true", "false"}
TOKEN_RE = re.compile(r"`([^`\n]{2,40})`|\[([^\]\n]{2,40})\]|'([^'\n]{2,40})'")
# Only identifier-shaped tokens are auditable. This is what keeps French elision
# (l'écran, d'édition) and prose fragments out of the suspect list.
IDENT_OK = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(?:[.<>()\[\]][A-Za-z0-9_]*)*$")
PLACEHOLDER = re.compile(r"[<>]")


def symbol_corpus():
    """Every identifier and literal that actually exists in code (comments excluded)."""
    corpus = set()
    for rel in collect_files(DEFAULT_ROOTS):
        try:
            text = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        except OSError:
            continue
        code = code_skeleton(text)
        for tok in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", code):
            corpus.add(tok)
        for a, b in re.findall(r"'([^'\n]{1,40})'|\"([^\"\n]{1,40})\"", code):
            corpus.add(a or b)
    sql = os.path.join(ROOT, "lib", "data", "local", "schema.sql")
    if os.path.exists(sql):
        for tok in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", open(sql, encoding="utf-8").read()):
            corpus.add(tok)
    return corpus


def _probe(tok: str) -> str:
    """Identifier candidate from a token named inside a comment. Never raises."""
    tok = (tok or "").strip().strip("`'\"·«»")
    if not tok:
        return ""
    tok = tok.split("(")[0].split(".")[-1].split("[")[0]
    for sep in (" ", "=", ":", ",", "|"):
        tok = tok.split(sep)[0]
    return tok.strip()


def cmd_audit():
    """Mechanical pre-screen: things a comment NAMES must exist in the code."""
    corpus = symbol_corpus()
    suspect = []
    total_tokens = 0
    for rel in collect_files(DEFAULT_ROOTS):
        for slot in extract_file(rel):
            for grp in TOKEN_RE.finditer(slot["text"]):
                tok = next((g for g in grp.groups() if g), "") or ""
                tok = tok.strip()
                if not tok or tok in SQL_NOISE or tok.endswith(".md"):
                    continue
                if " " in tok or "'" in tok or any(c in ACCENTS for c in tok):
                    continue                       # French prose, not a code reference
                if not IDENT_OK.match(tok):
                    continue
                total_tokens += 1
                if PLACEHOLDER.search(tok):
                    suspect.append((rel, slot["line"], tok + " <placeholder>", slot["text"][:80]))
                    continue
                probe = _probe(tok)
                if len(probe) < 3:
                    continue
                if probe not in corpus and tok not in corpus:
                    suspect.append((rel, slot["line"], tok, slot["text"][:80]))
    print(f"corpus tokens      : {len(corpus):,}")
    print(f"named tokens       : {total_tokens:,}")
    print(f"UNRESOLVED tokens  : {len(suspect)}  <- stale or invented, reviewer must rule")
    by_tok = {}
    for rel, no, tok, ctx in suspect:
        by_tok.setdefault(tok, []).append(f"{rel}:{no}")
    for tok, wheres in sorted(by_tok.items(), key=lambda kv: -len(kv[1]))[:40]:
        print(f"  {tok:<34} {', '.join(wheres[:3])}")
    os.makedirs(REVIEW_DIR, exist_ok=True)
    with open(os.path.join(REVIEW_DIR, "audit.tsv"), "w", encoding="utf-8") as f:
        for rel, no, tok, ctx in suspect:
            f.write(f"{rel}\t{no}\t{tok}\t{ctx}\n")
    print(f"-> {os.path.relpath(os.path.join(REVIEW_DIR, 'audit.tsv'), ROOT)}")


def code_window(lines, slot_no, before=2, after=8):
    """The code the comment documents: preceding lines + the following code,
    comment-only lines skipped, stopping at the end of the block."""
    out = [f"{n}| {lines[n - 1]}" for n in range(max(1, slot_no - before), slot_no)]
    taken, n = 0, slot_no + 1
    blank_seen = False
    while n <= len(lines) and taken < after:
        raw = lines[n - 1]
        start, _ = scan_line(raw)
        if raw.strip() == "":
            if blank_seen:
                break
            blank_seen = True
        elif start is not None and raw.strip().startswith(("//", "/*", "*")):
            pass
        else:
            out.append(f"{n}| {raw}")
            taken += 1
            blank_seen = False
        n += 1
    return out


REVIEW_HEADER = """# mamadera — EN comment vs CODE review
You are reviewing English comments that were machine-translated from informal French.
The French was written by the developer and is sometimes APPROXIMATIVE: a faithful
translation can therefore be fluent and FACTUALLY WRONG. Trust the code, not the comment.

For each entry below, read the CODE window and rule on the EN comment.
Answer with ONE line per entry, nothing else, in this exact format:
  L<line>\tOK
  L<line>\tFIX\t<corrected English comment, single line, <= 100 chars, no // and no code>
  L<line>\tASK\t<one short question: what cannot be decided from the code alone>
Rules:
- FIX only what the code contradicts or fails to support; do not restyle correct text.
- Never put code, backticked new identifiers, or file paths into a FIX. Reuse identifiers that appear in the CODE window.
- Numbers, units, enum literals, column names, version numbers: verify them, they are the usual lies.
- If the comment claims behaviour you cannot see in the window, answer ASK, do not guess.
"""


def cmd_pack(max_lines):
    """Review packets: EN comment + the code that must support it. One packet per file."""
    m = load_manifest()
    os.makedirs(PACK_DIR, exist_ok=True)
    en_by_file, fr_by_pos = {}, {}
    for u in m["units"]:
        out_path = os.path.join(OUT_DIR, u["id"] + ".out.txt")
        if not os.path.exists(out_path):
            continue
        out = [l.rstrip("\n") for l in open(out_path, encoding="utf-8")]
        if contract([s["text"] for s in u["lines"]], out):
            print(f"SKIP unit {u['id']}: contract mismatch, will not pack")
            continue
        en_by_file.setdefault(u["file"], []).extend(
            (slot["line"], en) for slot, en in zip(u["lines"], out))
        for slot in u["lines"]:
            fr_by_pos.setdefault(u["file"], {})[slot["line"]] = slot["text"]
    made = 0
    for rel in sorted(en_by_file):
        src = open(os.path.join(ROOT, rel), encoding="utf-8").read().split("\n")
        pairs = sorted(en_by_file[rel])
        blocks = []
        for pos, en in pairs:
            blocks.append(f"L{pos}\nFR: {fr_by_pos[rel][pos]}\nEN: {en}\n" +
                          "\n".join(code_window(src, pos)) + "\n")
        pack = os.path.join(PACK_DIR, uid_of(rel, 1, 1) + ".pack.txt")
        with open(pack, "w", encoding="utf-8") as f:
            f.write(REVIEW_HEADER + "\n" + "\n".join(blocks))
        made += 1
    sizes = [os.path.getsize(os.path.join(PACK_DIR, p)) for p in os.listdir(PACK_DIR)]
    print(f"packs built: {made} -> {os.path.relpath(PACK_DIR, ROOT)}/")
    if sizes:
        print(f"pack bytes: min={min(sizes):,} median={sorted(sizes)[len(sizes)//2]:,} "
              f"max={max(sizes):,} total={sum(sizes):,} (~{sum(sizes)/3.6:,.0f} tokens)")


def cmd_review_apply(dry):
    """Apply reviewer verdicts to the TRANSLATION OUTPUT, never to the sources.

    Why here and not on the .dart files: `extract_file` only yields French slots, so a
    source-patching reviewer can only run before `apply` — and `apply` then writes its own
    pass-1 text back over the same recorded line numbers, silently undoing every reviewer
    fix. Patching .fr2en/out/ instead makes the translation files the single source of
    truth, so the sources are written exactly once, skeleton-checked, with the reviewer's
    corrections already folded in.
    """
    if not os.path.exists(VERDICT_DIR):
        sys.exit(f"no verdicts dir — reviewer pass has not produced {VERDICT_DIR}")
    m = load_manifest()
    where = {}                       # (file, line) -> (unit_id, index)
    for u in m["units"]:
        for idx, slot in enumerate(u["lines"]):
            where[(u["file"], slot["line"])] = (u["id"], idx)
    fixed = asks = oks = refused = 0
    per_unit = {}
    ask_list = []
    for name in sorted(os.listdir(VERDICT_DIR)):
        if not name.endswith(".rev.txt"):
            continue
        rel = name[:-len(".rev.txt")].replace("__", os.sep) + ".dart"
        for raw in open(os.path.join(VERDICT_DIR, name), encoding="utf-8"):
            parts = raw.rstrip("\n").split("\t")
            if len(parts) < 2 or not parts[0].startswith("L"):
                continue
            try:
                no = int(parts[0][1:])
            except ValueError:
                continue
            verdict = parts[1].strip().upper()
            if verdict == "OK":
                oks += 1
                continue
            if verdict == "ASK":
                asks += 1
                ask_list.append(f"{rel}:{no} {parts[2] if len(parts) > 2 else ''}")
                continue
            if verdict != "FIX" or len(parts) < 3:
                refused += 1
                continue
            new_text = parts[2].strip()
            markers = [k for k in ("//", "/*", "*/") if k in new_text]
            hit = where.get((rel, no))
            if hit is None:
                print(f"REFUSED {rel}:{no} — not a translated comment line (bad target)")
                refused += 1
                continue
            if markers or not new_text:
                print(f"REFUSED {rel}:{no} — FIX contains {markers or 'empty text'}")
                refused += 1
                continue
            if is_degenerate(new_text):
                print(f"REFUSED {rel}:{no} — FIX is degenerate/empty after normalise")
                refused += 1
                continue
            per_unit.setdefault(hit[0], []).append((no, hit[1], new_text, rel))
            fixed += 1
    patched = 0
    for uid, edits in sorted(per_unit.items()):
        p = os.path.join(OUT_DIR, uid + ".out.txt")
        if not os.path.exists(p):
            print(f"REFUSED {uid}: no translation file")
            refused += len(edits)
            continue
        en = [l.rstrip("\n") for l in open(p, encoding="utf-8")]
        for no, idx, new_text, rel in edits:
            if idx >= len(en):
                print(f"REFUSED {rel}:{no} — index {idx} past end of {uid}")
                continue
            en[idx] = new_text
        if len(en) != len(next(u for u in m["units"] if u["id"] == uid)["lines"]):
            sys.exit(f"ABORT {uid}: line count changed by review — would corrupt reinsertion")
        if not dry:
            tmp = p + ".rev.tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                f.write("\n".join(en) + "\n")
            os.replace(tmp, p)
        patched += 1
        for no, idx, new_text, rel in edits:
            u = next(x for x in m["units"] if x["id"] == uid)
            print(f"  FIX {rel}:{no}  FR « {u['lines'][idx]['text'][:40]} »  ->  {new_text[:56]}")
    print(f"\n{'[dry-run] ' if dry else ''}verdicts: OK={oks} FIX={fixed} ASK={asks} REFUSED={refused} "
          f"across {patched} unit file(s)")
    for a in ask_list:
        print(f"ASK {a}")
    print("next: verify -> apply --dry-run -> apply -> flutter analyze")


def cmd_verify(staged):
    m = load_manifest()
    drift, french_left = [], []
    files = sorted({u["file"] for u in m["units"]})
    for rel in files:
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            drift.append(f"{rel}: missing")
            continue
        snap = skel_path(rel)
        if os.path.exists(snap):
            expected = open(snap, encoding="utf-8").read()
            got = code_skeleton(open(path, encoding="utf-8").read())
            if got != expected:
                drift.append(f"{rel}: CODE SKELETON DRIFT")
        for s in extract_file(rel):
            if is_french(s["text"]):
                french_left.append(f"{rel}:{s['line']}")
    print(f"files checked       : {len(files)}")
    print(f"skeleton drift      : {len(drift)}  {'<-- MUST BE 0' if drift else ''}")
    for d in drift:
        print(f"  {d}")
    print(f"French comments left: {len(french_left)}")
    for f in french_left[:20]:
        print(f"  {f}")
    if staged:
        diff = subprocess.run(["git", "diff", "--name-only"], cwd=ROOT, capture_output=True, text=True)
        print(f"git modified files  : {len([x for x in diff.stdout.split() if x])}")


def _norm(s):
    """Normalize a translated line for cross-pass comparison: case, quotes,
    dashes, trailing punctuation and whitespace are not signal."""
    s = s.strip().lower().replace("’", "'").replace("`", "").replace('"', "'")
    s = re.sub(r"[–—]", "-", s)
    s = re.sub(r"[.,;:!?:]+$", "", s)
    return re.sub(r"\s+", " ", s).strip()


def cmd_disagree(flag_below):
    """Compare pass 1 (temp 0) with pass 2 (temp > 0) line by line.

    A line the model translates two different ways is a line whose meaning the
    model was not sure of — the cheapest honest ambiguity signal available, and
    it costs no reasoning-model time. Agreement is NOT correctness: a line can
    agree twice and still be wrong about the code. So this ranks review effort,
    it does not replace the code-truth pass.
    """
    m = load_manifest()
    if not os.path.isdir(OUT_DIR2):
        sys.exit(f"no pass-2 output in {OUT_DIR2}\n"
                 f"run first: translate --model box --pass 2 --temp 0.7")
    os.makedirs(REVIEW_DIR, exist_ok=True)
    rows, both_blank, p1_blank, p2_blank, skipped = [], 0, 0, 0, 0
    for u in m["units"]:
        p1, p2 = (os.path.join(OUT_DIR, u["id"] + ".out.txt"),
                  os.path.join(OUT_DIR2, u["id"] + ".out.txt"))
        if not (os.path.exists(p1) and os.path.exists(p2)):
            continue
        e1 = [l.rstrip("\n") for l in open(p1, encoding="utf-8")]
        e2 = [l.rstrip("\n") for l in open(p2, encoding="utf-8")]
        if not (len(e1) == len(e2) == len(u["lines"])):
            skipped += 1
            print(f"SKIP {u['id']}: line count p1={len(e1)} p2={len(e2)} fr={len(u['lines'])}")
            continue
        for slot, a, b in zip(u["lines"], e1, e2):
            na, nb = _norm(a), _norm(b)
            if not na and not nb:
                both_blank += 1
            elif not na:
                p1_blank += 1
            elif not nb:
                p2_blank += 1
            sim = difflib.SequenceMatcher(None, na, nb).ratio() if (na or nb) else 1.0
            rows.append((sim, u["file"], slot["line"], slot["text"], a, b))
    if not rows:
        sys.exit("no comparable lines between pass 1 and pass 2")
    rows.sort(key=lambda r: r[0])
    out_tsv = os.path.join(REVIEW_DIR, "disagree.tsv")
    with open(out_tsv, "w", encoding="utf-8") as f:
        f.write("sim\tfile\tline\tFR\tpass1\tpass2\n")
        for sim, rel, ln, fr, a, b in rows:
            f.write(f"{sim:.3f}\t{rel}\t{ln}\t{fr}\t{a}\t{b}\n")
    n = len(rows)
    ident = sum(1 for r in rows if r[0] >= 0.98)
    minor = sum(1 for r in rows if 0.80 <= r[0] < 0.98)
    div = sum(1 for r in rows if 0.60 <= r[0] < 0.80)
    hard = sum(1 for r in rows if r[0] < 0.60)
    print(f"\ncompared           : {n:,} lines across pass 1 + pass 2 ({skipped} unit(s) skipped)")
    print(f"identical          : {ident:,} ({ident/n*100:.1f}%)")
    print(f"minor wording      : {minor:,} ({minor/n*100:.1f}%)")
    print(f"divergent        : {div:,} ({div/n*100:.1f}%)")
    print(f"CONFLICTING      : {hard:,} ({hard/n*100:.1f}%)  <- say something different")
    print(f"blank in p1 / p2 / both: {p1_blank} / {p2_blank} / {both_blank}")
    print(f"report             : {out_tsv} (worst first)")
    pri = [r for r in rows if r[0] < flag_below]
    pri_path = os.path.join(REVIEW_DIR, "review-priority.tsv")
    with open(pri_path, "w", encoding="utf-8") as f:
        f.write("sim\tfile\tline\tFR\tpass1\tpass2\n")
        for r in pri:
            f.write(f"{r[0]:.3f}\t{r[1]}\t{r[2]}\t{r[3]}\t{r[4]}\t{r[5]}\n")
    print(f"review priority    : {len(pri):,} lines below {flag_below:.2f} -> {pri_path}")
    print("\nHIGHEST-PRIORITY DISAGREEMENTS")
    for sim, rel, ln, fr, a, b in rows[:12]:
        print(f"  {sim:.2f}  {rel}:{ln}")
        print(f"        FR : {fr[:76]}")
        print(f"        p1 : {a[:76] or '<BLANK>'}")
        print(f"        p2 : {b[:76] or '<BLANK>'}")


def _protected_tokens(fr):
    """Code literals a comment is NOT allowed to paraphrase: backticked spans,
    [Ref] links, and bare ''/"" sentinels. These are identifiers and DB values —
    translating or rescasing them makes the comment point at something that does
    not exist. Measured 2026-10-16: the 12B renders the `''` 'no profile' sentinel
    as `` `` ` `` ``, `'`, " ", and even "Profileless" — on the very comments that
    document the v10 / v1.2.0 profile leak. That is a correctness bug, so it is
    guarded mechanically rather than left to a reviewer's patience."""
    out = set(re.findall(r"`([^`]*)`", fr))
    out |= set(re.findall(r"\[[^\]]+\]", fr))
    if re.search(r"(?<![\w'\"])''(?![\w'\"])", fr):
        out.add("''")
    return {t for t in out if t.strip() or t == ""}


# Only ever applied when the English line contains NO '' at all while the French
# did — so these cannot damage a line that already carries the sentinel correctly.
_RESENTINEL = [
    re.compile(r"'{2}\s*\.{3}\s*'{2}"),   # ''...
    re.compile(r"\"'{2}\""),               # "''"
    re.compile(r"`\s*'{1}\s*`(?!')"),      # backtick ' backtick
    re.compile(r"\"'{1}\""),               # "'
    re.compile(r"`\s*`(?!')"),             # empty backticks
    re.compile(r"\"\s*\""),               # empty or single-space double quotes
]


def harden_line(fr, en):
    """Restore protected code literals into an English line, deterministically.

    Returns (harded_en, restored, lost). Tokens absent from the English entirely
    are reported in `lost` for the reviewer — never invented here.
    """
    restored, lost = [], []
    for tok in sorted(_protected_tokens(fr), key=len, reverse=True):
        if tok == "":
            continue
        wrapped = f"`{tok}`"
        if wrapped in en:                 # already exact — never touch, never double-wrap
            continue
        if tok == "''":
            for rx in _RESENTINEL:
                new = rx.sub("`''`", en)
                if new != en:
                    en = new
                    restored.append("''")
                    break
            else:
                lost.append("''")
            continue
        if tok.startswith("["):           # [Ref] — the brackets carry the meaning
            if re.search(re.escape(tok), en):
                continue
            m = re.search(re.escape(tok[1:-1]), en, re.I)
            if m:
                en = en[:m.start()] + tok + en[m.end():]
                restored.append(tok)
            else:
                lost.append(tok)
            continue
        # identifier present but rescased, or in " " instead of backticks. Consume the
        # surrounding straight quotes so "Enabled" -> `enabled`, never `"`enabled`"`.
        pat = re.compile(r"[\"']?" + re.escape(tok) + r"[\"']?", re.I)
        m = pat.search(en)
        if m:
            if m.group(0) != wrapped:
                en = en[:m.start()] + wrapped + en[m.end():]
                restored.append(tok)
        elif not re.search(re.escape(tok), en, re.I):
            lost.append(tok)
    return en, restored, lost


def _file_identifiers(rel):
    """Identifiers in the CODE of a file (comments blanked) — the ground truth a
    [Ref] or a backticked symbol must match. Taken from the skeleton, not the raw
    file, because the French prose itself mentions names that no longer exist."""
    try:
        src = open(os.path.join(ROOT, rel), encoding="utf-8").read()
    except OSError:
        return set()
    return set(re.findall(r"[A-Za-z_$][A-Za-z0-9_$]*", code_skeleton(src)))


def _restore_pairs(en, fr_tokens, idents, fr_line):
    """Restore [Ref] doc links that the translator paraphrased, 1:1 by position.

    A token is `invented` only when it is not an identifier of this file AND does not
    appear anywhere in the French line. That second test is what keeps this safe: the
    first version substituted positionally without it and ate `''` (the no-profile
    sentinel) to restore `unit`, and replaced `IconButton` which the French itself
    names. Counts must match exactly, else everything is escalated and nothing is
    guessed. Bracketed refs only — backticked literals are never substituted, because
    a backticked thing that is not a skeleton identifier is usually a legitimate
    literal (`ml`, `3,4 kg`, `—`, SQL), not an error.
    """
    missing = [t for t in fr_tokens if f"[{t}]" not in en]
    if not missing:
        return en, []
    present = re.findall(r"\[[^\]]+\]", en)
    junk = [p for p in present
            if p[1:-1] not in idents and p[1:-1] not in fr_line]
    if len(missing) != len(junk):
        return en, [("ESCALATE", m) for m in missing]
    out = en
    for junk_tok, real in zip(junk, missing):
        out = out.replace(junk_tok, f"[{real}]", 1)
    return out, list(zip(junk, missing))


def harden_refs(en, fr_refs, idents, fr_line):
    """Force [Ref] doc links to name identifiers that actually exist."""
    real = [r[1:-1] for r in fr_refs if r[1:-1] in idents]
    if not real:
        return en, []
    return _restore_pairs(en, real, idents, fr_line)


def cmd_harden(dry, pass_no=1):
    """Deterministic hardening pass over a pass's output: put code literals back.

    Run this on BOTH passes before `disagree`, so the comparison scores meaning and
    not quoting style.
    """
    global PASS
    PASS = pass_no
    out_dir = _paths()[0]
    m = load_manifest()
    tally = collections.Counter()
    rows = []
    fixed_files = 0
    for u in m["units"]:
        p = os.path.join(out_dir, u["id"] + ".out.txt")
        if not os.path.exists(p):
            continue
        en = [l.rstrip("\n") for l in open(p, encoding="utf-8")]
        if len(en) != len(u["lines"]):
            print(f"SKIP {u['id']}: line count")
            continue
        idents = _file_identifiers(u["file"])
        new, touched = [], 0
        for slot, e in zip(u["lines"], en):
            if not e.strip():
                new.append(e)
                continue
            h, got, lost = harden_line(slot["text"], e)
            fr_br = [r for r in re.findall(r"\[[^\]]+\]", slot["text"])]
            if fr_br:
                h, pairs = harden_refs(h, fr_br, idents, slot["text"])
                for a, b in pairs:
                    if a == "ESCALATE":
                        lost.append(f"[ref]{b}")
                    else:
                        got.append(f"{a}->{b}")
                        tally["ref"] += 1
            if got:
                touched += 1
                tally["restored"] += len(got)
                if pass_no == 1:
                    print(f"  {u['file']}:{slot['line']}  " + ", ".join(got[:4]))
            if lost:
                tally["lost"] += len(lost)
                rows.append((u["file"], slot["line"], ",".join(lost), slot["text"], h))
            new.append(h)
        if not dry and touched:
            with open(p, "w", encoding="utf-8") as f:
                f.write("\n".join(new) + "\n")
            if touched:
                fixed_files += 1
    print(f"literals restored   : {tally['restored']}")
    print(f"still MISSING       : {tally['lost']}  <- reviewer must fix, never invented")
    out = os.path.join(REVIEW_DIR, "literals-lost.tsv" if pass_no == 1 else f"literals-lost.pass{pass_no}.tsv")
    os.makedirs(REVIEW_DIR, exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write("file\tline\tmissing\tFR\tEN\n")
        for r in rows:
            f.write("\t".join(str(x) for x in r) + "\n")
    print(f"review list         : {out}")
    print("[dry-run] nothing written" if dry else "pass 1 output updated in place")


def cmd_status():
    if not os.path.exists(MANIFEST):
        sys.exit("no manifest")
    m = load_manifest()
    done = sum(1 for u in m["units"] if u["translated"])
    disk = sum(1 for u in m["units"]
               if os.path.exists(os.path.join(OUT_DIR, u["id"] + ".out.txt")))
    perm = [u["id"] for u in m["units"] if u.get("failed")]
    blanks_tot = sum(len(u.get("blanks", [])) for u in m["units"])
    units_blank = sum(1 for u in m["units"] if u.get("blanks"))
    print(f"units: {done}/{len(m['units'])} translated, {disk} output files on disk")
    if perm:
        print(f"transport-failed (free memory then rerun, or --force): {len(perm)} -> {perm[:10]}")
    print(f"blank lines (review stage fills these, with code context): {blanks_tot} across {units_blank} units")
    fails = [u["id"] for u in m["units"] if u.get("warn", "").startswith("FAILED")]
    if fails:
        print(f"failed: {len(fails)} -> {fails[:10]}")
    if os.path.exists(LOG):
        print("--- tail of run.log ---")
        sys.stdout.write("".join(open(LOG, encoding="utf-8").readlines()[-10:]))


def main():
    ap = argparse.ArgumentParser(description="French comments -> English, TranslateGemma pipeline")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("scan"); p.add_argument("--roots", nargs="*", default=DEFAULT_ROOTS)
    p = sub.add_parser("extract"); p.add_argument("--roots", nargs="*", default=DEFAULT_ROOTS)
    p.add_argument("--max-lines", type=int, default=60)
    p.add_argument("--max-chars", type=int, default=6000)
    p = sub.add_parser("translate"); p.add_argument("--model", choices=["mac", "box"], default="mac")
    p.add_argument("--dry-run", action="store_true"); p.add_argument("--limit", type=int, default=0)
    p.add_argument("--max-tokens", type=int, default=4096); p.add_argument("--force", action="store_true")
    p.add_argument("--temp", type=float, default=0.0)
    p.add_argument("--pass", dest="pass_no", type=int, default=1,
                   help="pass 2 writes .fr2en/out2/ and its own cache; pass 1 is never touched")
    p = sub.add_parser("apply"); p.add_argument("--dry-run", action="store_true")
    p = sub.add_parser("verify"); p.add_argument("--staged", action="store_true")
    sub.add_parser("audit")
    p = sub.add_parser("disagree"); p.add_argument("--flag-below", type=float, default=0.60)
    p = sub.add_parser("harden"); p.add_argument("--dry-run", action="store_true")
    p.add_argument("--pass", dest="pass_no", type=int, default=1)
    p = sub.add_parser("pack"); p.add_argument("--max-lines", type=int, default=8)
    p = sub.add_parser("review-apply"); p.add_argument("--dry-run", action="store_true")
    sub.add_parser("status")
    a = ap.parse_args()
    if a.cmd == "scan":
        cmd_scan(a.roots)
    elif a.cmd == "extract":
        cmd_extract(a.roots, a.max_lines, a.max_chars)
    elif a.cmd == "translate":
        cmd_translate(a.model, a.dry_run, a.limit, a.max_tokens, a.force, a.temp, a.pass_no)
    elif a.cmd == "apply":
        cmd_apply(a.dry_run)
    elif a.cmd == "verify":
        cmd_verify(a.staged)
    elif a.cmd == "audit":
        cmd_audit()
    elif a.cmd == "disagree":
        cmd_disagree(a.flag_below)
    elif a.cmd == "harden":
        cmd_harden(a.dry_run, a.pass_no)
    elif a.cmd == "pack":
        cmd_pack(a.max_lines)
    elif a.cmd == "review-apply":
        cmd_review_apply(a.dry_run)
    elif a.cmd == "status":
        cmd_status()


if __name__ == "__main__":
    main()
