"""Indonesian Voice and Speech Parsing Service for Financial Transactions."""
import re
from decimal import Decimal
from typing import Dict, Any, Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models.category import Category


class VoiceService:
    """Service to parse spoken Indonesian text into structured transaction parameters."""

    WORD_TO_NUMBER = {
        "nol": 0,
        "kosong": 0,
        "satu": 1,
        "se": 1,
        "dua": 2,
        "tiga": 3,
        "empat": 4,
        "lima": 5,
        "enam": 6,
        "tujuh": 7,
        "delapan": 8,
        "sembilan": 9,
        "sepuluh": 10,
        "sebelas": 11,
        "seratus": 100,
        "seribu": 1000,
        "sejuta": 1000000,
    }

    EXPENSE_KEYWORDS = [
        "pengeluaran",
        "keluar",
        "beli",
        "membeli",
        "bayar",
        "membayar",
        "belanja",
        "jajan",
        "makan",
        "minum",
        "ongkos",
        "parkir",
        "bensin",
        "tagihan",
        "pulsa",
        "listrik",
        "kontrakan",
        "sewa",
        "topup",
        "top up",
        "cicilan",
    ]

    INCOME_KEYWORDS = [
        "pemasukan",
        "masuk",
        "gaji",
        "bonus",
        "thr",
        "transfer masuk",
        "dapat uang",
        "terima uang",
        "penjualan",
        "upah",
        "honor",
        "hadiah",
        "dividen",
        "cashback",
        "kembalian",
    ]

    CATEGORY_KEYWORD_MAP = {
        "Makanan & Minuman": [
            "makan", "minum", "sarapan", "lunch", "dinner", "jajan", "kopi", "cafe",
            "kafe", "resto", "restoran", "warteg", "bakso", "nasi", "ayam", "sate",
            "mie", "snack", "cemilan", "boba", "roti", "kue", "sembako", "sayur",
        ],
        "Transportasi": [
            "bensin", "pertalite", "pertamax", "solar", "parkir", "ojek", "gojek",
            "grab", "angkot", "bus", "transjakarta", "kereta", "krl", "mrt", "lrt",
            "taksi", "tol", "tambal ban", "servis", "cuci motor", "cuci mobil",
        ],
        "Tagihan & Utilitas": [
            "listrik", "pln", "air", "pdam", "wifi", "indihome", "biznet", "internet",
            "pulsa", "paket data", "kuota", "bpjs", "asuransi", "ipl", "kontrakan",
            "kos", "kost", "gas", "lpg", "tagihan",
        ],
        "Belanja": [
            "belanja", "baju", "celana", "sepatu", "tas", "supermarket", "minimarket",
            "indomaret", "alfamart", "mall", "shopee", "tokopedia", "lazada", "tiktok",
            "perabot", "alat",
        ],
        "Hiburan": [
            "nonton", "bioskop", "cinema", "game", "steam", "playstation", "wisata",
            "liburan", "hotel", "tiket", "karaoke", "konser", "rekreasi",
        ],
        "Kesehatan": [
            "obat", "apotek", "dokter", "rumah sakit", "klinik", "vitamin", "masker",
            "periksa", "cek darah", "terapi", "rawat",
        ],
        "Pendidikan": [
            "spp", "sekolah", "kuliah", "buku", "kursus", "les", "ujian", "skripsi", "atk",
        ],
        "Gaji": [
            "gaji", "upah", "payroll", "penghasilan", "salary",
        ],
        "Bonus": [
            "bonus", "thr", "insentif", "komisi", "tips", "reward",
        ],
        "Investasi": [
            "dividen", "reksadana", "saham", "crypto", "emas", "bunga bank", "keuntungan",
        ],
    }

    @classmethod
    def parse_indonesian_words_to_number(cls, text: str) -> Optional[Decimal]:
        """Convert Indonesian spoken numbers (e.g. 'dua puluh lima ribu', 'seratus lima puluh ribu') into numeric Decimal."""
        tokens = text.lower().replace("-", " ").split()
        if not tokens:
            return None

        DIGITS = {
            "nol": 0, "kosong": 0, "satu": 1, "se": 1, "dua": 2, "tiga": 3,
            "empat": 4, "lima": 5, "enam": 6, "tujuh": 7, "delapan": 8, "sembilan": 9,
        }

        total = Decimal("0")
        sub_total = Decimal("0")
        temp = Decimal("0")

        i = 0
        while i < len(tokens):
            w = tokens[i]

            if w in DIGITS:
                temp = Decimal(str(DIGITS[w]))
            elif w.isdigit():
                temp = Decimal(w)
            elif w == "sepuluh":
                sub_total += Decimal("10")
                temp = Decimal("0")
            elif w == "sebelas":
                sub_total += Decimal("11")
                temp = Decimal("0")
            elif w == "seratus":
                sub_total += Decimal("100")
                temp = Decimal("0")
            elif w == "seribu":
                total += (sub_total if sub_total > 0 else Decimal("1")) * Decimal("1000")
                sub_total = Decimal("0")
                temp = Decimal("0")
            elif w == "sejuta":
                total += Decimal("1000000")
                sub_total = Decimal("0")
                temp = Decimal("0")
            elif w == "setengah":
                temp = Decimal("0.5")
            elif w == "koma" and i + 1 < len(tokens):
                next_tok = tokens[i + 1]
                dec_val = DIGITS.get(next_tok) if next_tok in DIGITS else (int(next_tok) if next_tok.isdigit() else None)
                if dec_val is not None:
                    temp = temp + Decimal(f"0.{dec_val}")
                    i += 1
            elif w == "belas":
                sub_total += Decimal("10") + (temp if temp > 0 else Decimal("0"))
                temp = Decimal("0")
            elif w == "puluh":
                sub_total += (temp if temp > 0 else Decimal("1")) * Decimal("10")
                temp = Decimal("0")
            elif w == "ratus":
                sub_total += (temp if temp > 0 else Decimal("1")) * Decimal("100")
                temp = Decimal("0")
            elif w == "ribu" or w == "rb" or w == "k":
                curr_block = sub_total + temp
                total += (curr_block if curr_block > 0 else Decimal("1")) * Decimal("1000")
                sub_total = Decimal("0")
                temp = Decimal("0")
            elif w == "juta" or w == "jt":
                curr_block = sub_total + temp
                total += (curr_block if curr_block > 0 else Decimal("1")) * Decimal("1000000")
                sub_total = Decimal("0")
                temp = Decimal("0")
            elif w == "miliar" or w == "milyar":
                curr_block = sub_total + temp
                total += (curr_block if curr_block > 0 else Decimal("1")) * Decimal("1000000000")
                sub_total = Decimal("0")
                temp = Decimal("0")

            i += 1

        total += sub_total + temp
        return total if total > 0 else None

    @classmethod
    def extract_amount(cls, text: str) -> Optional[Decimal]:
        """Extract monetary amount using regex patterns or Indonesian number words."""
        cleaned = text.lower()

        # 1. Pattern: '2,5 juta' or '2.5jt' or '10 juta'
        juta_match = re.search(r"(\d+(?:[.,]\d+)?)\s*(?:jt|juta)", cleaned)
        if juta_match:
            val_str = juta_match.group(1).replace(",", ".")
            try:
                return (Decimal(val_str) * Decimal("1000000")).quantize(Decimal("1.00"))
            except Exception:
                pass

        # 2. Pattern: '50rb' or '50k' or '50 ribu' or '100.000'
        ribu_match = re.search(r"(\d+(?:[.,]\d+)?)\s*(?:rb|ribu|k)", cleaned)
        if ribu_match:
            val_str = ribu_match.group(1).replace(",", ".")
            try:
                return (Decimal(val_str) * Decimal("1000")).quantize(Decimal("1.00"))
            except Exception:
                pass

        # 3. Direct formatted currency numbers: 'Rp 50.000' or '350.000' or '25000'
        currency_match = re.search(r"(?:rp\.?|rupiah\s*)?\s*(\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d{4,})", cleaned)
        if currency_match:
            raw_num = currency_match.group(1).replace(".", "").replace(",", ".")
            try:
                parsed_dec = Decimal(raw_num)
                if parsed_dec >= 100:  # Reasonable minimum financial transaction amount
                    return parsed_dec.quantize(Decimal("1.00"))
            except Exception:
                pass

        # 4. Spoken words pattern fallback (e.g. 'dua puluh lima ribu rupiah')
        number_tokens = [
            "nol", "satu", "dua", "tiga", "empat", "lima", "enam", "tujuh", "delapan", "sembilan",
            "sepuluh", "sebelas", "belas", "puluh", "seratus", "ratus", "seribu", "ribu",
            "sejuta", "juta", "setengah", "koma",
        ]
        words = cleaned.split()
        num_phrase = []
        for word in words:
            clean_word = re.sub(r"[^\w]", "", word)
            if clean_word in number_tokens or clean_word.isdigit():
                num_phrase.append(clean_word)
            elif num_phrase:
                break

        if num_phrase:
            parsed = cls.parse_indonesian_words_to_number(" ".join(num_phrase))
            if parsed and parsed > 0:
                return parsed.quantize(Decimal("1.00"))

        return None

    @classmethod
    def detect_transaction_type(cls, text: str) -> str:
        """Detect whether speech indicates income or expense."""
        cleaned = text.lower()
        for kw in cls.INCOME_KEYWORDS:
            if kw in cleaned:
                return "income"
        return "expense"

    @classmethod
    def extract_clean_description(cls, text: str, detected_amount: Optional[Decimal]) -> str:
        """Strip filler words and amounts to extract clean activity/item description."""
        cleaned = text.strip()

        # Remove common command fillers at the start
        cleaned = re.sub(
            r"^(?:tolong\s+)?(?:catat(?:kan)?|tambah(?:kan)?|masukkan|input)\s+",
            "",
            cleaned,
            flags=re.IGNORECASE,
        )
        cleaned = re.sub(
            r"^(?:transaksi\s+)?(?:pengeluaran|pemasukan|uang\s+masuk|uang\s+keluar)\s+",
            "",
            cleaned,
            flags=re.IGNORECASE,
        )

        # Remove currency prefixes / words
        cleaned = re.sub(r"\b(?:sebesar|sebanyak|nominal|seharga|senilai)\b", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\b(?:rupiah|rp\.?)\b", "", cleaned, flags=re.IGNORECASE)

        # Remove number digits and shorthand
        cleaned = re.sub(r"\b\d+(?:[.,]\d+)?\s*(?:jt|juta|rb|ribu|k)?\b", "", cleaned, flags=re.IGNORECASE)

        # Remove Indonesian number words
        indonesian_num_words = (
            r"\b(?:nol|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|"
            r"sebelas|dua\s+belas|tiga\s+belas|empat\s+belas|lima\s+belas|enam\s+belas|tujuh\s+belas|delapan\s+belas|sembilan\s+belas|"
            r"puluh|seratus|ratus|seribu|ribu|sejuta|juta|setengah|koma)\b"
        )
        cleaned = re.sub(indonesian_num_words, "", cleaned, flags=re.IGNORECASE)

        # Clean multiple spaces and punctuation
        cleaned = re.sub(r"\s+", " ", cleaned).strip()
        cleaned = re.sub(r"^[,\-.:;]+\s*", "", cleaned).strip()

        if not cleaned:
            return "Transaksi Suara"
        return cleaned.capitalize()

    @classmethod
    def match_suggested_category(
        cls,
        text: str,
        tx_type: str,
        db: Session,
        user_id: str,
    ) -> tuple[Optional[str], Optional[str]]:
        """Find the best matching category from system and user categories."""
        cleaned = text.lower()
        matched_cat_name = None

        # Check keyword map
        for cat_name, keywords in cls.CATEGORY_KEYWORD_MAP.items():
            for kw in keywords:
                if re.search(r"\b" + re.escape(kw) + r"\b", cleaned):
                    matched_cat_name = cat_name
                    break
            if matched_cat_name:
                break

        # Query database to find matching category ID
        categories = db.query(Category).filter(
            Category.type == tx_type,
            or_(Category.user_id == user_id, Category.is_system == True),  # noqa: E712
        ).all()

        if matched_cat_name:
            # Try exact match or partial match on name
            for cat in categories:
                if matched_cat_name.lower() in cat.name.lower() or cat.name.lower() in matched_cat_name.lower():
                    return cat.id, cat.name

        # If no specific keyword matched, default to the first category of this type
        if categories:
            return categories[0].id, categories[0].name

        return None, None

    @classmethod
    def parse_voice_text(
        cls,
        text: str,
        db: Session,
        user_id: str,
    ) -> Dict[str, Any]:
        """Parse raw speech transcript into structured transaction draft."""
        tx_type = cls.detect_transaction_type(text)
        amount = cls.extract_amount(text)
        description = cls.extract_clean_description(text, amount)
        cat_id, cat_name = cls.match_suggested_category(text, tx_type, db, user_id)

        # Calculate confidence score based on amount detection and category match
        confidence = 0.5
        if amount is not None and amount > 0:
            confidence += 0.3
        if cat_name is not None:
            confidence += 0.2

        return {
            "raw_text": text,
            "type": tx_type,
            "amount": amount,
            "description": description,
            "suggested_category_name": cat_name,
            "suggested_category_id": cat_id,
            "confidence_score": min(confidence, 1.0),
        }
