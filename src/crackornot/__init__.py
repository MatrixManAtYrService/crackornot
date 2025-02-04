from .main import app

def get_greeting() -> str:
    return "Hello, world!"

def hello():
    print(get_greeting()) 