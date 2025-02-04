from crackornot.main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "Wall Inspector" in response.text

def test_inspect_walls():
    # Inspect first wall - no crack
    response = client.post("/inspect", data={"has_crack": ""})
    assert response.status_code == 200
    assert "wall #1" in response.text
    assert "with no crack" in response.text

    # Inspect second wall - with crack
    response = client.post("/inspect", data={"has_crack": "true"})
    assert response.status_code == 200
    assert "wall #2" in response.text
    assert "had a crack" in response.text
    assert "wall #1" in response.text  # Previous wall should still be there

    # Verify the narrative format
    assert response.text.count("<p>") == 2  # Should have two paragraphs
