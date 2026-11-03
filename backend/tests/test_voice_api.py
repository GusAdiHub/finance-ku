"""Integration and unit tests for Voice Input and Indonesian Speech Parsing."""
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient
from app.services.voice_service import VoiceService


def _get_auth_token(client: TestClient, email: str, name: str = "Voice User") -> str:
    """Helper to register and return an access token."""
    res = client.post(
        "/api/v1/auth/register",
        json={"name": name, "email": email, "password": "Password123!"},
    )
    return res.json()["access_token"]


def test_voice_parser_heuristics():
    """Unit test for Indonesian voice parsing helpers."""
    # 1. Number parsing from words
    assert VoiceService.parse_indonesian_words_to_number("dua puluh lima ribu") == Decimal("25000")
    assert VoiceService.parse_indonesian_words_to_number("seratus lima puluh ribu") == Decimal("150000")
    assert VoiceService.parse_indonesian_words_to_number("satu juta dua ratus ribu") == Decimal("1200000")

    # 2. Extract amounts
    assert VoiceService.extract_amount("beli bensin 50rb") == Decimal("50000.00")
    assert VoiceService.extract_amount("gaji bulanan 5 juta rupiah") == Decimal("5000000.00")
    assert VoiceService.extract_amount("jajan bakso 25.000") == Decimal("25000.00")
    assert VoiceService.extract_amount("bayar wifi seratus ribu rupiah") == Decimal("100000.00")

    # 3. Type detection
    assert VoiceService.detect_transaction_type("catat pengeluaran makan siang") == "expense"
    assert VoiceService.detect_transaction_type("beli pulsa lima puluh ribu") == "expense"
    assert VoiceService.detect_transaction_type("uang masuk gaji bulanan") == "income"
    assert VoiceService.detect_transaction_type("terima transfer bonus projek") == "income"


def test_voice_parse_api_endpoint(client: TestClient):
    """Test POST /api/v1/voice/parse endpoint with realistic speech inputs."""
    token = _get_auth_token(client, "voice_test_user@example.com")

    # Test Case 1: Spoken expense for food
    payload1 = {"text": "Tolong catat pengeluaran makan siang di warteg dua puluh lima ribu rupiah"}
    res1 = client.post(
        "/api/v1/voice/parse",
        headers={"Authorization": f"Bearer {token}"},
        json=payload1,
    )
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["type"] == "expense"
    assert float(data1["amount"]) == 25000.0
    assert "warteg" in data1["description"].lower() or "makan" in data1["description"].lower()
    assert data1["confidence_score"] >= 0.7

    # Test Case 2: Spoken expense for transportation
    payload2 = {"text": "Beli bensin pertalite motor 50rb"}
    res2 = client.post(
        "/api/v1/voice/parse",
        headers={"Authorization": f"Bearer {token}"},
        json=payload2,
    )
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["type"] == "expense"
    assert float(data2["amount"]) == 50000.0
    assert "bensin" in data2["description"].lower()

    # Test Case 3: Spoken income for salary
    payload3 = {"text": "Pemasukan gaji bulanan lima juta rupiah"}
    res3 = client.post(
        "/api/v1/voice/parse",
        headers={"Authorization": f"Bearer {token}"},
        json=payload3,
    )
    assert res3.status_code == 200
    data3 = res3.json()
    assert data3["type"] == "income"
    assert float(data3["amount"]) == 5000000.0
    assert "gaji" in data3["description"].lower()


def test_voice_parse_unauthenticated(client: TestClient):
    """Test that voice parsing requires authentication."""
    res = client.post(
        "/api/v1/voice/parse",
        json={"text": "Beli kopi 25 ribu"},
    )
    assert res.status_code == 401
