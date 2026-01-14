# api.py
from __future__ import annotations

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any

from .storage import (
    connect, init_db,
    list_protocols, get_protocol,
    create_protocol, update_protocol, delete_protocol,
    create_run, Protocol
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

class ProtocolOut(ProtocolIn):
    id: int
    created_at: str
    updated_at: str

class RunCreateIn(BaseModel):
    protocol_id: int
    notes: Optional[str] = None

class RunCreateOut(BaseModel):
    run_id: int

# ---------- Startup ----------
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
