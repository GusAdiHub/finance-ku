"""Integration tests for Receipt and OCR endpoints."""
import io
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient
from app.services.ocr_service import OCRService


def _get_auth_token(client: TestClient, email: str, name: str = "Test User") -> str:
    """Helper to register and return an access token."""
    res = client.post(
        "/api/v1/auth/register",
        json={"name": name, "email": email, "password": "Password123!"},
    )
    return res.json()["access_token"]


def _get_expense_category_id(client: TestClient, token: str) -> str:
    """Helper to get a valid expense category ID."""
    res = client.get(
        "/api/v1/categories?type=expense",
        headers={"Authorization": f"Bearer {token}"},
    )
    return res.json()[0]["id"]


def test_ocr_parser_logic():
    """Unit test for Indonesian receipt parser heuristics."""
    sample_ocr_text = """
    INDOMARET PONDOK INDAH
    JL. METRO PONDOK INDAH NO. 12
    TANGGAL: 25/10/2026 14:35
    --------------------------------
    ROTI COKLAT           15.000
    SUSU UHT FULL CREAM   20.000
    AIR MINERAL 600ML      5.000
    --------------------------------
    SUBTOTAL              40.000
    DISKON MEMBER         -2.000
    TOTAL AKHIR           38.000
    TUNAI                 50.000
    KEMBALIAN             12.000
    """
    parsed = OCRService.parse_receipt_text(sample_ocr_text)

    assert parsed["merchant_name"] == "INDOMARET"
    assert parsed["receipt_date"] is not None
    assert parsed["receipt_date"].day == 25
    assert parsed["receipt_date"].month == 10
    assert parsed["receipt_date"].year == 2026
    assert parsed["total_amount"] == Decimal("38000")
    assert len(parsed["items"]) >= 2
    assert parsed["ocr_status"] == "success"


def test_ocr_parser_multiline_and_cents():
    """Test multi-line total layout, cents handling, and payment method fallback."""
    multiline_receipt = """
    ALFAMART KEMANG
    TGL 10-11-2026
    KOPI SUSU           12.000,00
    SNACK KERIPIK        8.500,00
    TOTAL BELANJA
    Rp 20.500,00
    QRIS
    """
    parsed = OCRService.parse_receipt_text(multiline_receipt)
    assert parsed["merchant_name"] == "ALFAMART"
    assert parsed["total_amount"] == Decimal("20500")
    assert parsed["ocr_status"] == "success"


def test_ocr_parser_unavailable_handling():
    """Test handling when OCR binary is not available or raw_text is empty."""
    unavailable = OCRService.parse_receipt_text("[OCR Unavailable: tesseract not installed]")
    assert unavailable["total_amount"] is None
    assert unavailable["ocr_status"] == "unavailable"
    assert "belum terpasang" in unavailable["ocr_message"]

    empty = OCRService.parse_receipt_text("")
    assert empty["total_amount"] is None
    assert empty["ocr_status"] == "empty"


def test_ocr_parser_dotmatrix_pharmacy():
    """Test dot-matrix pharmacy receipt format with spaced amounts and rotal/tunai/kembalian."""
    pharmacy_receipt = """
    Adapolek Ablansemal
    Abian Semal
    081337184741
    ====================================
    Kasir                             EKA
    Waktu             31 October 2026. 14.37
    No. Transaksi       261031APAS-004797
    Dokter                             XX
    Pasien
    ====================================
    LAXADINE SIRUP 60ML
    64,500 x 1 -0%                64,500
    SALONPAS KOYO ISI 10 (BIRU)
    9,000 x 1 -0%                  9,000
    ====================================
    rotal                         73, 500
    ====================================
    Tunai                        100,000
    ------------------------------------
    Kembalian                     26,500
    ====================================
                *** LUNAS ***
    """
    parsed = OCRService.parse_receipt_text(pharmacy_receipt)
    assert "Apotek" in parsed["merchant_name"] or "Adapolek" in parsed["merchant_name"]
    assert parsed["receipt_date"] is not None
    assert parsed["receipt_date"].year == 2026
    assert parsed["receipt_date"].month == 10
    assert parsed["receipt_date"].day == 31
    assert parsed["total_amount"] == Decimal("73500")
    assert parsed["ocr_status"] == "success"


def test_ocr_parser_spaced_and_multiline_divider():
    """Test dot-matrix receipt where total amount has only spaces and divider lines."""
    receipt = """
    APOTEK SEHAT
    TOTAL
    ====================================
    73 500
    ====================================
    Tunai 100 000
    Kembalian 26 500
    """
    parsed = OCRService.parse_receipt_text(receipt)
    assert parsed["total_amount"] == Decimal("73500")
    assert parsed["ocr_status"] == "success"


def test_ocr_parser_items_sum_fallback():
    """Test calculating total from line items when Total label is smudged/missing."""
    receipt = """
    KLINIK DAN APOTEK KITA
    OBAT BATUK SIRUP        45.000
    VITAMIN C 500MG         25.000
    PLASTER LUKA            10.000
    ------------------------------
    LUNAS
    """
    parsed = OCRService.parse_receipt_text(receipt)
    assert parsed["total_amount"] == Decimal("80000")
    assert parsed["ocr_status"] == "success"


def test_ocr_parser_dotmatrix_ocr_typo_correction():
    """Test that OCR character typos (e.g. Adanotek Ablansemal, rotal 74 503) are fixed by heuristics and cash math."""
    noisy_receipt = """
    Adanotek Ablansemal
    Abian Semal
    081337184741
    ====================================
    Kasir                             EKA
    Waktu             31 October 2026. 14.37
    No. Transaksi       261031APAS-004797
    ====================================
    LAXADINE SIRUP 60ML
    64,500 x 1 -0%                64,500
    SALONPAS KOYO ISI 10 (BIRU)
    9,000 x 1 -0%                  9,000
    ====================================
    rotal                         74, 503
    ====================================
    Tunai                        100,000
    ------------------------------------
    Kembalian                     26,500
    ====================================
                *** LUNAS ***
    """
    parsed = OCRService.parse_receipt_text(noisy_receipt)
    assert parsed["merchant_name"] == "Apotek Abiansemal"
    assert parsed["receipt_date"] is not None
    assert parsed["receipt_date"].year == 2026
    assert parsed["receipt_date"].month == 10
    assert parsed["receipt_date"].day == 31
    assert parsed["total_amount"] == Decimal("73500")
    assert len(parsed["items"]) == 2
    assert parsed["items"][0]["item_name"] == "LAXADINE SIRUP 60ML"
    assert parsed["items"][0]["price_per_unit"] == Decimal("64500")
    assert parsed["items"][1]["item_name"] == "SALONPAS KOYO ISI 10 (BIRU)"
    assert parsed["items"][1]["price_per_unit"] == Decimal("9000")
    assert parsed["ocr_status"] == "success"


def test_ocr_parser_dotmatrix_286_denomination_typo():
    """Test that dot-matrix 286 suffix typo (from 500) is corrected to 500 and total is 73500."""
    noisy_receipt = """
    Adapotek Ablansemal
    Abian Semal
    081337184741
    ====================================
    Kasir                             EKA
    Waktu             31 October 2026. 14.37
    No. Transaksi       261031APAS-004797
    ====================================
    LAXADINE SIRUP 60ML
    64,286 x 1 -0%                64,286
    ¡ALONPAS KOYO ISI 10 (BIRU)
    9,000 x 1 -0%                  9,000
    ====================================
    Total                         73, 286
    ====================================
    Tunai                        100,000
    ------------------------------------
    Kembalian                     26,286
    ====================================
                *** LUNAS ***
    """
    parsed = OCRService.parse_receipt_text(noisy_receipt)
    assert "Apotek" in parsed["merchant_name"]
    assert parsed["total_amount"] == Decimal("73500")
    assert len(parsed["items"]) == 2
    assert parsed["items"][0]["total_price"] == Decimal("64500")
    assert parsed["items"][1]["total_price"] == Decimal("9000")
    assert parsed["ocr_status"] == "success"


def test_upload_receipt_invalid_file_type(client: TestClient):
    """Test rejecting non-image files."""
    token = _get_auth_token(client, "user_ocr1@example.com")
    fake_file = io.BytesIO(b"dummy pdf content")

    response = client.post(
        "/api/v1/receipts",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("test.pdf", fake_file, "application/pdf")},
    )
    assert response.status_code == 400
    assert "tidak didukung" in response.json()["detail"].lower()


def test_upload_receipt_and_confirm_transaction(client: TestClient):
    """Test full flow: upload receipt draft -> review -> confirm into a personal transaction."""
    token = _get_auth_token(client, "user_ocr2@example.com")
    cat_id = _get_expense_category_id(client, token)

    # 1. Create a dummy JPEG file
    fake_image_bytes = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xff\xdb\x00C\x00" + (b"\x00" * 100)
    file_buffer = io.BytesIO(fake_image_bytes)

    upload_res = client.post(
        "/api/v1/receipts",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("struk_belanja.jpg", file_buffer, "image/jpeg")},
    )
    assert upload_res.status_code == 201
    receipt_data = upload_res.json()
    receipt_id = receipt_data["id"]
    assert receipt_data["status"] == "draft"
    assert receipt_data["file_name"] == "struk_belanja.jpg"

    # 2. Get receipt detail
    get_res = client.get(
        f"/api/v1/receipts/{receipt_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert get_res.status_code == 200
    assert get_res.json()["id"] == receipt_id

    # 3. Confirm receipt draft into a personal transaction
    confirm_payload = {
        "category_id": cat_id,
        "merchant_name": "Alfamart Kemang",
        "total_amount": 85000.00,
        "description": "Belanja mingguan perlengkapan mandi",
        "target_scope": "personal",
        "items": [
            {"item_name": "Sabun Mandi", "quantity": 2, "price_per_unit": 20000, "total_price": 40000},
            {"item_name": "Shampoo", "quantity": 1, "price_per_unit": 45000, "total_price": 45000},
        ],
    }

    confirm_res = client.post(
        f"/api/v1/receipts/{receipt_id}/confirm",
        headers={"Authorization": f"Bearer {token}"},
        json=confirm_payload,
    )
    assert confirm_res.status_code == 200
    tx_data = confirm_res.json()
    assert tx_data["amount"] == 85000.00
    assert tx_data["input_method"] == "ocr"
    assert tx_data["receipt_id"] == receipt_id
    assert tx_data["category_id"] == cat_id

    # 4. Verify receipt status is now confirmed
    verify_receipt = client.get(
        f"/api/v1/receipts/{receipt_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert verify_receipt.json()["status"] == "confirmed"

    # 5. Cannot re-confirm already confirmed receipt
    reconfirm_res = client.post(
        f"/api/v1/receipts/{receipt_id}/confirm",
        headers={"Authorization": f"Bearer {token}"},
        json=confirm_payload,
    )
    assert reconfirm_res.status_code == 400
    assert "sudah pernah dikonfirmasi" in reconfirm_res.json()["detail"].lower()


def test_receipt_idor_protection(client: TestClient):
    """Test that another user cannot view or confirm someone else's receipt."""
    token_user_a = _get_auth_token(client, "user_a@example.com")
    token_user_b = _get_auth_token(client, "user_b@example.com")
    cat_id_b = _get_expense_category_id(client, token_user_b)

    # User A uploads receipt
    fake_img = io.BytesIO(b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01" + b"\x00" * 50)
    upload_res = client.post(
        "/api/v1/receipts",
        headers={"Authorization": f"Bearer {token_user_a}"},
        files={"file": ("struk_a.jpg", fake_img, "image/jpeg")},
    )
    receipt_id = upload_res.json()["id"]

    # User B tries to view User A's receipt
    get_res = client.get(
        f"/api/v1/receipts/{receipt_id}",
        headers={"Authorization": f"Bearer {token_user_b}"},
    )
    assert get_res.status_code == 403

    # User B tries to confirm User A's receipt
    confirm_res = client.post(
        f"/api/v1/receipts/{receipt_id}/confirm",
        headers={"Authorization": f"Bearer {token_user_b}"},
        json={
            "category_id": cat_id_b,
            "total_amount": 50000.00,
            "target_scope": "personal",
        },
    )
    assert confirm_res.status_code == 403

    # User B tries to delete User A's receipt
    delete_res = client.delete(
        f"/api/v1/receipts/{receipt_id}",
        headers={"Authorization": f"Bearer {token_user_b}"},
    )
    assert delete_res.status_code == 403


def test_delete_receipt(client: TestClient):
    """Test deleting receipt draft."""
    token = _get_auth_token(client, "del_user@example.com")

    fake_img = io.BytesIO(b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01" + b"\x00" * 50)
    upload_res = client.post(
        "/api/v1/receipts",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("to_delete.png", fake_img, "image/png")},
    )
    receipt_id = upload_res.json()["id"]

    # Delete
    del_res = client.delete(
        f"/api/v1/receipts/{receipt_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert del_res.status_code == 200

    # Ensure it's gone
    get_res = client.get(
        f"/api/v1/receipts/{receipt_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert get_res.status_code == 404
