"""Checagem estatica do Kinora: blocos sub/function/if/for, XML, ids, callbacks, scripts incluidos,
imagens/fontes referenciadas e chaves de traducao. Uso: python3 tools/lint.py"""
import re, os, sys, glob
import xml.etree.ElementTree as ET

root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
errors = []
def err(msg): errors.append(msg)

def strip_comment(line):
    out, inq = "", False
    for ch in line:
        if ch == '"': inq = not inq
        if ch == "'" and not inq: break
        out += ch
    return out

def check_blocks(path):
    stack = []
    for n, raw in enumerate(open(path, encoding="utf-8"), 1):
        line = strip_comment(raw).strip()
        low = line.lower()
        if not low: continue
        if re.match(r"^(sub|function)\b", low): stack.append(("sub", n))
        elif re.match(r"^end\s*(sub|function)\b", low):
            if not stack or stack[-1][0] != "sub": err(f"{path}:{n} end sub/function sem abertura")
            else: stack.pop()
        elif re.match(r"^(else\s+)?if\b", low) and not low.startswith("else if"):
            if re.search(r"\bthen\s*$", low): stack.append(("if", n))
        elif re.match(r"^end\s*if\b", low) or low == "endif":
            if not stack or stack[-1][0] != "if": err(f"{path}:{n} end if sem abertura (pilha={stack[-1] if stack else None})")
            else: stack.pop()
        elif re.match(r"^for\b", low): stack.append(("for", n))
        elif re.match(r"^(end\s*for|next)\b", low):
            if not stack or stack[-1][0] != "for": err(f"{path}:{n} end for sem abertura")
            else: stack.pop()
        elif re.match(r"^while\b", low): stack.append(("while", n))
        elif re.match(r"^end\s*while\b", low):
            if not stack or stack[-1][0] != "while": err(f"{path}:{n} end while sem abertura")
            else: stack.pop()
    if stack: err(f"{path}: blocos abertos sem fechar: {stack}")

def defined_funcs(path):
    names = set()
    for raw in open(path, encoding="utf-8"):
        m_ = re.match(r"^\s*(?:sub|function)\s+(\w+)", raw, re.I)
        if m_: names.add(m_.group(1).lower())
    return names

brs_files = glob.glob(root + "/**/*.brs", recursive=True)
for f in brs_files: check_blocks(f)

# nomes duplicados dentro do mesmo escopo de componente
comps = {}
for x in glob.glob(root + "/components/*.xml"):
    tree = ET.parse(x)
    r = tree.getroot()
    name = r.get("name")
    comps[name] = (x, r)
builtin_nodes = {"ContentNode","StandardMessageDialog","StandardKeyboardDialog","Timer","StandardPinPadDialog","Rectangle","Label","Poster","Group"}

builtin_vars = set("abs asc atn chr cint cos csng cdbl exp fix hex instr int lcase left len log mid pos right rnd sgn sin sqr str string tab tan ucase val type box eval sleep wait run getinterface".split())
reserved = set("to next step then stop end exit run print goto dim let mod not and or if else elseif for each in while sub function return as invalid true false library".split())
reserved -= {"run"}

for name, (xmlpath, r) in comps.items():
    scripts = [s.get("uri") for s in r.findall("script")]
    funcs = {}
    for u in scripts:
        p = u.replace("pkg:/", root + "/")
        if not os.path.exists(p): err(f"{name}: script inexistente {u}"); continue
        for fn in defined_funcs(p):
            if fn in funcs and funcs[fn] != p: err(f"{name}: funcao duplicada {fn} em {funcs[fn]} e {p}")
            funcs[fn] = p
    ids = {e.get("id") for e in r.iter() if e.get("id")}
    iface = r.find("interface")
    fields = {e.get("id") for e in (iface.findall("field") if iface is not None else [])}
    ifuncs = {e.get("name") for e in (iface.findall("function") if iface is not None else [])}
    for fn in ifuncs:
        if fn.lower() not in funcs: err(f"{name}: <function {fn}> nao definida")
    if iface is not None:
        for e in iface.findall("field"):
            oc = e.get("onChange")
            if oc and oc.lower() not in funcs: err(f"{name}: onChange={oc} nao definida")
    src = "\n".join(open(u.replace("pkg:/", root + "/"), encoding="utf-8").read() for u in scripts if os.path.exists(u.replace("pkg:/", root + "/")))
    code = "\n".join(strip_comment(l) for l in src.splitlines())
    for fid in re.findall(r'findNode\("(\w+)"\)', code):
        if fid not in ids: err(f"{name}: findNode('{fid}') sem id no XML")
    for cb in re.findall(r'observeField\("\w+",\s*"(\w+)"\)', code):
        if cb.lower() not in funcs: err(f"{name}: callback {cb} nao definido")
    for cb in re.findall(r'startJson\([^\n]*?,\s*"(on\w+)"\s*,', code):
        if cb.lower() not in funcs: err(f"{name}: callback startJson {cb} nao definido")
    for node in re.findall(r'CreateObject\("roSGNode",\s*"(\w+)"\)', code):
        if node not in comps and node not in builtin_nodes: err(f"{name}: no desconhecido {node}")
    for fc in re.findall(r'callFunc\("(\w+)"', code):
        pass
    for f in re.findall(r"\bm\.top\.(\w+)", code):
        if f not in fields and f not in {"findNode","getScene","appendChild","removeChild","setFocus","visible","functionName","url","context","result","timeoutMs","dialog","observeField","subtype"}:
            err(f"{name}: m.top.{f} nao declarado na interface")
    # palavras reservadas como variavel/parametro
    for n, l in enumerate(code.splitlines(), 1):
        for mm in re.finditer(r"\b(\w+)\s+as\s+(?:String|Object|Integer|Boolean|Dynamic|Float)\b", l):
            if mm.group(1).lower() in reserved: err(f"{name}: parametro reservado '{mm.group(1)}' linha {n}")
        mm = re.match(r"^\s*(\w+)\s*=[^=]", l)
        if mm and mm.group(1).lower() in reserved: err(f"{name}: variavel reservada '{mm.group(1)}'")
        if mm and mm.group(1).lower() in builtin_vars: err(f"{name}: variavel com nome de funcao nativa '{mm.group(1)}' (linha {n})")
    # itemComponentName existe?
    for e in r.iter():
        icn = e.get("itemComponentName")
        if icn and icn not in comps: err(f"{name}: itemComponentName {icn} inexistente")

# manifest e imagens referenciadas
mf = open(root + "/manifest").read()
for m_ in re.findall(r"pkg:/([^\s]+)", mf):
    if not os.path.exists(f"{root}/{m_}"): err(f"manifest: {m_} inexistente")
for x in glob.glob(root + "/components/*.xml"):
    for m_ in re.findall(r"pkg:/((?:images|fonts)/[^\"']+)", open(x, encoding="utf-8").read()):
        if not os.path.exists(f"{root}/{m_}"): err(f"{x}: imagem {m_} inexistente")


# --- chamadas a funcoes desconhecidas, POR COMPONENTE (pega <script> faltando) ---
known_builtin = set("""createobject type str val int len left right mid instr chr asc lcase ucase wait formatjson parsejson abs""".split())
def code_of(path):
    code = "\n".join(strip_comment(l) for l in open(path, encoding="utf-8").read().splitlines())
    return re.sub(r'"[^"]*"', '""', code)
for name, (xmlpath, r) in comps.items():
    scripts = [s_.get("uri").replace("pkg:/", root + "/") for s_ in r.findall("script")]
    funcs = set()
    for sp in scripts:
        if os.path.exists(sp): funcs |= defined_funcs(sp)
    for sp in scripts:
        if not os.path.exists(sp): continue
        for n, l in enumerate(code_of(sp).splitlines(), 1):
            if re.match(r"^\s*(sub|function)\b", l, re.I): continue
            for mm in re.finditer(r"(?<![\.\w])([A-Za-z_]\w*)\s*\(", l):
                nm = mm.group(1).lower()
                if nm in funcs or nm in known_builtin or nm in reserved or nm in ("if","while","for"): continue
                err(f"{name}/{os.path.basename(sp)}:{n} chamada a '{mm.group(1)}' sem estar definida/incluida neste componente")

# --- chaves tr("...") existem nos 3 idiomas ---
i18n = open(root + "/source/I18n.brs", encoding="utf-8").read()
blocks = {}
for lang, fn in (("pt","stringsPt"),("en","stringsEn"),("es","stringsEs")):
    m_ = re.search(r"function %s\(\) as Object(.*?)end function" % fn, i18n, re.S)
    keys = set(re.findall(r'^\s*"?([\w\-]+)"?\s*:\s*"', m_.group(1), re.M))
    blocks[lang] = keys
allk = blocks["pt"] | blocks["en"] | blocks["es"]
for lang, ks in blocks.items():
    for k in sorted(allk - ks): err(f"I18n: chave '{k}' ausente em {lang}")
used = set()
for f in brs_files:
    c = open(f, encoding="utf-8").read()
    for k in re.findall(r'\b(?:i18n|trf2?)\("([\w\-]+)"', c):
        if not k.endswith('_'): used.add(k)
for k in sorted(used - allk): err(f"tr('{k}') nao existe em I18n")
# --- linhas dos Ajustes: cada row("x") precisa de st_x e st_x_h nos 3 idiomas ---
sv = open(root + "/components/SettingsView.brs", encoding="utf-8").read()
for k in re.findall(r'\brow\("(\w+)"', sv):
    for need in ("st_" + k, "st_" + k + "_h"):
        for lang, ks in blocks.items():
            if need not in ks: err(f"Ajustes: chave '{need}' ausente em {lang}")
print("chaves tr usadas:", len(used), "| definidas:", len(allk))

NATIVAS = set("""abs asc atn cdbl chr cint cos copyfile createdirectory createobject csng deletedirectory deletefile eval exp findmemberfunction fix formatdrive formatjson getglobalaa getinterface getlasterror instr int lcase left len listdir log matchfiles mid parsejson parsexml pos readasciifile rebootsystem right rnd run sgn sin sleep sqr str stri string stringi substitute tab tan tr type ucase uptime val wait writeasciifile box""".split())
for f_ in brs_files:
    for fn_ in defined_funcs(f_):
        if fn_ in NATIVAS: err(f"{os.path.basename(f_)}: funcao '{fn_}' tem o mesmo nome de uma funcao nativa do BrightScript (a nativa vence)")
print("arquivos .brs:", len(brs_files), "| componentes:", len(comps))
if errors:
    print("PROBLEMAS:")
    for e in errors: print(" -", e)
    sys.exit(1)
print("OK: nenhum problema estatico encontrado")
