from crackornot.main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "Todo List" in response.text

def test_create_and_list_todo():
    # Create a todo
    response = client.post("/todos", data={"todo": "Test the API"})
    assert response.status_code == 200
    assert "Test the API" in response.text

    # List todos
    response = client.get("/todos", headers={"HX-Request": "true"})
    assert response.status_code == 200
    assert "Test the API" in response.text
