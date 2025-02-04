from hello_world import get_greeting

def test_get_greeting():
    print("Running greeting test!")  # This will be visible with `pytest -s`
    assert get_greeting() == "Hello, world!"
