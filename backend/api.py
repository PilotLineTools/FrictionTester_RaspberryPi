# api.py
from __future__ import annotations

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any

from .storage import (
    connect, init_db,
    list_protocols, get_protocol,
    create_protocol, update_protocol, delete_protocol,
    create_run, mark_run_status,
    list_runs, get_run, delete_run, get_run_snapshot,
    export_run_csv, write_export_file,
    Protocol
)


app = FastAPI(title="FrictionTester Backend")

# ---------- Models ----------
class ProtocolIn(BaseModel):
    name: str
    speed: float
    stroke_length_mm: int
    clamp_force_g: int
    water_temp_c: int
    cycles: int
    fixed_start_enabled: bool = False
    fixed_start_mm: float = 0.0

class ProtocolOut(ProtocolIn):
    id: int
    created_at: str
    updated_at: str

class RunCreateIn(BaseModel):
    protocol_id: int
    notes: Optional[str] = None

class RunCreateOut(BaseModel):
    run_id: int

class RunOut(BaseModel):
    id: int
    protocol_id: int
    protocol_name: str
    status: str
    started_at: Optional[str] = None
    finished_at: Optional[str] = None
    run_dir: str
    notes: Optional[str] = None

class RunStatusIn(BaseModel):
    status: str   # queued/running/completed/aborted/failed


# ---------- Startup ----------
@app.get("/health")
def health():
    return {"ok": True}

@app.on_event("startup")
def _startup():
    conn = connect()
    init_db(conn)
    conn.close()

# ---------- Endpoints ----------
@app.get("/protocols", response_model=List[ProtocolOut])
def api_list_protocols():
    conn = connect()
    try:
        items = list_protocols(conn)
        return [ProtocolOut(**p.__dict__) for p in items]  # dataclass -> dict
    finally:
        conn.close()

@app.post("/protocols", response_model=Dict[str, int])
def api_create_protocol(p: ProtocolIn):
    conn = connect()
    try:
        pid = create_protocol(conn, Protocol(
            id=None,
            name=p.name,
            speed=p.speed,
            stroke_length_mm=p.stroke_length_mm,
            clamp_force_g=p.clamp_force_g,
            water_temp_c=p.water_temp_c,
            cycles=p.cycles,
            fixed_start_enabled=p.fixed_start_enabled,
            fixed_start_mm=p.fixed_start_mm,
        ))
        return {"id": pid}
    finally:
        conn.close()

@app.put("/protocols/{protocol_id}")
def api_update_protocol(protocol_id: int, fields: Dict[str, Any]):
    conn = connect()
    try:
        if not get_protocol(conn, protocol_id):
            raise HTTPException(status_code=404, detail="Protocol not found")
        update_protocol(conn, protocol_id, fields)
        return {"ok": True}
    finally:
        conn.close()

@app.delete("/protocols/{protocol_id}")
def api_delete_protocol(protocol_id: int):
    conn = connect()
    try:
        if not get_protocol(conn, protocol_id):
            raise HTTPException(status_code=404, detail="Protocol not found")
        delete_protocol(conn, protocol_id)
        return {"ok": True}
    finally:
        conn.close()

@app.post("/runs", response_model=RunCreateOut)
def api_create_run(req: RunCreateIn):
    conn = connect()
    try:
        p = get_protocol(conn, req.protocol_id)
        if not p:
            raise HTTPException(status_code=404, detail="Protocol not found")
        run_id = create_run(conn, p, notes=req.notes)
        return RunCreateOut(run_id=run_id)
    finally:
        conn.close()

@app.get("/runs", response_model=List[RunOut])
def api_list_runs():
    conn = connect()
    try:
        items = list_runs(conn)
        out: List[RunOut] = []
        for r in items:
            snap = get_run_snapshot(r)
            out.append(RunOut(
                id=r.id,
                protocol_id=r.protocol_id,
                protocol_name=snap.get("name", f"Protocol {r.protocol_id}"),
                status=r.status,
                started_at=r.started_at,
                finished_at=r.finished_at,
                run_dir=r.run_dir,
                notes=r.notes,
            ))
        return out
    finally:
        conn.close()


@app.get("/runs/{run_id}", response_model=Dict[str, Any])
def api_get_run(run_id: int):
    conn = connect()
    try:
        r = get_run(conn, run_id)
        if not r:
            raise HTTPException(status_code=404, detail="Run not found")

        snap = get_run_snapshot(r)
        return {
            "run": {
                "id": r.id,
                "protocol_id": r.protocol_id,
                "protocol_name": snap.get("name", f"Protocol {r.protocol_id}"),
                "status": r.status,
                "started_at": r.started_at,
                "finished_at": r.finished_at,
                "run_dir": r.run_dir,
                "notes": r.notes,
            },
            "protocol_snapshot": snap,
            # Later: include result summary, stats, etc.
        }
    finally:
        conn.close()


@app.put("/runs/{run_id}/status")
def api_set_run_status(run_id: int, req: RunStatusIn):
    conn = connect()
    try:
        r = get_run(conn, run_id)
        if not r:
            raise HTTPException(status_code=404, detail="Run not found")

        mark_run_status(conn, run_id, req.status)
        return {"ok": True}
    finally:
        conn.close()


@app.delete("/runs/{run_id}")
def api_delete_run(run_id: int, delete_files: bool = False):
    conn = connect()
    try:
        r = get_run(conn, run_id)
        if not r:
            raise HTTPException(status_code=404, detail="Run not found")

        delete_run(conn, run_id, delete_files=delete_files)
        return {"ok": True}
    finally:
        conn.close()


@app.get("/runs/{run_id}/export")
def api_export_run(run_id: int, fmt: str = "csv", mode: str = "content"):
    """
    mode=content -> return the export content (CSV text)
    mode=file    -> write export into run_dir and return its path
    """
    conn = connect()
    try:
        if not get_run(conn, run_id):
            raise HTTPException(status_code=404, detail="Run not found")

        if fmt.lower() != "csv":
            raise HTTPException(status_code=400, detail="Only csv supported for now")

        if mode == "file":
            path = write_export_file(conn, run_id, fmt="csv")
            return {"format": "csv", "path": path}

        content = export_run_csv(conn, run_id)
        return {"format": "csv", "content": content}
    finally:
        conn.close()

