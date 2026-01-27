# storage.py
from __future__ import annotations

import os
import json
import sqlite3
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Any, Optional, List, Dict

# -------------------------
# Project-local data paths
# -------------------------

DEFAULT_DATA_DIR = Path("/home/pilotline/projects/FrictionTester_RaspberryPi/data")

# Optional override (keep if you ever want to change location without editing code)
DATA_DIR = Path(os.environ.get("FRICTIONTESTER_DATA_DIR", str(DEFAULT_DATA_DIR)))

DB_PATH = DATA_DIR / "db" / "frictiontester.db"
TRIALS_DIR = DATA_DIR / "runs"   

def _utc_now_iso() -> str:
    return datetime.utcnow().replace(microsecond=0).isoformat() + "Z"


def connect() -> sqlite3.Connection:
    # Ensure folders exist
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)   # data/db
    TRIALS_DIR.mkdir(parents=True, exist_ok=True)       # data/trials

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def _column_exists(conn: sqlite3.Connection, table: str, column: str) -> bool:
    rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
    return any(r["name"] == column for r in rows)

def init_db(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS protocols (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            speed REAL NOT NULL,
            stroke_length_mm INTEGER NOT NULL,
            clamp_force_g INTEGER NOT NULL,
            water_temp_c INTEGER NOT NULL,
            cycles INTEGER NOT NULL,

            fixed_start_enabled INTEGER NOT NULL DEFAULT 0,
            fixed_start_mm REAL NOT NULL DEFAULT 0,

            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            protocol_id INTEGER NOT NULL,
            protocol_snapshot_json TEXT NOT NULL,
            status TEXT NOT NULL, -- queued, running, completed, aborted, failed
            started_at TEXT,
            finished_at TEXT,
            run_dir TEXT NOT NULL,
            notes TEXT,
            FOREIGN KEY(protocol_id) REFERENCES protocols(id) ON DELETE RESTRICT
        );

        CREATE INDEX IF NOT EXISTS idx_protocols_updated_at ON protocols(updated_at);
        CREATE INDEX IF NOT EXISTS idx_runs_protocol_id ON runs(protocol_id);
        """
    )

    # --- ✅ MIGRATION for existing DBs (if table existed before new columns) ---
    if not _column_exists(conn, "protocols", "fixed_start_enabled"):
        conn.execute("ALTER TABLE protocols ADD COLUMN fixed_start_enabled INTEGER NOT NULL DEFAULT 0;")
    if not _column_exists(conn, "protocols", "fixed_start_mm"):
        conn.execute("ALTER TABLE protocols ADD COLUMN fixed_start_mm REAL NOT NULL DEFAULT 0;")

    conn.commit()

@dataclass
class Protocol:
    id: Optional[int]
    name: str
    speed: float                 # cm/s
    stroke_length_mm: int
    clamp_force_g: int
    water_temp_c: int
    cycles: int

    # ✅ NEW
    fixed_start_enabled: int = 0   # store as 0/1 for sqlite
    fixed_start_mm: float = 0.0

    created_at: Optional[str] = None
    updated_at: Optional[str] = None


@dataclass
class RunRow:
    id: int
    protocol_id: int
    protocol_snapshot_json: str
    status: str
    started_at: Optional[str]
    finished_at: Optional[str]
    run_dir: str
    notes: Optional[str]

def list_protocols(conn: sqlite3.Connection) -> List[Protocol]:
    rows = conn.execute(
        "SELECT * FROM protocols ORDER BY updated_at DESC"
    ).fetchall()
    return [Protocol(**dict(r)) for r in rows]


def get_protocol(conn: sqlite3.Connection, protocol_id: int) -> Optional[Protocol]:
    row = conn.execute("SELECT * FROM protocols WHERE id = ?", (protocol_id,)).fetchone()
    return Protocol(**dict(row)) if row else None


def create_protocol(conn: sqlite3.Connection, p: Protocol) -> int:
    now = _utc_now_iso()
    cur = conn.execute(
        """
        INSERT INTO protocols (
            name, speed, stroke_length_mm, clamp_force_g, water_temp_c, cycles,
            fixed_start_enabled, fixed_start_mm,
            created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            p.name,
            p.speed,
            p.stroke_length_mm,
            p.clamp_force_g,
            p.water_temp_c,
            p.cycles,
            int(p.fixed_start_enabled),
            float(p.fixed_start_mm),
            now,
            now,
        ),
    )
    conn.commit()
    return int(cur.lastrowid)


def update_protocol(conn: sqlite3.Connection, protocol_id: int, fields: Dict[str, Any]) -> None:
    allowed = {
        "name", "speed", "stroke_length_mm", "clamp_force_g", "water_temp_c", "cycles",
        "fixed_start_enabled", "fixed_start_mm",
    }
    bad = set(fields.keys()) - allowed
    if bad:
        raise ValueError(f"Invalid protocol fields: {sorted(bad)}")

    fields = dict(fields)

    if "fixed_start_enabled" in fields:
        fields["fixed_start_enabled"] = int(bool(fields["fixed_start_enabled"]))
    if "fixed_start_mm" in fields:
        fields["fixed_start_mm"] = float(fields["fixed_start_mm"])

    fields["updated_at"] = _utc_now_iso()

    sets = ", ".join([f"{k} = ?" for k in fields.keys()])
    vals = list(fields.values()) + [protocol_id]
    conn.execute(f"UPDATE protocols SET {sets} WHERE id = ?", vals)
    conn.commit()

def delete_protocol(conn: sqlite3.Connection, protocol_id: int) -> None:
    conn.execute("DELETE FROM protocols WHERE id = ?", (protocol_id,))
    conn.commit()


def create_run(conn: sqlite3.Connection, protocol: Protocol, notes: str | None = None) -> int:
    """
    Creates a new run folder under:
      /home/pilotline/projects/FrictionTester_RaspberryPi/data/trials/<timestamp>_<protocol>/
    and inserts the run record in the DB.
    """
    safe_name = "".join([c if c.isalnum() or c in "-_ " else "_" for c in protocol.name]).strip().replace(" ", "-")
    run_stamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    run_dir = TRIALS_DIR / f"{run_stamp}_{safe_name}"
    run_dir.mkdir(parents=True, exist_ok=True)

    snapshot = asdict(protocol)
    snapshot.pop("id", None)

    cur = conn.execute(
        """
        INSERT INTO runs (protocol_id, protocol_snapshot_json, status, started_at, finished_at, run_dir, notes)
        VALUES (?, ?, 'queued', NULL, NULL, ?, ?)
        """,
        (protocol.id, json.dumps(snapshot), str(run_dir), notes),
    )
    conn.commit()
    return int(cur.lastrowid)


def mark_run_status(conn: sqlite3.Connection, run_id: int, status: str) -> None:
    allowed = {"queued", "running", "completed", "aborted", "failed"}
    if status not in allowed:
        raise ValueError(f"Invalid status: {status}")

    if status == "running":
        conn.execute(
            "UPDATE runs SET status = ?, started_at = COALESCE(started_at, ?) WHERE id = ?",
            (status, _utc_now_iso(), run_id),
        )
    elif status in {"completed", "aborted", "failed"}:
        conn.execute(
            "UPDATE runs SET status = ?, finished_at = ? WHERE id = ?",
            (status, _utc_now_iso(), run_id),
        )
    else:
        conn.execute("UPDATE runs SET status = ? WHERE id = ?", (status, run_id))

    conn.commit()

def _run_protocol_name(run: RunRow) -> str:
    try:
        snap = json.loads(run.protocol_snapshot_json or "{}")
        return snap.get("name") or f"Protocol {run.protocol_id}"
    except Exception:
        return f"Protocol {run.protocol_id}"


def list_runs(conn: sqlite3.Connection) -> List[RunRow]:
    rows = conn.execute(
        "SELECT * FROM runs ORDER BY id DESC"
    ).fetchall()
    return [RunRow(**dict(r)) for r in rows]


def get_run(conn: sqlite3.Connection, run_id: int) -> Optional[RunRow]:
    row = conn.execute("SELECT * FROM runs WHERE id = ?", (run_id,)).fetchone()
    return RunRow(**dict(row)) if row else None


def delete_run(conn: sqlite3.Connection, run_id: int, delete_files: bool = False) -> None:
    r = get_run(conn, run_id)
    if not r:
        return

    conn.execute("DELETE FROM runs WHERE id = ?", (run_id,))
    conn.commit()

    if delete_files:
        # optional: remove run directory contents
        try:
            import shutil
            shutil.rmtree(r.run_dir, ignore_errors=True)
        except Exception:
            pass


def get_run_snapshot(run: RunRow) -> Dict[str, Any]:
    try:
        return json.loads(run.protocol_snapshot_json or "{}")
    except Exception:
        return {}


def export_run_csv(conn: sqlite3.Connection, run_id: int) -> str:
    """
    Export CSV from a standard JSON file if it exists in run_dir.
    You can change this to whatever format you actually save.

    Expected file (example): <run_dir>/points.json
      [{"t":0.0,"pos":0.0,"force":0.1}, ...]
    """
    r = get_run(conn, run_id)
    if not r:
        raise ValueError("Run not found")

    run_dir = Path(r.run_dir)
    points_path = run_dir / "points.json"

    points: List[Dict[str, Any]] = []
    if points_path.exists():
        try:
            points = json.loads(points_path.read_text())
        except Exception:
            points = []

    # Header + rows
    lines = ["t_s,position_mm,force_n"]
    for p in points:
        t = p.get("t", 0)
        pos = p.get("pos", 0)
        force = p.get("force", 0)
        lines.append(f"{t},{pos},{force}")

    return "\n".join(lines)


def write_export_file(conn: sqlite3.Connection, run_id: int, fmt: str = "csv") -> str:
    """
    Writes an export file into the run_dir and returns the full path.
    """
    r = get_run(conn, run_id)
    if not r:
        raise ValueError("Run not found")

    run_dir = Path(r.run_dir)
    run_dir.mkdir(parents=True, exist_ok=True)

    if fmt.lower() == "csv":
        content = export_run_csv(conn, run_id)
        out_path = run_dir / "export.csv"
        out_path.write_text(content)
        return str(out_path)

    raise ValueError("Unsupported export format")
