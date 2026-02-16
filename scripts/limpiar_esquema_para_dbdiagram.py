#!/usr/bin/env python3
"""
Lee el dump de pg_dump (esquema) y genera un SQL limpio solo con DDL
que dbdiagram.io puede importar: CREATE TABLE, ALTER TABLE ADD CONSTRAINT, CREATE INDEX.
Elimina SET, CREATE FUNCTION, CREATE TRIGGER, COMMENT, etc.

Uso (desde la raíz del proyecto):
  python scripts/limpiar_esquema_para_dbdiagram.py

Entrada: docs/esquema_para_dbdiagram.sql (UTF-16 o UTF-8)
Salida:  docs/esquema_para_dbdiagram_limpio.sql (UTF-8)
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
IN_FILE = ROOT / "docs" / "esquema_para_dbdiagram.sql"
OUT_FILE = ROOT / "docs" / "esquema_para_dbdiagram_limpio.sql"


def read_content(path: Path) -> str:
    """Lee el archivo intentando UTF-16 (BOM) y luego UTF-8."""
    raw = path.read_bytes()
    if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
        return raw.decode("utf-16")
    return raw.decode("utf-8", errors="replace")


def main():
    if not IN_FILE.exists():
        print(f"No se encontró {IN_FILE}. Ejecuta primero el pg_dump.")
        return 1
    content = read_content(IN_FILE)
    lines = content.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    out_lines = []
    i = 0
    in_create_table = False
    in_create_function = False
    in_other_block = False
    skip_until_dollar = False

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Saltar líneas que dbdiagram no usa
        if stripped.startswith("\\restrict"):
            i += 1
            continue
        if stripped.upper().startswith("SET "):
            i += 1
            continue
        if "pg_catalog.set_config" in stripped or "search_path" in stripped and "set_config" in stripped:
            i += 1
            continue
        if stripped.startswith("COPY ") and "FROM stdin" in stripped:
            in_other_block = True
            i += 1
            continue
        if in_other_block and stripped == "\\.":
            in_other_block = False
            i += 1
            continue
        if in_other_block:
            i += 1
            continue
        if stripped.startswith("SELECT pg_catalog.setval"):
            i += 1
            continue

        # Bloque CREATE FUNCTION / CREATE TRIGGER: saltar hasta $$;
        if "CREATE FUNCTION" in stripped or "CREATE TRIGGER" in stripped:
            in_create_function = True
            skip_until_dollar = True
            i += 1
            continue
        if skip_until_dollar:
            if "$$;" in stripped or stripped == "$$;":
                skip_until_dollar = False
                in_create_function = False
            i += 1
            continue
        if in_create_function:
            i += 1
            continue

        if stripped.startswith("COMMENT ON"):
            i += 1
            continue
        if stripped.startswith("CREATE SEQUENCE"):
            i += 1
            continue
        if stripped.startswith("ALTER SEQUENCE"):
            i += 1
            continue
        if "OWNER TO" in stripped and stripped.startswith("ALTER "):
            i += 1
            continue
        if stripped.startswith("ALTER TABLE ONLY") and "OWNER TO" in stripped:
            i += 1
            continue

        # CREATE TABLE: guardar hasta );
        if "CREATE TABLE" in stripped and "public." in stripped:
            in_create_table = True
            out_lines.append("")
            out_lines.append(line)
            i += 1
            continue
        if in_create_table:
            out_lines.append(line)
            if stripped.endswith(");"):
                in_create_table = False
            i += 1
            continue

        # ALTER TABLE ... ADD CONSTRAINT (puede ser una línea o dos: ALTER TABLE ONLY ... / ADD CONSTRAINT ... REFERENCES)
        if "ALTER TABLE" in stripped and "ADD CONSTRAINT" in stripped:
            out_lines.append("")
            out_lines.append(line)
            i += 1
            continue
        if stripped.startswith("ALTER TABLE ONLY") and i + 1 < len(lines):
            next_stripped = lines[i + 1].strip()
            if "ADD CONSTRAINT" in next_stripped:
                out_lines.append("")
                table_part = stripped.replace("ALTER TABLE ONLY ", "ALTER TABLE ").strip()
                constraint_part = next_stripped.lstrip()
                out_lines.append(f"{table_part} {constraint_part}")
                i += 2
                continue
        if stripped.startswith("ALTER TABLE ONLY"):
            i += 1
            continue

        # CREATE INDEX / CREATE UNIQUE INDEX
        if stripped.startswith("CREATE INDEX") or stripped.startswith("CREATE UNIQUE INDEX"):
            out_lines.append("")
            out_lines.append(line)
            i += 1
            continue

        # Comentarios tipo -- Name: ... (opcional, los dejamos para legibilidad)
        if stripped.startswith("--") and ("Type: TABLE" in stripped or "Type: CONSTRAINT" in stripped or "Type: INDEX" in stripped):
            # Opcional: out_lines.append(line)
            i += 1
            continue

        i += 1

    result = "\n".join(out_lines).strip()
    # Quitar líneas totalmente vacías consecutivas (dejar solo una)
    result = re.sub(r"\n{3,}", "\n\n", result)
    OUT_FILE.write_text(result, encoding="utf-8")
    print(f"Listo. DDL limpio guardado en: {OUT_FILE}")
    print("Importa ese archivo en dbdiagram.io (File -> Import from SQL, PostgreSQL).")
    return 0


if __name__ == "__main__":
    exit(main())
