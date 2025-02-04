from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from typing import Annotated
from dataclasses import dataclass
from typing import List

app = FastAPI()
templates = Jinja2Templates(directory="templates")

@dataclass
class WallInspection:
    wall_number: int
    has_crack: bool

# Global state (in a real app, this would be a database)
inspections: List[WallInspection] = []

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse(
        request=request, 
        name="index.html",
        context={"inspections": inspections}
    )

@app.post("/inspect", response_class=HTMLResponse)
async def inspect_wall(
    request: Request,
    has_crack: Annotated[bool, Form()] = False
):
    # Add new inspection with incremented wall number
    next_wall = len(inspections) + 1
    inspections.append(WallInspection(wall_number=next_wall, has_crack=has_crack))
    
    return templates.TemplateResponse(
        request=request,
        name="report.html",
        context={"inspections": inspections}
    ) 