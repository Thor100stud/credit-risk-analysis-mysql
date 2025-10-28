# Tagesablauf Dokumentations-App

Eine FastAPI-basierte Anwendung zur Dokumentation von Tagesabläufen mit JWT-Authentifizierung und Excel-Export.

## Features

- Benutzerregistrierung und -authentifizierung mit JWT
- Erfassung von Tagesablauf-Einträgen mit automatischem Zeitstempel
- CRUD-Operationen für Einträge (Erstellen, Lesen, Aktualisieren, Löschen)
- Excel-Export aller Einträge eines Benutzers
- Benutzer-Isolation (jeder sieht nur seine eigenen Einträge)
- Passwort-Hashing mit bcrypt
- Input-Validierung mit Pydantic

## Installation

### 1. Dependencies installieren

```bash
pip install -r requirements.txt
```

### 2. Umgebungsvariablen prüfen

Die `.env` Datei enthält bereits einen generierten JWT Secret Key. Bei Bedarf kannst du einen neuen generieren:

```python
import secrets
print(secrets.token_hex(32))
```

### 3. Anwendung starten

```bash
uvicorn main:app --reload
```

Die API läuft dann unter: `http://127.0.0.1:8000`

## API-Dokumentation

FastAPI generiert automatisch eine interaktive API-Dokumentation:

- **Swagger UI:** http://127.0.0.1:8000/docs
- **ReDoc:** http://127.0.0.1:8000/redoc

## Verwendung

### 1. Benutzer registrieren

**Endpoint:** `POST /auth`

```json
{
  "email": "max@example.com",
  "username": "maxmustermann",
  "first_name": "Max",
  "last_name": "Mustermann",
  "password": "SicheresPasswort123!"
}
```

**Passwort-Anforderungen:**
- Mindestens 8 Zeichen
- Mindestens eine Ziffer
- Mindestens ein Sonderzeichen (!@#$%^&*()-_=+[]{};:,.<>?/\|)

### 2. Anmelden und Token erhalten

**Endpoint:** `POST /token`

**Form Data:**
- username: `maxmustermann`
- password: `SicheresPasswort123!`

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 3. Token verwenden

Füge den Token in alle geschützten Requests ein:

**Header:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 4. Tagesablauf-Eintrag erstellen

**Endpoint:** `POST /log`

```json
{
  "activity": "Meeting mit Team",
  "description": "Besprechung der Projektfortschritte und nächste Schritte",
  "duration_minutes": 60
}
```

Der Zeitstempel wird automatisch beim Erstellen hinzugefügt!

### 5. Alle Einträge abrufen

**Endpoint:** `GET /logs`

Gibt alle deine Einträge zurück.

### 6. Einzelnen Eintrag abrufen

**Endpoint:** `GET /log/{log_id}`

Beispiel: `GET /log/1`

### 7. Eintrag aktualisieren

**Endpoint:** `PUT /log/{log_id}`

```json
{
  "activity": "Meeting mit Team (aktualisiert)",
  "description": "Detaillierte Besprechung mit neuen Erkenntnissen",
  "duration_minutes": 75
}
```

### 8. Eintrag löschen

**Endpoint:** `DELETE /log/{log_id}`

### 9. Excel-Export

**Endpoint:** `GET /export`

Lädt eine Excel-Datei mit allen deinen Einträgen herunter. Die Datei enthält:

- ID
- Datum
- Uhrzeit
- Aktivität
- Beschreibung
- Dauer (Minuten)
- Benutzer
- Gesamtdauer-Berechnung

**Dateiname-Format:** `tagesablauf_{username}_{timestamp}.xlsx`

## Projektstruktur

```
dokumentations_app/
├── main.py              - Anwendungseinstiegspunkt
├── auth.py              - Authentifizierungs-Router (Registrierung, Login)
├── routes.py            - DailyLog CRUD-Operationen
├── export.py            - Excel-Export-Funktionalität
├── models.py            - SQLAlchemy Datenbankmodelle
├── data_model.py        - Pydantic Validierungs-Schemas
├── database.py          - Datenbankkonfiguration
├── helper.py            - JWT und Auth-Utilities
├── .env                 - Umgebungsvariablen
├── requirements.txt     - Python-Dependencies
├── dokumentation.db     - SQLite-Datenbank (wird automatisch erstellt)
└── temp/                - Temporäre Excel-Dateien
```

## Datenmodell

### Users
- id (Primary Key)
- email (unique)
- username (unique)
- first_name
- last_name
- hashed_password
- is_active
- role

### DailyLog
- id (Primary Key)
- activity
- description
- duration_minutes
- created_at (automatisch)
- owner_id (Foreign Key → Users)

## Sicherheit

- JWT mit HS256-Algorithmus
- Token-Ablaufzeit: 30 Minuten (konfigurierbar)
- bcrypt Passwort-Hashing
- Benutzer-Isolation (Zugriff nur auf eigene Daten)
- Input-Validierung mit Pydantic
- OAuth2 Password Flow

## Testing mit Swagger UI

1. Öffne http://127.0.0.1:8000/docs
2. Registriere einen Benutzer über `POST /auth`
3. Melde dich an über `POST /token` und kopiere den access_token
4. Klicke auf "Authorize" (Schloss-Symbol oben rechts)
5. Gib ein: `<dein_access_token>` (ohne "Bearer")
6. Jetzt kannst du alle geschützten Endpoints testen
7. Erstelle mehrere Einträge
8. Exportiere sie als Excel über `GET /export`

## Tipps

- Die Datenbank wird automatisch beim ersten Start erstellt
- Token ist 30 Minuten gültig, danach neu einloggen
- Excel-Dateien werden im `temp/` Verzeichnis gespeichert
- Der Export ist sortiert nach Zeitstempel (älteste zuerst)
- Gesamtdauer wird automatisch in der Excel-Datei berechnet

## Erweiterte Konfiguration

In der `.env` Datei kannst du anpassen:

- `JWT_SECRET_KEY`: Secret Key für JWT-Signierung (WICHTIG: In Produktion ändern!)
- `ACCESS_TOKEN_EXPIRE_MINUTES`: Token-Gültigkeitsdauer in Minuten

## Abgabe

Die Excel-Datei kann direkt aus dem `GET /export` Endpoint heruntergeladen und abgegeben werden. Sie enthält:

- Alle deine Einträge chronologisch sortiert
- Formatierte Tabelle mit Header
- Berechnung der Gesamtdauer
- Professionelles Layout für die Abgabe

Viel Erfolg! 🚀
